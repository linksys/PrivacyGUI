// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_settings.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_state.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/bench_mark.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/core/utils/nodes.dart';

final firmwareUpdateProvider =
    NotifierProvider<FirmwareUpdateNotifier, FirmwareUpdateState>(
        () => FirmwareUpdateNotifier());

class FirmwareUpdateNotifier extends Notifier<FirmwareUpdateState> {
  static const Duration firmwareCheckPeriod = Duration(minutes: 5);

  StreamSubscription? _sub;

  @override
  FirmwareUpdateState build() {
    final fwUpdateSettingsRaw = ref.watch(pollingProvider.select<JNAPResult?>(
        (value) => value.value?.data[JNAPAction.getFirmwareUpdateSettings]));
    final fwUpdateCheckRaw = ref.watch(pollingProvider.select(
        (value) => value.value?.data[JNAPAction.getFirmwareUpdateStatus]));
    final nodesFwUpdateCheckRaw = ref.watch(pollingProvider.select(
        (value) => value.value?.data[JNAPAction.getNodesFirmwareUpdateStatus]));

    FirmwareUpdateSettings? fwUpdateSettings;
    if (fwUpdateSettingsRaw is JNAPSuccess) {
      fwUpdateSettings =
          FirmwareUpdateSettings.fromMap(fwUpdateSettingsRaw.output);
    }

    List<FirmwareUpdateStatus>? fwUpdateStatusList =
        switch (isServiceSupport(JNAPService.nodesFirmwareUpdate)) {
      true when nodesFwUpdateCheckRaw is JNAPSuccess =>
        List.from(nodesFwUpdateCheckRaw.output['firmwareUpdateStatus'])
            .map((e) => NodesFirmwareUpdateStatus.fromMap(e))
            .toList(),
      false when fwUpdateCheckRaw is JNAPSuccess => [
          FirmwareUpdateStatus.fromMap(fwUpdateCheckRaw.output)
        ],
      _ => [],
    };

    return FirmwareUpdateState(
      settings: fwUpdateSettings ??
          FirmwareUpdateSettings(
              updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
              autoUpdateWindow: FirmwareAutoUpdateWindow.simple()),
      nodesStatus: fwUpdateStatusList,
    );
  }

  Future setFirmwareUpdatePolicy(String policy) {
    final repo = ref.read(routerRepositoryProvider);
    final newSettings = state.settings.copyWith(updatePolicy: policy);
    return repo
        .send(JNAPAction.setFirmwareUpdateSettings,
            auth: true,
            cacheLevel: CacheLevel.noCache,
            data: newSettings.toMap())
        .then((_) async {
      await repo.send(JNAPAction.getFirmwareUpdateSettings,
          auth: true, fetchRemote: true);
    }).then((_) {
      state = state.copyWith(settings: newSettings);
    });
  }

  Stream<List<FirmwareUpdateStatus>> checkFirmwareUpdateStream(
      {bool force = false, int retry = 3}) async* {
    final lastCheckTime =
        (state.nodesStatus?.map((e) => e.lastSuccessfulCheckTime).toList() ??
                [])
            .map((e) => DateTime.tryParse(e))
            .map((e) => e?.millisecondsSinceEpoch ?? 0)
            .max;
    if (_checkFirmwareUpdatePeriod(lastCheckTime) && !force) {
      logger.i(
          'FIRMWARE:: Skip checking firmware update avaliable: last check time {${DateTime.fromMillisecondsSinceEpoch(lastCheckTime)}}');
      yield [];
    } else {
      final action = isServiceSupport(JNAPService.nodesFirmwareUpdate)
          ? JNAPAction.updateFirmwareNow
          : JNAPAction.nodesUpdateFirmwareNow;
      await ref
          .read(routerRepositoryProvider)
          .send(
            action,
            data: {'onlyCheck': true},
            cacheLevel: CacheLevel.noCache,
            fetchRemote: true,
            auth: true,
          )
          .then((_) {});
      yield* _startCheckFirmwareUpdateStatus(retryTimes: retry);
    }
  }

  Future checkFirmwareUpdateStatus() {
    return checkFirmwareUpdateStream(force: true, retry: 1)
        .single
        .onError((error, stackTrace) => [])
        .then((statusList) {
      state = state.copyWith(nodesStatus: statusList);
    });
  }

