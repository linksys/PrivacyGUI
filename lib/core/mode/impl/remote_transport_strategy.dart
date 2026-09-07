import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/mode/impl/bridge_config.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
import 'package:privacy_gui/core/usp/services/sse_remote_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';
import 'package:privacy_gui/framework/mode/transport_strategy.dart';

/// `browser → Guardian → router`. Every byte crosses a proxy that scopes it to
/// one support session.
class RemoteTransportStrategy implements TransportStrategy {
  /// The credential cause, injected — see [LocalTransportStrategy.credential]
  /// for why this is not a hard-coded `AuthBehavior.remote`.
  final CredentialStrategy credential;

  const RemoteTransportStrategy({required this.credential});

  /// Null until the Guardian session exists.
  ///
  /// The mode is decided at build time, the session only when the agent opens a
  /// `?session=&token=` link, so there is a real window in which the app knows
  /// it is remote and cannot yet say where "remote" points. `null` is that
  /// window; `uspBridgeClientProvider` returns null for it, exactly as the
  /// pre-#1474 `if (config == null) return null;` did.
  ///
  /// **The `select` is load-bearing.** It is a `.select((s) => s.config)` rather
  /// than a bare `watch`, because `RemoteAssistanceState` also carries
  /// `isActive`, and a bare watch rebuilt — and so re-created — the bridge and
  /// its SSE manager on an `isActive` flip that changed nothing about the
  /// transport. Keep the select if this method is edited.
  @override
  BridgeConfig? bridgeConfig(Ref ref) {
    final config = ref.watch(remoteAssistanceProvider.select((s) => s.config));
    if (config == null) return null;
    return BridgeConfig(
      endpoints: BridgeEndpoints.remote(config.sessionId),
      baseUrl: config.guardianOrigin,
      authToken: config.temporaryAccessToken,
      clientTypeId: config.clientTypeId,
      authBehavior: credential.authBehavior,
    );
  }

  @override
  SseOperationStrategy sseStrategy(UspBridgeClient bridge) =>
      RemoteSseStrategy(bridge);
}
