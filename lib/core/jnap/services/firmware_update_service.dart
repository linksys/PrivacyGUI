// lib/core/jnap/services/firmware_update_service.dart

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_ui_model.dart';

// Define the provider for FirmwareUpdateService
final firmwareUpdateServiceProvider =
    Provider((ref) => FirmwareUpdateService(ref));

class FirmwareUpdateService {
  final Ref _ref;

  FirmwareUpdateService(this._ref);

  RouterRepository get _routerRepo => _ref.read(routerRepositoryProvider);
  DeviceManagerState get _deviceManagerState =>
      _ref.read(deviceManagerProvider);

  static const Duration firmwareCheckPeriod = Duration(minutes: 5);

  FirmwareUpdateUIModel _transformToUIModel(FirmwareUpdateStatus status) {
    if (status is NodesFirmwareUpdateStatus) {
      final device = _deviceManagerState.deviceList
          .firstWhereOrNull((d) => d.deviceID == status.deviceUUID);
      return FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(status, device);
    } else {
      // For a single-node setup, the device is the master device.
      final device = _deviceManagerState.masterDevice;
      return FirmwareUpdateUIModel.fromFirmwareUpdateStatus(status, device);
    }
  }

  Future<FirmwareUpdateSettings> setFirmwareUpdatePolicy(
      String policy, FirmwareUpdateSettings currentSettings) async {
    final newSettings = currentSettings.copyWith(updatePolicy: policy);
    await _routerRepo.send(
      JNAPAction.setFirmwareUpdateSettings,
      auth: true,
      cacheLevel: CacheLevel.noCache,
      data: newSettings.toMap(),
    );
    // After setting, fetch the updated settings from remote to ensure consistency
    await _routerRepo.send(
      JNAPAction.getFirmwareUpdateSettings,
      auth: true,
      fetchRemote: true,
    );
    return newSettings;
  }

  Future<(List<FirmwareUpdateUIModel>, bool)> fetchAvailableFirmwareUpdates(
      List<FirmwareUpdateUIModel>? currentNodesStatus,
      List<FirmwareUpdateUIModel>? cachedCandidates) async {
    logger.i('[FIRMWARE]: Examine if there are firmware updates available');
    final benchmark = BenchMarkLogger(name: 'FirmwareUpdate');
    benchmark.start();
    final resultList = await fetchFirmwareUpdateStream(
            force: true, retry: 2, currentNodesStatus: currentNodesStatus)
        .last
        .onError((error, stackTrace) => []);
    benchmark.end();

    final uiModels = resultList;

    bool isWaitingChildrenAfterUpdating = false;
    if (cachedCandidates != null) {
      final updatingNode =
          uiModels.firstWhereOrNull((element) => element.operation != null);
      if (updatingNode != null) {
        final updatingChildNode = cachedCandidates.firstWhereOrNull((element) =>
            element.deviceId == updatingNode.deviceId &&
            element.isMaster == false);
        if (updatingChildNode != null) {
          isWaitingChildrenAfterUpdating = true;
        }
      }
    }

    return (uiModels, isWaitingChildrenAfterUpdating);
  }

  Stream<List<FirmwareUpdateUIModel>> fetchFirmwareUpdateStream(
      {bool force = false,
      int retry = 3,
      List<FirmwareUpdateUIModel>? currentNodesStatus}) async* {
    final lastCheckTime =
        (currentNodesStatus?.map((e) => e.lastSuccessfulCheckTime).toList() ??
                    [])
                .map((e) => DateTime.tryParse(e))
                .map((e) => e?.millisecondsSinceEpoch ?? 0)
                .maxOrNull ??
            0;
    if (!_isNeedDoFetch(lastCheckTime: lastCheckTime) && !force) {
      logger.i(
          '[FIRMWARE]: Skip checking firmware update avaliable: last check time {${DateTime.fromMillisecondsSinceEpoch(lastCheckTime)}}');
      yield [];
    } else {
      final action = getIt.get<ServiceHelper>().isSupportNodeFirmwareUpdate()
          ? JNAPAction.nodesUpdateFirmwareNow
          : JNAPAction.updateFirmwareNow;
      await _routerRepo
          .send(
            action,
            data: {'onlyCheck': true},
            cacheLevel: CacheLevel.noCache,
            fetchRemote: true,
            auth: true,
            retries: 0,
          )
          .then((_) {});
      yield* _startCheckFirmwareUpdateStatus(
          retryTimes: retry, onCompleted: (_) {});
    }
  }

  @visibleForTesting
  bool isNeedDoFetch({required int lastCheckTime}) {
    return _isNeedDoFetch(lastCheckTime: lastCheckTime);
  }

  bool _isNeedDoFetch({required int lastCheckTime}) {
    final period = firmwareCheckPeriod.inMilliseconds;
    return (DateTime.now().millisecondsSinceEpoch - lastCheckTime) >= period;
  }

