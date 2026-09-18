import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
import 'package:privacy_gui/core/usp/services/sse_local_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/bridge_config.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';
import 'package:privacy_gui/framework/mode/transport_strategy.dart';

/// `browser → router`. The app is served by the box it is configuring.
class LocalTransportStrategy implements TransportStrategy {
  /// The credential cause, injected rather than hard-coded.
  ///
  /// [BridgeConfig.authBehavior] is where the transport and credential causes
  /// meet, and it is the credential cause that owns the answer. Passing the
  /// strategy in — instead of writing `AuthBehavior.local` here — is what keeps
  /// the two independent: phase 6 has to make an RA session that behaves like a
  /// local one for exactly one operation, and a hard-coded literal in the
  /// transport would have to be found and unwound first.
  final CredentialStrategy credential;

  const LocalTransportStrategy({required this.credential});

  /// Never null: a local build always knows its transport, because the transport
  /// is "wherever this page came from". No session handshake, no host to learn.
  ///
  /// [ref] is accepted and unused. That is the contract's shape, not an
  /// oversight — the remote answer must watch a provider, and a signature that
  /// differed per mode would put the `if` back.
  @override
  BridgeConfig? bridgeConfig(Ref ref) => BridgeConfig(
        endpoints: BridgeEndpoints.local,
        authBehavior: credential.authBehavior,
      );

  @override
  SseOperationStrategy sseStrategy(UspBridgeClient bridge) =>
      LocalSseStrategy(bridge);

  /// The on-router bridge's own health endpoint — verbatim what
  /// `RecoveryProbeService.probe()` step 1 did before #1323, including the two
  /// field checks and the swallowed exception.
  ///
  /// `agent_connected` and `agent_state` are both required because the bridge
  /// answers 200 while OBUSPA behind it is still starting: a `health()` that
  /// merely returned is not a router that can serve a `Get`.
  @override
  Future<bool> isRouterReachable(Ref ref) async {
    // Read, not watch: this runs inside a probe loop, and a rebuild of the
    // bridge mid-outage must not re-enter the probe. `read` also survives the
    // null window that `bridgeConfig` documents — the pre-#1323 provider
    // resolved the bridge with `bridge!` at construction time and threw a
    // `TypeError` if a session ended while a probe loop was still running.
    final bridge = ref.read(uspBridgeClientProvider);
    if (bridge == null) return false;

    try {
      final health = await bridge.health();
      final agentConnected = health['agent_connected'] as bool? ?? false;
      final agentState = health['agent_state'] as String? ?? '';
      if (!agentConnected || agentState != 'ready') {
        logger.d('[Recovery] Bridge healthy but agent not ready: '
            'connected=$agentConnected, state=$agentState');
        return false;
      }
      return true;
    } catch (e) {
      logger.d('[Recovery] Health check failed: $e');
      return false;
    }
  }
}
