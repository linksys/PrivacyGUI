import 'dart:convert';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';

class AutoIPoETestData {
  static const id = 'f954a865-22c0-4dad-96d0-714cd58af8f4';
  static const settings =
      AutoIPoESettings(isEnabled: true, selectedMode: AutoIPoEMode.auto);
  static AutoIPoESnapshot snapshot(
          {String? requestId,
          int? exitCode,
          bool busy = false,
          bool verified = false,
          String phase = 'completed',
          bool reset = false}) =>
      AutoIPoESnapshot(
        capabilities: const AutoIPoECapabilities(
            isSupported: true,
            supportedModes: [AutoIPoEMode.auto],
            blocksManualIPv6Configuration: true,
            requiresResetOnExit: true),
        settings: settings,
        requestId: requestId,
        operationId: requestId,
        exitCode: exitCode,
        accepted: requestId != null,
        runtime: const AutoIPoEStatus.init().copyWith(
            isEnabled: true,
            isCurrentWANType: true,
            applyState:
                verified ? AutoIPoEApplyState.active : AutoIPoEApplyState.idle,
            connectivityVerified: verified,
            isBusy: busy,
            lastResult: reset && exitCode == 0 ? 'ResetCompleted' : null,
            terminalResultSupported: true,
            terminalResult: exitCode == null
                ? null
                : AutoIPoETerminalResult(
                    phase: AutoIPoETerminalPhase.fromValue(phase)!,
                    operation: reset ? 'reset' : 'auto_ipoe',
                    exitCode: exitCode,
                    reason: phase == 'retry_scheduled'
                        ? 'RetryScheduled'
                        : phase == 'busy'
                            ? 'Busy'
                            : exitCode == 0
                                ? (reset ? 'ResetCompleted' : 'Completed')
                                : 'ProcessFailed',
                    connectivityVerified: verified)),
      );
  static AutoIPoESnapshot recoverySnapshot({
    required bool capabilitiesAvailable,
    bool supported = false,
    String? resetRequestId,
  }) {
    final resetComplete = resetRequestId != null;
    final result = snapshot(
      requestId: resetRequestId,
      exitCode: resetComplete ? 0 : null,
      reset: resetComplete,
    );
    return AutoIPoESnapshot(
      capabilities:
          supported ? result.capabilities : const AutoIPoECapabilities.init(),
      capabilitiesAvailable: capabilitiesAvailable,
      settings: resetComplete ? const AutoIPoESettings.init() : result.settings,
      runtime: result.runtime.copyWith(
        isEnabled: !resetComplete,
        isCurrentWANType: !resetComplete,
        needsResetBeforeLeaving: !resetComplete,
      ),
      requestId: result.requestId,
      operationId: result.operationId,
      exitCode: result.exitCode,
      accepted: result.accepted,
    );
  }

  static Map<String, dynamic> wire({String apiVersion = '1'}) {
    final s = snapshot();
    return {
      'Device.X_LINKSYS_AutoIPoE.APIVersion': apiVersion,
      'Device.X_LINKSYS_AutoIPoE.Capabilities':
          jsonEncode(s.capabilities.toMap()),
      'Device.X_LINKSYS_AutoIPoE.Settings': jsonEncode(s.settings.toMap()),
      'Device.X_LINKSYS_AutoIPoE.Status': jsonEncode(s.runtime.toMap()),
      'Device.X_LINKSYS_AutoIPoE.Log': jsonEncode(s.log.toMap()),
    };
  }
}