  @visibleForTesting
  Stream<List<FirmwareUpdateUIModel>> startCheckFirmwareUpdateStatus({
    int? retryTimes = 1,
    int? retryDelayInMilliSec,
    bool Function(JNAPResult)? stopCondition,
    Function(bool exceedMaxRetry)? onCompleted,
  }) =>
      _startCheckFirmwareUpdateStatus(
        retryTimes: retryTimes,
        retryDelayInMilliSec: retryDelayInMilliSec,
        stopCondition: stopCondition,
        onCompleted: onCompleted,
      );

  Stream<List<FirmwareUpdateUIModel>> _startCheckFirmwareUpdateStatus({
    int? retryTimes = 1,
    int? retryDelayInMilliSec,
    bool Function(JNAPResult)? stopCondition,
    Function(bool exceedMaxRetry)? onCompleted,
  }) {
    final action = getIt.get<ServiceHelper>().isSupportNodeFirmwareUpdate()
        ? JNAPAction.getNodesFirmwareUpdateStatus
        : JNAPAction.getFirmwareUpdateStatus;
    return _routerRepo
        .scheduledCommand(
      action: action,
      maxRetry: retryTimes ?? -1,
      retryDelayInMilliSec: retryDelayInMilliSec ?? 2000,
      condition: stopCondition,
      onCompleted: onCompleted,
      requestTimeoutOverride: 3000,
      auth: true,
    )
        .map((result) {
      if (result is! JNAPSuccess) {
        throw result;
      }
      final statusList = action == JNAPAction.getNodesFirmwareUpdateStatus
          ? List.from(result.output['firmwareUpdateStatus'])
              .map((e) => NodesFirmwareUpdateStatus.fromMap(e))
              .toList()
          : [FirmwareUpdateStatus.fromMap(result.output)];
      return statusList.map(_transformToUIModel).toList();
    });
  }

  ///
  /// Check all nodes connect back
  ///
  // @visibleForTesting // This annotation is for Notifier, not for Service
  bool isRecordConsistent(
    List<FirmwareUpdateUIModel> list,
    List<FirmwareUpdateUIModel> records,
  ) =>
      _isRecordConsistent(list, records);

  bool _isRecordConsistent(
    List<FirmwareUpdateUIModel> list,
    List<FirmwareUpdateUIModel> records,
  ) {
    checkExist(FirmwareUpdateUIModel model) {
      return list.any((e) => e.deviceId == model.deviceId);
    }

    return records.fold<bool>(
        true, (value, element) => value & checkExist(element));
  }

  int getAvailableUpdateNumber(
      List<FirmwareUpdateUIModel>? currentNodesStatus) {
    return (currentNodesStatus ?? [])
        .where((e) => e.availableUpdate != null)
        .length;
  }

  @visibleForTesting
  bool checkFirmwareUpdateComplete(
    JNAPResult result,
    List<FirmwareUpdateUIModel> records,
  ) {
    return _checkFirmwareUpdateComplete(result, records);
  }

  bool _checkFirmwareUpdateComplete(
    JNAPResult result,
    List<FirmwareUpdateUIModel> records,
  ) {
    if (result is JNAPSuccess) {
      final statusList = switch (getIt.get<ServiceHelper>().isSupportNodeFirmwareUpdate()) {
        false => [FirmwareUpdateStatus.fromMap(result.output)],
        true => List.from(result.output['firmwareUpdateStatus'])
            .map((e) => NodesFirmwareUpdateStatus.fromMap(e))
            .toList()
      };

      final uiModels = statusList.map(_transformToUIModel).toList();
      final isDone = !uiModels.any((status) => status.operation != null);
      logger.i('[FIRMWARE]: Check if all updates are finished: $isDone');
      return isDone;
    } else {
      logger.e('[FIRMWARE]: Error: $result - Maybe rebooting');
      return false;
    }
  }

  Stream<List<FirmwareUpdateUIModel>> updateFirmware(
      List<FirmwareUpdateUIModel>? currentNodesStatus,
      Function(bool exceedMaxRetry) onCompletedCallback) async* {
    logger.i('[FIRMWARE]: Update firmware: Start');
    final benchmark = BenchMarkLogger(name: 'FirmwareUpdate');
    benchmark.start();

    logger.d('[FIRMWARE]: Saved current status records: $currentNodesStatus');

    final action = getIt.get<ServiceHelper>().isSupportNodeFirmwareUpdate()
        ? JNAPAction.nodesUpdateFirmwareNow
        : JNAPAction.updateFirmwareNow;
    await _routerRepo.send(
      action,
      data: {'onlyCheck': false},
      cacheLevel: CacheLevel.noCache,
      fetchRemote: true,
      auth: true,
    );
    yield* _startCheckFirmwareUpdateStatus(
      retryTimes: 60 * getAvailableUpdateNumber(currentNodesStatus),
      stopCondition: (result) =>
          _checkFirmwareUpdateComplete(result, currentNodesStatus ?? []),
      onCompleted: onCompletedCallback,
    );
    benchmark.end();
  }

  Future finishFirmwareUpdate() async {
    await SharedPreferences.getInstance().then((pref) {
      pref.setBool(pFWUpdated, true);
    });
  }

  bool isFailedCheckFirmwareUpdate(
      List<FirmwareUpdateUIModel>? currentNodesStatus) {
    return currentNodesStatus?.any((e) => e.lastOperationFailure != null) ??
        false;
  }
}