  Future updateFirmware() async {
    final benchmark = BenchMarkLogger(name: 'FirmwareUpdate');
    benchmark.start();
    state = state.copyWith(isUpdating: true);
    final action = isServiceSupport(JNAPService.nodesFirmwareUpdate)
        ? JNAPAction.updateFirmwareNow
        : JNAPAction.nodesUpdateFirmwareNow;
    await ref.read(routerRepositoryProvider).send(
          action,
          data: {'onlyCheck': false},
          cacheLevel: CacheLevel.noCache,
          fetchRemote: true,
          auth: true,
        );
    _sub?.cancel();
    ref.read(pollingProvider.notifier).stopPolling();
    final targetFirmwareUpdateRecords = state.nodesStatus ?? [];
    final availableCount = targetFirmwareUpdateRecords
        .where((e) => e.availableUpdate != null)
        .length;
    // check firmware update up to 480 seconds for per router
    _sub = _startCheckFirmwareUpdateStatus(
        retryTimes: 48 * availableCount,
        stopCondition: (result) =>
            _checkFirmwareUpdateComplete(result, targetFirmwareUpdateRecords),
        onCompleted: () {
          logger.i('FIRMWARE:: update firmware COMPLETED!');
          final polling = ref.read(pollingProvider.notifier);
          polling.forcePolling().then((_) {
            polling.startPolling();
            _sub?.cancel();
            state = state.copyWith(isUpdating: false);
            benchmark.end();
          });
        }).listen((statusList) {
      logger.i('FIRMWARE:: update firmware state: $statusList');
      state = state.copyWith(nodesStatus: statusList);
    });
  }

  bool _checkFirmwareUpdateComplete(
    JNAPResult result,
    List<FirmwareUpdateStatus> records,
  ) {
    if (result is JNAPSuccess) {
      final statusList =
          switch (isServiceSupport(JNAPService.nodesFirmwareUpdate)) {
        false => [FirmwareUpdateStatus.fromMap(result.output)],
        true => List.from(result.output['firmwareUpdateStatus'])
            .map((e) => NodesFirmwareUpdateStatus.fromMap(e))
            .toList()
      };

      final isSatisfied =
          !statusList.any((status) => status.pendingOperation != null);
      final isDataConsitent = _isRecordConsistent(statusList, records);
      logger.i(
          'FIRMWARE:: check are all finished: $statusList, $isSatisfied, $isDataConsitent');
      return isSatisfied && isDataConsitent;
    } else {
      logger.i('FIRMWARE:: error: $result, maybe reboot');
      return false;
    }
  }

  ///
  /// Check all nodes connect back
  ///
  @visibleForTesting
  bool isRecordConsistent(
    List<FirmwareUpdateStatus> list,
    List<FirmwareUpdateStatus> records,
  ) =>
      _isRecordConsistent(list, records);
  bool _isRecordConsistent(
    List<FirmwareUpdateStatus> list,
    List<FirmwareUpdateStatus> records,
  ) {
    checkExist(FirmwareUpdateStatus status) {
      if (status is NodesFirmwareUpdateStatus) {
        return list
            .map((e) => e as NodesFirmwareUpdateStatus)
            .map((e) => e.deviceUUID)
            .contains(status.deviceUUID);
      } else {
        return list.length == 1;
      }
    }

    return records.fold<bool>(
        true, (value, element) => value & checkExist(element));
  }

  Stream<List<FirmwareUpdateStatus>> _startCheckFirmwareUpdateStatus({
    int? retryTimes = 3,
    int? retryDelayInMilliSec,
    bool Function(JNAPResult)? stopCondition,
    Function()? onCompleted,
  }) {
    final action = isServiceSupport(JNAPService.nodesFirmwareUpdate)
        ? JNAPAction.getNodesFirmwareUpdateStatus
        : JNAPAction.getFirmwareUpdateStatus;
    return ref
        .read(routerRepositoryProvider)
        .scheduledCommand(
            action: action,
            maxRetry: retryTimes ?? -1,
            retryDelayInMilliSec: retryDelayInMilliSec ?? 10000,
            condition: stopCondition,
            onCompleted: onCompleted,
            auth: true)
        .map((result) {
      logger.i('FIRMWARE:: check firmware update status: $result');
      if (result is! JNAPSuccess) {
        throw result;
      }
      return action == JNAPAction.getNodesFirmwareUpdateStatus
          ? List.from(result.output['firmwareUpdateStatus'])
              .map((e) => NodesFirmwareUpdateStatus.fromMap(e))
              .toList()
          : [FirmwareUpdateStatus.fromMap(result.output)];
    });
  }

  bool _checkFirmwareUpdatePeriod(int lastCheckTime) {
    final period = firmwareCheckPeriod.inMilliseconds;
    return (DateTime.now().millisecondsSinceEpoch - lastCheckTime) < period;
  }
}
