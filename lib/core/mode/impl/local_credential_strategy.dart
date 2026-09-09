import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';

/// Local / cloud credential handling: the browser holds the router's own
/// session, so a 401 is transient and worth retrying.
class LocalCredentialStrategy implements CredentialStrategy {
  const LocalCredentialStrategy();

  @override
  AuthBehavior get authBehavior => AuthBehavior.local;

  /// Steps 2 and 3 of the pre-#1323 `RecoveryProbeService.probe()`, verbatim and
  /// in the same order.
  ///
  /// Re-login first: the router restarted, so the old session cookie is gone and
  /// the serial read below would 401 without it. Then compare identity, because
  /// a factory-reset router answers on the same address as a *different* box —
  /// same address, blank config, no stored fingerprint match — and carrying on
  /// would show the previous router's settings while writing to this one.
  ///
  /// Note what is *not* here: no try/catch. A throw from either call is the
  /// caller's "still unreachable", which is what both of the two separate
  /// try/catch blocks in the old service did with it.
  @override
  Future<bool> reestablishAfterOutage(Ref ref) async {
    final coordinator = ref.read(uspAuthCoordinatorProvider);
    await coordinator.restoreSession(isRecovering: true);

    final serial = await coordinator.getSerialNumber();
    return ref.read(routerFingerprintServiceProvider).matches(serial);
  }

  /// Nothing to drop. A local re-login replaces a credential with another
  /// credential from the same authority, so the coordinator's refresh timestamps
  /// are still about this session — clearing them here would discard a valid
  /// `_lastTokenRefresh` on every ordinary re-auth and put the app back to
  /// refreshing on every SSE heartbeat.
  @override
  void onCredentialRebound(Ref ref) {}
}
