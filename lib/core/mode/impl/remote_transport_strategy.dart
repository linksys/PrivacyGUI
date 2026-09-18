import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
import 'package:privacy_gui/core/usp/services/sse_remote_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/bridge_config.dart';
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
      // The three reads Guardian serves over its own notification store, which
      // the router has no counterpart for. Non-null here and null in the local
      // arm is the whole of how #1580's page learns whether it has anything to
      // read; see [RemoteReads].
      remoteReads: RemoteReads.forSession(config.sessionId),
    );
  }

  @override
  SseOperationStrategy sseStrategy(UspBridgeClient bridge) =>
      RemoteSseStrategy(bridge);

  /// Guardian's own `/usp/health`, which is a purpose-built liveness check with a
  /// ~5-second budget of its own — not a full object-model round trip.
  ///
  /// **The claim this replaced was false.** Until #1576 this read
  /// `Device.DeviceInfo.SerialNumber` over `POST /actions/usp`, on the recorded
  /// grounds that `BridgeEndpoints.remote()`'s `health` path was a fabrication
  /// Guardian did not serve. Guardian's OpenAPI spec serves it, at exactly the path
  /// we have always declared. The probe runs every 30 s
  /// (`RemoteProximityStrategy`), so trading a whole object-model round trip for a
  /// 5-second yes/no is a straight win.
  ///
  /// Any `200` is reachable, **including a partial answer**: firmware that lacks
  /// one of the seven parameters has its key omitted rather than sent as null, and
  /// only an answer carrying none of them is a `400`. So there is nothing to read
  /// out of the body — the status is the whole verdict. That is the one asymmetry
  /// with `LocalTransportStrategy`, which reads `agent_connected` / `agent_state`
  /// because the on-router bridge answers `200` while OBUSPA behind it is still
  /// starting. Guardian has already talked to the device by the time it answers.
  ///
  /// **The `404` fallback is temporary and dated.** The spec is documentation, and
  /// whether QA has the endpoint deployed is #1575's verification item 3, still
  /// open on 2026-09-18. Pointed at an undeployed endpoint this probe would answer
  /// false forever and an RA session would never recover from a transient drop —
  /// strictly worse than the workaround it replaces. So a `404`, and only a `404`,
  /// falls back to the old read: any other status, a timeout or a throw is the
  /// router being away, which is what the probe is for. **Delete
  /// [_reachableViaSerialNumber] and this arm once that item is answered** (Austin's
  /// call, 2026-09-18); it is a deployment hedge, not a firmware one, so it has an
  /// end date rather than being the permanent-absence case
  /// `dev-phase-no-fw-back-compat` would rule out entirely.
  ///
  /// Never throws — `RecoveryProbeService.probe()` has no try/catch around the
  /// call, and `Timer.periodic` does not await its callback, so an escape would be
  /// an unhandled async error with the probe loop still running.
  @override
  Future<bool> isRouterReachable(Ref ref) async {
    // Read, not watch: this runs inside a probe loop, and a rebuild of the bridge
    // mid-outage must not re-enter the probe.
    final bridge = ref.read(uspBridgeClientProvider);
    if (bridge == null) return false;

    try {
      await bridge.health();
      return true;
    } on BridgeReadException catch (e) {
      if (e.isNotFound) {
        logger.w('[Recovery] Guardian has no /usp/health here (404) — '
            'falling back to the pre-#1576 read. See #1575 item 3.');
        return _reachableViaSerialNumber(ref);
      }
      logger.d('[Recovery] Guardian health check answered ${e.statusCode}');
      return false;
    } catch (e) {
      logger.d('[Recovery] Guardian health check failed: $e');
      return false;
    }
  }

  /// The pre-#1576 probe, kept only for a deployment that has no `/usp/health`.
  ///
  /// `Device.DeviceInfo.SerialNumber` is the path because it is the cheapest
  /// parameter on the object model that is always present and never permission
  /// gated: reaching it proves the whole chain — browser → Guardian → agent →
  /// OBUSPA → the box — is carrying traffic. The value is deliberately not
  /// compared to anything; see [RemoteCredentialStrategy] for why identity needs
  /// no check here, and #1576 for why comparing the serial `/usp/health` now
  /// returns is a separate decision from this one.
  Future<bool> _reachableViaSerialNumber(Ref ref) async {
    final usp = ref.read(uspClientProvider);
    if (usp == null) return false;

    try {
      final result = await usp.get([_kReachabilityPath]);
      final reachable = result[_kReachabilityPath] != null;
      if (!reachable) {
        logger.d('[Recovery] Guardian answered without $_kReachabilityPath');
      }
      return reachable;
    } catch (e) {
      logger.d('[Recovery] Guardian-proxied read failed: $e');
      return false;
    }
  }
}

const _kReachabilityPath = 'Device.DeviceInfo.SerialNumber';
