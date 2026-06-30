import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';

enum ProbeResult {
  unreachable,
  recovered,
  serialMismatch,
}

class RecoveryProbeService {
  RecoveryProbeService({
    required this.bridge,
    required this.authCoordinator,
    required this.fingerprintService,
  });

  final UspBridgeClient bridge;
  final UspAuthCoordinator authCoordinator;
  final RouterFingerprintService fingerprintService;

  Future<ProbeResult> probe({bool healthOnly = false}) async {
    try {
      final healthResponse = await bridge.health();
      final agentConnected =
          healthResponse['agent_connected'] as bool? ?? false;
      final agentState = healthResponse['agent_state'] as String? ?? '';
      if (!agentConnected || agentState != 'ready') {
        logger.d('[Recovery] Health check passed but agent not ready '
            '(connected=$agentConnected, state=$agentState)');
        return ProbeResult.unreachable;
      }
      logger.d('[Recovery] Health check passed');
    } catch (e) {
      logger.d('[Recovery] Health check failed: $e');
      return ProbeResult.unreachable;
    }

    if (healthOnly) {
      logger.i('[Recovery] healthOnly mode — router reachable, done');
      return ProbeResult.recovered;
    }

    try {
      await authCoordinator.restoreSession(isRecovering: true);
      logger.d('[Recovery] Session restored');
    } catch (e) {
      logger.d('[Recovery] Session restore failed: $e');
      return ProbeResult.unreachable;
    }

    try {
      final serial = await authCoordinator.getSerialNumber();
      final matches = await fingerprintService.matches(serial);
      if (matches) {
        logger.i('[Recovery] Serial match — recovered');
        return ProbeResult.recovered;
      } else {
        logger.w('[Recovery] Serial mismatch — different router detected');
        return ProbeResult.serialMismatch;
      }
    } catch (e) {
      logger.w('[Recovery] Serial read failed: $e');
      return ProbeResult.unreachable;
    }
  }
}
