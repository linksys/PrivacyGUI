import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/framework/mode/session_entry.dart';
import 'package:privacy_gui/framework/mode/session_request.dart';
import 'package:privacy_gui/framework/mode/session_strategy.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';

/// Remote Assistance sessions: a supporter's link opens a one-shot Guardian
/// engagement, and when the *engagement* ends the temporary token is spent and
/// there is no login screen to return to, so the destination is a terminal
/// "session ended" surface.
class RemoteSessionStrategy implements SessionStrategy {
  const RemoteSessionStrategy();

  /// Ceiling on the Guardian release call.
  ///
  /// Not defensive padding — without it this method can never return.
  /// `GuardianApiClient._request` calls `http.delete` with no timeout of its own,
  /// so a Guardian endpoint that accepts the connection and never answers hangs
  /// the `await` forever; a `try`/`catch` catches errors, not hangs. And this
  /// method runs *first* inside `logout()`'s `AsyncValue.guard`, so a hang there
  /// is not a slow logout — it is no logout at all: `authProvider` stays
  /// `AsyncValue.loading()`, the credential is never cleared, and
  /// [clearSession] below never runs, which leaves `sessionInfo` and
  /// `sessionToken` in place for the `/usp*` guard to rebuild the confirm URL
  /// from. That is acceptance 3 failing on the one path that asked politely, and
  /// it would be strictly worse than the code this replaced, which cleared local
  /// state synchronously before it navigated.
  ///
  /// Five seconds because the value only has to be shorter than a human's
  /// patience with a Disconnect button: the request is a courtesy, and Guardian
  /// expires the session on its own timer regardless.
  static const _apiTimeout = Duration(seconds: 5);

  /// Install the Guardian transport, then record the engagement.
  ///
  /// Both halves matter and the order does too. `activate` swaps the registered
  /// `UspClient` for a Guardian-proxied one under the mutation lock and sets
  /// `loginType` to remote; `updateSessionInfo` is what starts the expiry countdown
  /// and the status poll, and what the UI restrictions read. Recording the session
  /// *before* the transport existed would give a live countdown over a dead
  /// connection.
  ///
  /// The two build-configuration values are read here rather than passed in, so that
  /// no caller can point an RA session at the wrong Guardian — see
  /// [SupportSessionRequest].
  ///
  /// Throws whatever `activate` throws, which is the confirm view's "Connection
  /// failed" path. Deliberate: see [SessionStrategy.start] for why entry may throw
  /// where [end] may not.
  @override
  Future<void> start(Ref ref, SessionRequest request) async {
    final session = switch (request) {
      SupportSessionRequest r => r,
      // Unreachable by construction — the caller is the confirm view. See
      // [SessionRequest] for why the refusal is typed rather than coerced.
      //
      // "By construction" means by *caller*, not by route table: `localLoginRoute`
      // is in `sharedAppRoutes`, so a remote build does register the local password
      // form and someone who hand-types that location can submit it. That reaches
      // here, and `_mapToViewError` has no `ArgumentError` arm, so the form shows
      // its generic unexpected-error copy. Deliberately not given a nicer message:
      // this is a programming error, and translating it into product copy would
      // hide the one signal that a caller crossed the modes. What the form showed
      // before phase 9 was not better — a remote build has no app-origin
      // `UspClient` at all (`canUseAppOriginUspClient`), so the same submit failed
      // in the transport with an equally generic message.
      OwnCredentialsRequest() => throw ArgumentError.value(
          request,
          'request',
          'remote session entry needs a Guardian support session, not a router '
              'password',
        ),
    };

    final config = RemoteAssistanceConfig(
      guardianBaseUrl: cloudEnvironmentConfig[kCloudBase] as String,
      sessionId: session.sessionId,
      temporaryAccessToken: session.token,
      clientTypeId: kClientTypeId,
    );

    await ref.read(remoteAssistanceProvider.notifier).activate(config);

    ref.read(remoteAccessProvider.notifier).updateSessionInfo(
          session.sessionInfo,
          session.remainingSeconds,
          sessionToken: session.token,
        );
  }

  /// The URL is the credential: a `?session=` parameter *is* the engagement.
  ///
  /// [token] is taken as `?? ''` rather than left null, preserving the URL the
  /// router has always emitted — see [SupportSessionEntry] for why a half-formed
  /// link must reach the confirm view rather than be rerouted here.
  ///
  /// With no parameters this still answers [SupportSessionEntry]: a remote build's
  /// only entry is the agent UI, and the bare confirm path is where a cold load
  /// belongs. This is the arm that used to read `if (BuildConfig.isRemote())` at the
  /// end of `autoConfigurationLogic`.
  @override
  SessionEntry entryPoint(Ref ref, Uri location) {
    final raSession = location.queryParameters['session'];
    if (raSession != null && raSession.isNotEmpty) {
      final raToken = location.queryParameters['token'] ?? '';
      logger.i('[Route]: Detected Remote Assistance session: $raSession');
      return SupportSessionEntry(sessionId: raSession, token: raToken);
    }

    logger.i('[Route]: Remote build mode detected, redirecting to RA page');
    return const SupportSessionEntry();
  }

