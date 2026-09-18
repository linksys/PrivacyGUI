import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/framework/mode/session_entry.dart';
import 'package:privacy_gui/framework/mode/session_request.dart';
import 'package:privacy_gui/framework/mode/session_strategy.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// Local / cloud sessions: the user's own router password opens one, and when it
/// ends the destination is the login screen and they can log straight back in.
class LocalSessionStrategy implements SessionStrategy {
  const LocalSessionStrategy();

  /// USP login, then device info and the services that depend on it.
  ///
  /// The order is the assertion: `fetchDeviceInfoAndInitializeServices` runs only
  /// after `tryUspLogin` returns, so a failed login never reaches it — pinned by
  /// `auth_notifier_test.dart`'s "login does not call fetchDeviceInfo if USP
  /// fails". Achieved by an `await`, not a check, which is why there is no
  /// `if` here to get wrong.
  ///
  /// Everything else `AuthNotifier.localLogin` does stays there: it is the same in
  /// every mode. See [SessionStrategy.start].
  @override
  Future<void> start(Ref ref, SessionRequest request) async {
    final password = switch (request) {
      OwnCredentialsRequest(:final password) => password,
      // Unreachable by construction — the caller is a local login form. Kept
      // because it is what makes the hybrid configuration of #1357 item 1
      // inexpressible rather than merely unlikely; see [SessionRequest].
      SupportSessionRequest() => throw ArgumentError.value(
          request,
          'request',
          'local session entry needs the router password, not a Guardian '
              'support session',
        ),
    };

    await ref.read(uspAuthCoordinatorProvider).tryUspLogin(password);
    logger.d('[Auth]: localLogin: USP login succeeded');
    await ref
        .read(sessionProvider.notifier)
        .fetchDeviceInfoAndInitializeServices();
  }

  /// Always the user's own credentials, whatever the URL says.
  ///
  /// The `?session=` warning is the entire reason this member reads [location] in a
  /// mode that ignores it — see [SessionStrategy.entryPoint]. Nothing sanitises the
  /// parameter out: nothing downstream reads it once this declines, and rewriting
  /// the location here would fight the `?session=` the login redirect already
  /// passes through.
  @override
  SessionEntry entryPoint(Ref ref, Uri location) {
    final raSession = location.queryParameters['session'];
    if (raSession != null && raSession.isNotEmpty) {
      logger.w('[Route]: RA session param in a non-Remote build, ignoring');
    }
    return const OwnCredentialsEntry();
  }

  /// Held if the app is logged in; otherwise back to the login flow.
  ///
  /// `ref.watch`, not `read`, and deliberately: the router's `redirect` re-runs
  /// when the provider it watched changes, which is how a `/usp*` location becomes
  /// reachable the moment a login completes. The remote implementation reads
  /// instead, for the reason recorded on [SessionStrategy.guardEntry].
  ///
  /// There is no "restorable session" arm. A local password is not persisted across
  /// a reload in a form this could re-drive, so the absence is the mode's answer,
  /// not a gap.
  @override
  SessionEntry guardEntry(Ref ref) {
    final isLoggedIn = ref.watch(
        authProvider.select((value) => value.value?.isLoggedIn ?? false));
    return isLoggedIn
        ? const SessionAlreadyHeld()
        : const OwnCredentialsEntry();
  }

  @override
  SessionOutcome get destination => SessionOutcome.loginPage;

  /// Nothing to tear down.
  ///
  /// **This emptiness is the content of acceptance 8, not a stub.** Local logout
  /// already did everything it needed inside `logout()` itself, and this member
  /// adding nothing is the literal sense in which "local behaviour unchanged"
  /// holds: same calls, same order, one extra completed future in front of them.
  ///
  /// Three things that look like they belong here and do not:
  ///
  ///   - **clearing app credentials** — mode-independent, and `logout()` still owns
  ///     it. See [SessionStrategy.end].
  ///   - **clearing the stored local password.** `logout()` already decides that,
  ///     and it decides it differently per build (a cloud build keeps the cloud
  ///     login). Re-deciding it here would change local behaviour, which
  ///     acceptance 8 forbids.
  ///   - **a route.** [SessionOutcome.loginPage] deliberately does not name one;
  ///     the route redirect already knows where a credential-less app goes, and it
  ///     knows about PnP and cloud-vs-local, which this class does not.
  ///
  /// [cause] is ignored, and that is the measured finding that keeps [EndCause] at
  /// two values: locally an idle timeout, a failed relogin and the user pressing
  /// Logout all end the same way. Only remote reads it.
  @override
  Future<void> end(Ref ref, EndCause cause) async {}
}
