import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';

/// **Cause 2 — who holds the credential, and what expiry means.**
///
/// Local: the browser holds the router's own session, and a 401 is a transient
/// state a retry can fix. Remote Assistance: Guardian holds a *temporary access
/// token* minted for one support session, and a 401 means that session is over —
/// retrying re-asks a question that now has a permanent answer.
///
/// This is the cause behind [AuthBehavior.shouldRetryOnFailure], which is why
/// that flag is the whole contract today rather than a second copy of the same
/// decision.
///
/// See `doc/mode_strategy/mode_strategy_guide.md`. Rule 3: this contract lives
/// in `lib/framework/mode/`, its implementations in `lib/core/mode/impl/`.
abstract class CredentialStrategy {
  /// How the transport must treat an auth failure.
  ///
  /// [AuthBehavior] predates #1474 and already carries exactly this
  /// distinction — `AuthBehavior.local` retries, `AuthBehavior.remote` does
  /// not — so the strategy *returns* it rather than restating it. That keeps
  /// `UspBridgeClient`'s existing parameter and its 1 read site untouched: this
  /// phase moves the `if` that chose the value, not the value.
  AuthBehavior get authBehavior;

  /// Put the credential back to work after the router was unreachable, and say
  /// whether the app may keep the session it had.
  ///
  /// `true` means "carry on"; `false` means "this is not the box you were
  /// talking to". Throwing means "still not reachable" — the caller counts that
  /// as another failed probe, not as a verdict.
  ///
  /// **One member for two steps, because no mode does one without the other.**
  /// Locally this is re-login plus a serial-number comparison against the stored
  /// fingerprint: a router that came back on a factory-default config answers on
  /// the same address with a different identity, and continuing would show one
  /// router's settings while writing to another. Remotely *neither* step
  /// applies, and that is the substance of #1323: the temporary access token
  /// cannot be refreshed, so `restoreSession()` re-asks a question with a
  /// permanent answer, and there is no stored fingerprint for a support session,
  /// so `matches()` compares against `null` and returns false — which the caller
  /// read as "different router" and turned into a forced logout. Splitting this
  /// into `restore()` and `verifyIdentity()` would give the remote strategy two
  /// no-ops instead of one, and invite a later change to implement just one of
  /// them.
  Future<bool> reestablishAfterOutage(Ref ref);

  /// Drop whatever per-session state this mode's credential machinery caches,
  /// because the credential was just replaced.
  ///
  /// Acceptance 9 of #1323. `UspAuthCoordinator` is a non-autoDispose singleton
  /// whose only `ref.watch` is on `uspClientProvider`, and #1322 made that
  /// provider's value stable across a re-`activate()` — so the coordinator is
  /// now never rebuilt, and its refresh/restore bookkeeping
  /// (`_lastTokenRefresh`, `_lastRestoreAttempt`, `_lastRestoreResult`,
  /// `_restoreInProgress`) survives into the *next* Guardian session. A stale
  /// `_lastRestoreResult == false` there makes the new session look already
  /// broken.
  ///
  /// The mode decides, not the coordinator: locally the credential is not
  /// replaced by anything — a re-login is the same authority as before — so
  /// there is nothing to clear, and clearing it unconditionally inside the
  /// coordinator would throw away a valid refresh timestamp on every ordinary
  /// re-auth.
  void onCredentialRebound(Ref ref);
}
