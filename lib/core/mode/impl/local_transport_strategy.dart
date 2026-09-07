import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/mode/impl/bridge_config.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
import 'package:privacy_gui/core/usp/services/sse_local_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
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
}
