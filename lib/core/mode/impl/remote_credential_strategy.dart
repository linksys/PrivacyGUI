import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';

/// Remote Assistance credential handling: Guardian minted a temporary access
/// token for one support session, so a 401 means that session is over and a
/// retry re-asks a question whose answer is now permanent.
class RemoteCredentialStrategy implements CredentialStrategy {
  const RemoteCredentialStrategy();

  @override
  AuthBehavior get authBehavior => AuthBehavior.remote;

  /// Nothing to re-establish, and nothing to compare. **This is the fix in
  /// #1323, acceptances 4 and 5.**
  ///
  /// Both of the local steps are not merely unnecessary here, they are actively
  /// wrong, and each produced a distinct symptom:
  ///
  ///  * `restoreSession()` would re-login with a `temporaryAccessToken` that
  ///    cannot be refreshed. Guardian's answer does not change with time, so the
  ///    retry cost the probe a full round trip and then failed the recovery that
  ///    had already succeeded at the transport step.
  ///  * `RouterFingerprintService.matches()` compares against a serial stored at
  ///    *local* login. A support session never wrote one, and `matches()`
  ///    returns `false` for a null stored value — so every RA recovery that got
  ///    past step 2 reported `serialMismatch`, and the notifier turned that into
  ///    a forced logout with the Guardian session still alive.
  ///
  /// Returning a constant `true` is not a stub: identity is guaranteed upstream.
  /// Guardian binds a session to one serial number server-side and proxies only
  /// to that agent, so "a different router answered" is not a reachable state —
  /// there is no address for a replacement box to answer on. If the *session*
  /// has ended, the agent stops proxying and
  /// `RemoteTransportStrategy.isRouterReachable` returns false, which the caller
  /// already treats as "keep waiting".
  @override
  Future<bool> reestablishAfterOutage(Ref ref) async => true;

  /// Acceptance 9. Called by `RemoteAssistanceNotifier.activate()`, which is
  /// reachable a second time without any mode switch: an idle timeout or a
  /// `forceLogout` logs the user out while the Guardian session is still alive,
  /// and one tap on Connect gets back here with a *new* token.
  ///
  /// Since #1322 the `UspClient` façade is re-pointed rather than replaced, so
  /// `uspAuthCoordinatorProvider`'s single `ref.watch` never fires and the
  /// coordinator is never rebuilt — its per-session bookkeeping would otherwise
  /// describe the previous engagement.
  @override
  void onCredentialRebound(Ref ref) =>
      ref.read(uspAuthCoordinatorProvider).resetSessionState();
}
