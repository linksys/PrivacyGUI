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
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
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
          '[FIRMWARE]: Skip checking firmware update avaliable: last check time {${DateTime.fromMillisecondsSinceEpoch(lastCheckTime)}}');
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
    logger.i('[FIRMWARE]: update firmware START!');
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
    _sub = _startCheckFirmwareUpdateStatus(
      retryTimes: 180 * getAvailableUpdateNumber(),
      stopCondition: (result) =>
          _checkFirmwareUpdateComplete(result, state.nodesStatus ?? []),
      onCompleted: () {
        logger.i('[FIRMWARE]: update firmware COMPLETED!');
        final polling = ref.read(pollingProvider.notifier);
        polling
            .forcePolling()
            .then((_) => checkFirmwareUpdateStatus())
            .then((_) {
          state = state.copyWith(isUpdating: false);
          polling.startPolling();
          _sub?.cancel();
          benchmark.end();
        });
      },
    ).listen((statusList) {
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
          '[FIRMWARE]: check if updates are all finished: $statusList, $isSatisfied, $isDataConsitent');
      return isSatisfied && isDataConsitent;
    } else {
      logger.i('[FIRMWARE]: error: $result, maybe reboot');
      return false;
    }
  }

  int getAvailableUpdateNumber() {
    return (state.nodesStatus ?? [])
        .where((e) => e.availableUpdate != null)
        .length;
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
            retryDelayInMilliSec: retryDelayInMilliSec ?? 3000,
            condition: stopCondition,
            onCompleted: onCompleted,
            auth: true)
        .map((result) {
      logger.i('[FIRMWARE]: check firmware update status: $result');
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

  Future<bool> manualFirmwareUpdate(String filename, List<int> bytes) async {
    final client = LinksysHttpClient();
    final localPwd = ref.read(authProvider).value?.localPassword ??
        await const FlutterSecureStorage().read(key: pLocalPassword) ??
        '';
    final multiPart = MultipartFile.fromBytes(
      'upload',
      bytes,
      filename: filename,
      contentType: MediaType('application', 'octet-stream'),
    );
    return client
        .upload(Uri.parse('https://${getLocalIp(ref)}/jcgi/'), [
          // MultipartFile.fromBytes(kJNAPAction, 'updatefirmware'.codeUnits),
          // MultipartFile.fromBytes(kJNAPAuthorization,
          //     'Basic ${Utils.stringBase64Encode('admin:$localPwd')}'.codeUnits),
          multiPart,
        ], fields: {
          kJNAPAction: 'updatefirmware',
          kJNAPAuthorization:
              'Basic ${Utils.stringBase64Encode('admin:$localPwd')}'
        })
        .then((response) =>
            response.statusCode == 200 &&
            jsonDecode(response.body)['result'] == 'OK')
        .onError((error, stackTrace) {
          logger.d('Manual Firmware update error: $error');
          return false;
        });
  }
}
