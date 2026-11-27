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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';

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
      isWaitingChildrenAfterUpdating: fwUpdateStatusRecord.$2,
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

  /// [logoutGeneration] is the login the check belongs to, when the check
  /// continues work begun earlier; left null, it is the current one (#1904).
  Future fetchAvailableFirmwareUpdates({int? logoutGeneration}) {
    logger.i('[FIRMWARE]: Examine if there are firmware updates available');
    final benchmark = BenchMarkLogger(name: 'FirmwareUpdate');
    benchmark.start();
    return fetchFirmwareUpdateStream(
            force: true, retry: 2, logoutGeneration: logoutGeneration)
        .last
        .then<List<FirmwareUpdateStatus>?>((resultList) => resultList)
        .onError<LoggedOutException>((error, stackTrace) => null)
        .onError((error, stackTrace) => [])
        .then((resultList) {
      benchmark.end();
      if (resultList == null) {
        // Ended by a logout: it reports no update, so no caller goes on to
        // install one after the logout, as PnP and the auto-parent first
        // login would. The state is written directly, not through
        // _examineStatusResult, whose ref.read a debug build refuses once the
        // logout's reset of polling has changed what this notifier watches.
        state = state.copyWith(
            nodesStatus: const [], isWaitingChildrenAfterUpdating: false);
        return;
      }
      // In addition to the build function, state updates here should also be examined
      final statusRecord = _examineStatusResult(resultList);
      logger.d(
          '[FIRMWARE]: Fetch available firmware updates: saved status list = $statusRecord');
      state = state.copyWith(
        nodesStatus: statusRecord.$1,
        isWaitingChildrenAfterUpdating: statusRecord.$2,
      );
    });
  }

  Stream<List<FirmwareUpdateStatus>> fetchFirmwareUpdateStream(
      {bool force = false, int retry = 3, int? logoutGeneration}) async* {
    final lastCheckTime =
        (state.nodesStatus?.map((e) => e.lastSuccessfulCheckTime).toList() ??
                    [])
                .map((e) => DateTime.tryParse(e))
                .map((e) => e?.millisecondsSinceEpoch ?? 0)
                .maxOrNull ??
            0;
    // Read as the check begins, so that a logout before its status reads, even
    // one while the first request is still out, ends them (#1904). Read after
    // `state`, which rebuilds this notifier when a poll has changed what it
    // watches: in a debug build, Riverpod refuses a `ref.read` from a notifier
    // that has not rebuilt yet.
    final auth = ref.read(authProvider.notifier);
    final generation = logoutGeneration ?? auth.logoutGeneration;
    // Read before the first await for the same reason: a poll, or a logout's
    // reset of polling, may land while the first request is out.
    final repository = ref.read(routerRepositoryProvider);
    if (!_isNeedDoFetch(lastCheckTime: lastCheckTime) && !force) {
      logger.i(
          '[FIRMWARE]: Skip checking firmware update avaliable: last check time {${DateTime.fromMillisecondsSinceEpoch(lastCheckTime)}}');
      yield [];
    } else {
      final action = serviceHelper.isSupportNodeFirmwareUpdate()
          ? JNAPAction.nodesUpdateFirmwareNow
          : JNAPAction.updateFirmwareNow;
      // A check that continues an install the user has logged out of since
      // asks nothing.
      if (auth.loggedOutSince(generation)) {
        throw const LoggedOutException();
      }
      await repository
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
          retryTimes: retry,
          onCompleted: (_) {},
          logoutGeneration: generation,
          repository: repository);
    }
  }

  /// Asks the router to install the available updates, then follows the
  /// install with status checks until the router is back on the new firmware.
  ///
  /// The firmware detail page, PnP's firmware step and the auto-parent first
  /// login tell how it went from [FirmwareUpdateState.isUpdating], so this
  /// order is part of the contract:
  /// - the access policy refuses: [ReadOnlyAccessException] is thrown before
  ///   `isUpdating` is set, so it never changes;
  /// - the router refuses: `isUpdating` turns on, then off, and the error is
  ///   rethrown;
  /// - the router accepts: this returns with `isUpdating` on. It turns off
  ///   once the install is done, or once the status checks run out, which
  ///   sets [FirmwareUpdateState.isRetryMaxReached] first.
  Future updateFirmware() async {
    logger.i('[FIRMWARE]: Update firmware: Start');
    final action = serviceHelper.isSupportNodeFirmwareUpdate()
        ? JNAPAction.nodesUpdateFirmwareNow
        : JNAPAction.updateFirmwareNow;
    // Checked before `isUpdating` is set, so a refused write never shows the
    // page its updating spinner.
    enforceAccess(ref, (policy) => policy.checkWrite(action));
    // The install is followed for as long as this login lasts (#1904).
    final logoutGeneration = ref.read(authProvider.notifier).logoutGeneration;
    final benchmark = BenchMarkLogger(name: 'FirmwareUpdate');
    benchmark.start();
    state = state.copyWith(isUpdating: true);
    // Save the current status list and their corresponding node objects
    // Note: Before the update process, the nodes should not be null
    final candidates = ref.read(firmwareUpdateCandidateProvider);
    final statusRecords = getIDStatusRecords();
    ref.read(firmwareUpdateCandidateProvider.notifier).state = statusRecords;
    logger.d('[FIRMWARE]: Saved current status records: $statusRecords');

    try {
      await ref.read(routerRepositoryProvider).send(
            action,
            data: {'onlyCheck': false},
            cacheLevel: CacheLevel.noCache,
            fetchRemote: true,
            auth: true,
          );
    } catch (error) {
      // The router never started the install, so no status check will end it:
      // put the page back as it was before the update was asked for.
      logger.e('[FIRMWARE]: Update firmware: refused: $error');
      ref.read(firmwareUpdateCandidateProvider.notifier).state = candidates;
      state = state.copyWith(isUpdating: false);
      rethrow;
    }
    _sub?.cancel();
    ref.read(pollingProvider.notifier).stopPolling();
    _sub = _startCheckFirmwareUpdateStatus(
      logoutGeneration: logoutGeneration,
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
          finishFirmwareUpdate(logoutGeneration: logoutGeneration).then((_) {
            _sub?.cancel();
            benchmark.end();
          });
        }
      },
    ).listen(
      (statusList) {
        // The updated list here will be continuously rendered on different screens
        // No need to examine the node status number
        state = state.copyWith(nodesStatus: statusList);
      },
      // A status read fails while the router restarts into the new firmware.
      // The stop condition has already logged it and the checks go on, so it
      // is not an error of the update. Anything else, such as a status that
      // does not parse, is logged here, as nothing else logs it.
      onError: (Object error, StackTrace stackTrace) {
        if (error is JNAPError) return;
        if (error is LoggedOutException) {
          // The router goes on installing, but nothing here follows it any
          // more, so nothing else would ever turn the spinner off. The nodes
          // the install saved are not put back, as a refused install's are:
          // the logout has cleared them.
          logger.i('[FIRMWARE]: Update firmware: no longer followed, '
              'logged out');
          state = state.copyWith(isUpdating: false);
          benchmark.end();
          return;
        }
        logger.e('[FIRMWARE]: Update firmware: status check failed',
            error: error, stackTrace: stackTrace);
      },
    );
  }

  /// [logoutGeneration] is the login of the install this finishes; left null,
  /// it is the current one, as for [fetchAvailableFirmwareUpdates]. Once a
  /// logout has ended it, nothing more is asked of the router and polling is
  /// not started on the login screen (#1904). The install itself is done, so
  /// it is recorded as such either way.
  Future finishFirmwareUpdate({int? logoutGeneration}) {
    // Read now: the forced poll below changes what this notifier watches, and
    // a debug build refuses a `ref.read` from it until it has rebuilt.
    final auth = ref.read(authProvider.notifier);
    final generation = logoutGeneration ?? auth.logoutGeneration;
    bool loggedOut() => auth.loggedOutSince(generation);
    void recordDone() => SharedPreferences.getInstance().then((pref) {
          pref.setBool(pFWUpdated, true);
        });
    final polling = ref.read(pollingProvider.notifier);
    if (loggedOut()) {
      state = state.copyWith(isUpdating: false);
      recordDone();
      return Future.value();
    }
    return polling
        .forcePolling()
        .then((_) => loggedOut()
            ? null
            : fetchAvailableFirmwareUpdates(logoutGeneration: generation))
        .then((_) {
      state = state.copyWith(isUpdating: false);
      recordDone();

      if (loggedOut()) return;
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
  List<(LinksysDevice?, FirmwareUpdateStatus)> getIDStatusRecords() {
    return (state.nodesStatus ?? []).map((nodeStatus) {
      final nodes = ref.read(deviceManagerProvider).nodeDevices;
      LinksysDevice? node;
      try {
        node = nodeStatus is NodesFirmwareUpdateStatus
            ? nodes.firstWhere((node) => node.deviceID == nodeStatus.deviceUUID)
            : ref.read(deviceManagerProvider).masterDevice;
      } catch (error) {
        // If the node is not found, use null to indicate that the node is not found
        // Note: This may happen in Pinnacle's CF production firmware
        logger.e('[FIRMWARE]: Error finding corresponding node: $error');
        node = null;
      }
      return (node, nodeStatus);
    }).toList();
  }

  int getAvailableUpdateNumber() {
    return (state.nodesStatus ?? [])
        .where((e) => e.availableUpdate != null)
        .length;
  }

  bool isFailedCheckFirmwareUpdate() {
    return state.nodesStatus?.any((e) => e.lastOperationFailure != null) ??
        false;
  }

  (List<FirmwareUpdateStatus>, bool) _examineStatusResult(
      List<FirmwareUpdateStatus> resultList) {
    // After fw updating and router restarting, the child nodes will be offline for a while
    // During this period, the polling will only obtain the status of the master node
    // In order to maintain the integrity of the list on the page, the status list should not be overwritten in state
    final cachedCandidates = ref.read(firmwareUpdateCandidateProvider);
    if (cachedCandidates != null) {
      // Get the list of status objects from the cached candidates
      final cachedList = cachedCandidates.map((e) => e.$2).toList();
      if (_isRecordConsistent(resultList, cachedList)) {
        logger.d('[FIRMWARE]: Fetched status is correct - nodes have resumed');
        return (resultList, false);
      } else {
        logger.d('[FIRMWARE]: Fetched status mismatch! - show the cached list');
        // These cached nodes used to temporarily display nodes after updating
        // need to clear availableUpdate to indicate that these nodes have been updated
        final updatedCachedList = cachedList.map((e) {
          return e.copyWith(availableUpdate: () => null);
        }).toList();
        return (updatedCachedList, true);
      }
    }
    // Initial state - no updates in progress
    logger.d('[FIRMWARE]: No cached node status list');
    return (resultList, false);
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
    required int logoutGeneration,
    RouterRepository? repository,
  }) {
    final action = serviceHelper.isSupportNodeFirmwareUpdate()
        ? JNAPAction.getNodesFirmwareUpdateStatus
        : JNAPAction.getFirmwareUpdateStatus;
    final RouterRepository repo =
        repository ?? ref.read(routerRepositoryProvider);
    return repo
        .scheduledCommand(
      action: action,
      maxRetry: retryTimes ?? -1,
      retryDelayInMilliSec: retryDelayInMilliSec ?? 2000,
      condition: stopCondition,
      onCompleted: onCompleted,
      requestTimeoutOverride: 3000,
      auth: true,
      logoutGeneration: logoutGeneration,
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
    // The upload goes to the router's local address, not through
    // RouterRepository, so its gate never sees this write.
    enforceAccess(
        ref, (policy) => policy.checkWrite(JNAPAction.updateFirmwareNow));
    final client = LinksysHttpClient()
      ..timeoutMs = 300000
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
    StateProvider<List<(LinksysDevice?, FirmwareUpdateStatus)>?>((ref) {
  return null;
});