  /// Held if the USP layer is already on the Guardian transport; otherwise back to
  /// the confirm page, with or without a session to resume.
  ///
  /// Three answers, and the middle one is the mode-specific part: RA session
  /// parameters survive a page reload in `sessionStorage`, so a refresh mid-session
  /// can re-establish rather than start over. `ref.read` throughout, preserved from
  /// the redirect this replaces.
  ///
  /// The third answer is where all eight *automatic* RA endings land, and telling it
  /// apart from a cold load is what #1323 phase 5 made possible: since cause 3
  /// clears `remoteAccessProvider` on every exit, an idle timeout, a 401 on the
  /// bridge, an SSE give-up, a serial mismatch, a factory reset and a failed relogin
  /// all arrive here with no parameters. Without
  /// [SupportSessionEntry.previousSessionEnded] they rendered the confirm view's
  /// `_buildMissingParamsView()` — a red developer page reading "Missing
  /// Parameters" — because the bare path has nothing for `_hasRequiredParams`.
  @override
  SessionEntry guardEntry(Ref ref) {
    final isRemoteAssistance = ref.read(authProvider
        .select((value) => value.value?.isRemoteAssistance ?? false));
    if (isRemoteAssistance) {
      return const SessionAlreadyHeld();
    }

    final raState = ref.read(remoteAccessProvider);
    if (raState.sessionInfo != null && raState.sessionToken != null) {
      logger.i('[Route]: Remote mode refresh, redirecting to confirm page');
      return SupportSessionEntry(
        sessionId: raState.sessionInfo!.id,
        token: raState.sessionToken,
      );
    }

    final endedHere = ref.read(remoteAssistanceProvider).isActive;
    logger.i('[Route]: Remote mode no session, redirecting to RA page '
        '(endedHere: $endedHere)');
    return SupportSessionEntry(previousSessionEnded: endedHere);
  }

  @override
  SessionOutcome get destination => SessionOutcome.supportSessionEnded;

  /// Release the Guardian session, then drop everything the app holds about it.
  ///
  /// This is the sequence `remote_session_chip.dart` had, lifted minus the two
  /// mode-independent steps (navigate, `logout()`). It was correct there; the
  /// defect is that it existed *only* there, so the other ten paths into
  /// `logout()` — an idle timeout, a serial mismatch, an SSE give-up, a 401 on the
  /// bridge, a route guard — left `sessionInfo` and `sessionToken` populated.
  /// `router_provider.dart`'s `/usp*` guard then read those and redirected back to
  /// the confirm page with the old parameters, where Connect re-activated a dead
  /// session. That is acceptance 3, and the unconditional `clearSession()` below
  /// is what closes it.
  ///
  /// [EndCause.sessionLost] skips `endSessionForCA` because the token it would
  /// authenticate with is the thing that is gone — a rejected token is the most
  /// common way to get here. Skipping it is not a shortcut: attempting it costs a
  /// round-trip and a certain `ServiceError` on a path that must not throw.
  @override
  Future<void> end(Ref ref, EndCause cause) async {
    // See [_apiTimeout] — the awaited call below is the only thing between
    // `logout()` starting and any of its teardown running.
    final state = ref.read(remoteAccessProvider);
    final sessionId = state.sessionInfo?.id;
    final sessionToken = state.sessionToken;

    if (cause == EndCause.userRequested &&
        sessionId != null &&
        sessionToken != null) {
      // Best effort. Guardian expires the session on its own timer, so a failure
      // here leaks nothing that does not clean itself up, and the user has
      // already asked to leave.
      try {
        await ref
            .read(remoteAssistanceServiceProvider)
            .endSessionForCA(
              sessionToken: sessionToken,
              sessionId: sessionId,
            )
            .timeout(_apiTimeout);
        logger.d('[RA] Session ended via API');
      } catch (e) {
        // Includes TimeoutException. Everything below still runs.
        logger.w('[RA] Failed to end session via API: $e');
      }
    }

    // Unconditional, and it is the whole point: the chip disappears, the poll and
    // countdown timers stop, and `sessionStorage` is cleared so a page reload does
    // not resurrect the session either.
    ref.read(remoteAccessProvider.notifier).clearSession();
  }
}
