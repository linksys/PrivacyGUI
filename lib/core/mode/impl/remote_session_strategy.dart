import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/framework/mode/session_strategy.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';

/// Remote Assistance session ending: the *support engagement* ended. The
/// temporary token is spent and there is no login screen to return to, so the
/// destination is a terminal "session ended" surface.
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
