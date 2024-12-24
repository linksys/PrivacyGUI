import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/core/jnap/providers/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/jnap/providers/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/ip_getter/web_get_local_ip.dart';
import 'package:privacy_gui/utils.dart';

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

    List<FirmwareUpdateStatus>? resultStatusList =
        switch (serviceHelper.isSupportNodeFirmwareUpdate()) {
      true when nodesFwUpdateCheckRaw is JNAPSuccess =>
        List.from(nodesFwUpdateCheckRaw.output['firmwareUpdateStatus'])
            .map((e) => NodesFirmwareUpdateStatus.fromMap(e))
            .toList(),
      false when fwUpdateCheckRaw is JNAPSuccess => [
          FirmwareUpdateStatus.fromMap(fwUpdateCheckRaw.output)
        ],
      _ => [],
    };
    final fwUpdateStatusRecord = _examineStatusResult(resultStatusList);

    final state = FirmwareUpdateState(
      settings: fwUpdateSettings ??
          FirmwareUpdateSettings(
            updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
            autoUpdateWindow: FirmwareAutoUpdateWindow.simple(),
          ),
      nodesStatus: fwUpdateStatusRecord.$1,
      isChildAllUp: fwUpdateStatusRecord.$2,
    );
    logger.d('[FIRMWARE]: Build: state = ${state.toJson()}');
    return state;
  }

  Future setFirmwareUpdatePolicy(String policy) {
    final repo = ref.read(routerRepositoryProvider);
    final newSettings = state.settings.copyWith(updatePolicy: policy);
    return repo
        .send(
      JNAPAction.setFirmwareUpdateSettings,
      auth: true,
      cacheLevel: CacheLevel.noCache,
      data: newSettings.toMap(),
    )
        .then((_) async {
      await repo.send(
        JNAPAction.getFirmwareUpdateSettings,
        auth: true,
        fetchRemote: true,
      );
    }).then((_) {
      state = state.copyWith(settings: newSettings);
    });
  }

  Future fetchAvailableFirmwareUpdates() {
    logger.i('[FIRMWARE]: Examine if there are firmware updates available');
    return fetchFirmwareUpdateStream(force: true, retry: 1)
        .single
        .onError((error, stackTrace) => [])
        .then((resultList) {
      // In addition to the build function, state updates here should also be examined
      final statusRecord = _examineStatusResult(resultList);
      logger.d(
          '[FIRMWARE]: Fetch available firmware updates: saved status list = $statusRecord');
      state = state.copyWith(
        nodesStatus: statusRecord.$1,
        isChildAllUp: statusRecord.$2,
      );
    });
  }

  Stream<List<FirmwareUpdateStatus>> fetchFirmwareUpdateStream(
      {bool force = false, int retry = 3}) async* {
    final lastCheckTime =
        (state.nodesStatus?.map((e) => e.lastSuccessfulCheckTime).toList() ??
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
      final action = serviceHelper.isSupportNodeFirmwareUpdate()
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
      yield* _startCheckFirmwareUpdateStatus(
          retryTimes: retry, onCompleted: (_) {});
    }
  }

  Future updateFirmware() async {
    logger.i('[FIRMWARE]: Update firmware: Start');
    final benchmark = BenchMarkLogger(name: 'FirmwareUpdate');
    benchmark.start();
    state = state.copyWith(isUpdating: true);
    logger.d('[FIRMWARE]: Save the current status list: ${state.nodesStatus}');
    // Save the current status list
    ref.read(firmwareUpdateCandidateProvider.notifier).state =
        state.nodesStatus;
    final action = serviceHelper.isSupportNodeFirmwareUpdate()
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
    _sub = _startCheckFirmwareUpdateStatus(
      retryTimes: 60 * getAvailableUpdateNumber(),
      stopCondition: (result) =>
          _checkFirmwareUpdateComplete(result, state.nodesStatus ?? []),
      onCompleted: (bool exceedMaxRetry) {
        state = state.copyWith(isRetryMaxReached: exceedMaxRetry);
        if (exceedMaxRetry) {
          logger.e(
              '[FIRMWARE]: Firmware update halts due to exceeding the maximum retry limit');
          // If the client does not reconnect to the router, the requests will continue to fail up to the maximum limit
          // Update ended with exception
          state = state.copyWith(isUpdating: false);
          _sub?.cancel();
          benchmark.end();
        } else {
          logger.i('[FIRMWARE]: Firmware update: Done!');
          finishFirmwareUpdate().then((_) {
            _sub?.cancel();
            benchmark.end();
          });
        }
      },
    ).listen((statusList) {
      // The updated list here will be continuously rendered on different screens
      // No need to examine the node status number
      state = state.copyWith(nodesStatus: statusList);
    });
  }

  Future finishFirmwareUpdate() {
    final polling = ref.read(pollingProvider.notifier);
    return polling
        .forcePolling()
        .then((_) => fetchAvailableFirmwareUpdates())
        .then((_) {
      state = state.copyWith(isUpdating: false);
      polling.startPolling();
    });
  }

  bool _checkFirmwareUpdateComplete(
    JNAPResult result,
    List<FirmwareUpdateStatus> records,
  ) {
    if (result is JNAPSuccess) {
      final statusList = switch (serviceHelper.isSupportNodeFirmwareUpdate()) {
        false => [FirmwareUpdateStatus.fromMap(result.output)],
        true => List.from(result.output['firmwareUpdateStatus'])
            .map((e) => NodesFirmwareUpdateStatus.fromMap(e))
            .toList()
      };

      final isDone =
          !statusList.any((status) => status.pendingOperation != null);
      logger.i('[FIRMWARE]: Check if all updates are finished: $isDone');
      return isDone;
    } else {
      logger.e('[FIRMWARE]: Error: $result - Maybe rebooting');
      return false;
    }
  }

  // Get records of nodes' update status and their device IDs
  List<(LinksysDevice, FirmwareUpdateStatus)> getIDStatusRecords() {
    return (state.nodesStatus ?? []).map((nodeStatus) {
      final nodes = ref.read(deviceManagerProvider).nodeDevices;
      return (
        nodeStatus is NodesFirmwareUpdateStatus
            ? nodes.firstWhere((node) => node.deviceID == nodeStatus.deviceUUID)
            : ref.read(deviceManagerProvider).masterDevice,
        nodeStatus
      );
    }).toList();
  }

  int getAvailableUpdateNumber() {
    return (state.nodesStatus ?? [])
        .where((e) => e.availableUpdate != null)
        .length;
  }

  (List<FirmwareUpdateStatus>, bool) _examineStatusResult(
      List<FirmwareUpdateStatus> resultList) {
    // After fw updating and router restarting, the child nodes will be offline for a while
    // During this period, the polling will only obtain the status of the master node
    // In order to maintain the integrity of the list on the page, the status list should not be overwritten in state
    final cachedList = ref.read(firmwareUpdateCandidateProvider);
    if (cachedList != null) {
      if (_isRecordConsistent(resultList, cachedList)) {
        logger.d('[FIRMWARE]: Fetched status is correct - nodes have resumed');
        return (resultList, true);
      } else {
        logger.d('[FIRMWARE]: Fetched status mismatch! - show the cached list');
        return (cachedList, false);
      }
    }
    // Initial state - no updates in progress
    logger.d('[FIRMWARE]: No cached node status list');
    return (resultList, true);
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
    int? retryTimes = 1,
    int? retryDelayInMilliSec,
    bool Function(JNAPResult)? stopCondition,
    Function(bool exceedMaxRetry)? onCompleted,
  }) {
    final action = serviceHelper.isSupportNodeFirmwareUpdate()
        ? JNAPAction.getNodesFirmwareUpdateStatus
        : JNAPAction.getFirmwareUpdateStatus;
    return ref
        .read(routerRepositoryProvider)
        .scheduledCommand(
          action: action,
          maxRetry: retryTimes ?? -1,
          retryDelayInMilliSec: retryDelayInMilliSec ?? 3000,
          condition: stopCondition,
          onCompleted: onCompleted,
          requestTimeoutOverride: 3000,
          auth: true,
        )
        .map((result) {
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

  bool _isNeedDoFetch({required int lastCheckTime}) {
    final period = firmwareCheckPeriod.inMilliseconds;
    return (DateTime.now().millisecondsSinceEpoch - lastCheckTime) >= period;
  }

  Future<bool> manualFirmwareUpdate(String filename, List<int> bytes) async {
    final client = LinksysHttpClient()
      ..timeoutMs = 60000
      ..retries = 0;
    final localPwd = ref.read(authProvider).value?.localPassword ??
        await const FlutterSecureStorage().read(key: pLocalPassword) ??
        '';
    final multiPart = MultipartFile.fromBytes(
      'upload',
      bytes,
      filename: filename,
      contentType: MediaType('application', 'octet-stream'),
    );
    final log = BenchMarkLogger(name: 'Manual FW update');
    log.start();
    await ref.read(pollingProvider.notifier).stopPolling();
    return client.upload(Uri.parse('https://${getLocalIp(ref)}/jcgi/'), [
      multiPart,
    ], fields: {
      kJNAPAction: 'updatefirmware',
      kJNAPAuthorization: 'Basic ${Utils.stringBase64Encode('admin:$localPwd')}'
    }).then((response) {
      final result = jsonDecode(response.body)['result'];
      log.end();
      if (result == 'OK') {
        return true;
      }
      // error
      final error = response.headers['X-Jcgi-Result'];
      throw ManualFirmwareUpdateException(error);
    }).onError((error, stackTrace) {
      log.end();
      if (error is ErrorResponse && error.code == '500') {
        return true;
      }
      logger.e('[FIRMWARE]: Manual firmware update: Error: $error');
      throw ManualFirmwareUpdateException('UnknownError');
    });
  }

  Future waitForRouterBackOnline() {
    return ref
        .read(sideEffectProvider.notifier)
        .manualDeviceRestart()
        .whenComplete(() {
      ref.read(pollingProvider.notifier).startPolling();
    });
  }
}

class ManualFirmwareUpdateException implements Exception {
  final String? result;
  ManualFirmwareUpdateException(this.result);
}

// This provider is used to save the original list of all nodes and their fw status
// when the firmware update right started
final firmwareUpdateCandidateProvider =
    StateProvider<List<FirmwareUpdateStatus>?>((ref) {
  return null;
});
