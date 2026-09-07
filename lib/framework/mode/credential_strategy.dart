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
}
