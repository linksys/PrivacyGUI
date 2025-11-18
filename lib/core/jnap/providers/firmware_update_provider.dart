import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/services/firmware_update_service.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_ui_model.dart';

final firmwareUpdateProvider =
    NotifierProvider<FirmwareUpdateNotifier, FirmwareUpdateState>(
        () => FirmwareUpdateNotifier());

class FirmwareUpdateNotifier extends Notifier<FirmwareUpdateState> {
  StreamSubscription? _sub;
  late final FirmwareUpdateService _firmwareUpdateService =
      ref.read(firmwareUpdateServiceProvider);

  @override
  FirmwareUpdateState build() {
    final fwUpdateSettingsRaw = ref.watch(pollingProvider.select<JNAPResult?>(
        (value) => value.value?.data[JNAPAction.getFirmwareUpdateSettings]));

    FirmwareUpdateSettings? fwUpdateSettings;
    if (fwUpdateSettingsRaw is JNAPSuccess) {
      fwUpdateSettings =
          FirmwareUpdateSettings.fromMap(fwUpdateSettingsRaw.output);
    }

    final state = FirmwareUpdateState(
      settings: fwUpdateSettings ??
          FirmwareUpdateSettings(
            updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
            autoUpdateWindow: FirmwareAutoUpdateWindow.simple(),
          ),
      nodesStatus: const [],
    );
    logger.d('[FIRMWARE]: Build: state = ${state.toJson()}');
    return state;
  }

  Future setFirmwareUpdatePolicy(String policy) async {
    final updatedSettings = await _firmwareUpdateService
        .setFirmwareUpdatePolicy(policy, state.settings);
    state = state.copyWith(settings: updatedSettings);
  }

  Future fetchAvailableFirmwareUpdates() async {
    final cachedCandidates = ref.read(firmwareUpdateCandidateProvider);
    final statusRecord = await _firmwareUpdateService
        .fetchAvailableFirmwareUpdates(state.nodesStatus, cachedCandidates);
    state = state.copyWith(
      nodesStatus: statusRecord.$1,
      isWaitingChildrenAfterUpdating: statusRecord.$2,
    );
  }

  Future updateFirmware() async {
    logger.i('[FIRMWARE]: Update firmware: Start');
    state = state.copyWith(isUpdating: true);
    ref.read(pollingProvider.notifier).stopPolling();
    // Save the current status list
    ref.read(firmwareUpdateCandidateProvider.notifier).state =
        state.nodesStatus;
    logger.d('[FIRMWARE]: Saved current status records: ${state.nodesStatus}');

    _sub?.cancel(); // Cancel existing subscription
    _sub = _firmwareUpdateService.updateFirmware(
      state.nodesStatus,
      (bool exceedMaxRetry) {
        // onCompleted callback
        state = state.copyWith(isRetryMaxReached: exceedMaxRetry);
        if (exceedMaxRetry) {
          logger.e(
              '[FIRMWARE]: Firmware update halts due to exceeding the maximum retry limit');
          state = state.copyWith(isUpdating: false);
          _sub?.cancel();
        } else {
          logger.i('[FIRMWARE]: Firmware update: Done!');
          final candidates = ref.read(firmwareUpdateCandidateProvider);
          // assign new firmware version back to node status from candidate
          final nodeStatus = state.nodesStatus?.map((e) => e.copyWith(
              newFirmwareVersion: candidates
                  ?.firstWhereOrNull((c) => c.deviceId == e.deviceId)
                  ?.newFirmwareVersion));
          state = state.copyWith(nodesStatus: nodeStatus?.toList());
          finishFirmwareUpdate().then((_) {
            _sub?.cancel();
          });
        }
      },
    ).listen(
      (statusList) {
        state = state.copyWith(nodesStatus: statusList);
      },
      onError: (error, stackTrace) {
        logger.e('[FIRMWARE]: Firmware update stream error: $error');
        // According to the design, isUpdating should remain true as the service is designed to retry.
        // The onCompleted callback will eventually handle the final state (success or exceedMaxRetry).
      },
    );
  }

  Future finishFirmwareUpdate() async {
    await _firmwareUpdateService.finishFirmwareUpdate();
    ref.read(pollingProvider.notifier).startPolling();
    // The state update for isUpdating and nodesStatus is handled by fetchAvailableFirmwareUpdates
    state = state.copyWith(isUpdating: false);
  }

  int getAvailableUpdateNumber() {
    return _firmwareUpdateService.getAvailableUpdateNumber(state.nodesStatus);
  }

  bool isFailedCheckFirmwareUpdate() {
    return _firmwareUpdateService
        .isFailedCheckFirmwareUpdate(state.nodesStatus);
  }
}

// This provider is used to save the original list of all nodes and their fw status
// when the firmware update right started
final firmwareUpdateCandidateProvider =
    StateProvider<List<FirmwareUpdateUIModel>?>((ref) {
  return null;
});
