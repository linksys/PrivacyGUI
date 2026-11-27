import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/soft_sku_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/providers/global_model_number_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dashboardManagerProvider =
    NotifierProvider<DashboardManagerNotifier, DashboardManagerState>(
  () => DashboardManagerNotifier(),
);

class DashboardManagerNotifier extends Notifier<DashboardManagerState> {
  @override
  DashboardManagerState build() {
    final coreTransactionData = ref.watch(pollingProvider).value;
    return createState(pollingResult: coreTransactionData);
  }

  DashboardManagerState createState({CoreTransactionData? pollingResult}) {
    Map<String, dynamic>? getDeviceInfoData;
    Map<String, dynamic>? getRadioInfoData;
    Map<String, dynamic>? getGuestRadioSettingsData;
    Map<String, dynamic>? getHealthCheckResultsData;
    Map<String, dynamic>? getHealthCheckModuleData;
    Map<String, dynamic>? getSystemStats;
    Map<String, dynamic>? getEthernetPortConnections;
    Map<String, dynamic>? getLocalTime;

    final result = pollingResult?.data;
    if (result != null) {
      getDeviceInfoData =
          (result[JNAPAction.getDeviceInfo] as JNAPSuccess?)?.output;
      getRadioInfoData =
          (result[JNAPAction.getRadioInfo] as JNAPSuccess?)?.output;
      getGuestRadioSettingsData =
          (result[JNAPAction.getGuestRadioSettings] as JNAPSuccess?)?.output;
      getHealthCheckResultsData =
          (result[JNAPAction.getHealthCheckResults] as JNAPSuccess?)?.output;
      getHealthCheckModuleData =
          (result[JNAPAction.getSupportedHealthCheckModules] as JNAPSuccess?)
              ?.output;
      getSystemStats =
          (result[JNAPAction.getSystemStats] as JNAPSuccess?)?.output;
      getEthernetPortConnections =
          (result[JNAPAction.getEthernetPortConnections] as JNAPSuccess?)
              ?.output;
      getLocalTime = (result[JNAPAction.getLocalTime] as JNAPSuccess?)?.output;
    }

    var newState = const DashboardManagerState();
    if (getDeviceInfoData != null) {
      newState = newState.copyWith(
          deviceInfo: NodeDeviceInfo.fromJson(getDeviceInfoData));
    }
    if (getRadioInfoData != null) {
      newState = _getMainRadioList(newState, getRadioInfoData);
    }
    if (getGuestRadioSettingsData != null) {
      newState = _getGuestRadioList(newState, getGuestRadioSettingsData);
    }
    if (getHealthCheckResultsData != null) {
      newState = _getSpeedTestResult(newState, getHealthCheckResultsData);
    }

    if (getHealthCheckModuleData != null) {
      newState =
          _getHealthCheckModuleResult(newState, getHealthCheckModuleData);
    }

    if (getSystemStats != null) {
      final uptimeSeconds = getSystemStats['uptimeSeconds'];
      final cpuLoad = getSystemStats['CPULoad'];
      final memoryLoad = getSystemStats['MemoryLoad'];
      newState = newState.copyWith(
        uptimes: uptimeSeconds,
        cpuLoad: cpuLoad,
        memoryLoad: memoryLoad,
      );
    }

    if (getEthernetPortConnections != null) {
      final lanPortConnections =
          List<String>.from(getEthernetPortConnections['lanPortConnections']);
      final wanPortConnection = getEthernetPortConnections['wanPortConnection'];
      newState = newState.copyWith(
          lanConnections: lanPortConnections, wanConnection: wanPortConnection);
    }

    String? timeString;
    if (getLocalTime != null) {
      timeString = getLocalTime['currentTime'];
    }

    final localTime = (timeString != null
            ? DateFormat("yyyy-MM-ddTHH:mm:ssZ").tryParse(timeString)
            : DateTime.now())
        ?.millisecondsSinceEpoch;
    newState = newState.copyWith(localTime: localTime);

    final softSKUSettings = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getSoftSKUSettings, result ?? {});
    if (softSKUSettings != null) {
      final settings = SoftSKUSettings.fromMap(softSKUSettings.output);
      newState = newState.copyWith(skuModelNumber: settings.modelNumber);
    }

    return newState;
  }

  Future<void> saveSelectedNetwork(
      String serialNumber, String networkId) async {
    logger.i('[Prepare]: saveSelectedNetwork - $networkId, $serialNumber');
    // Update latest selected network ID in storage
    final pref = await SharedPreferences.getInstance();
    // await pref.remove(pCurrentSN);
    logger.d('[Prepare]: save selected network - $serialNumber, $networkId');
    await pref.setString(pCurrentSN, serialNumber);
    await pref.setString(pSelectedNetworkId, networkId);
    // Update provider
    ref.read(selectedNetworkIdProvider.notifier).state = networkId;
    state = const DashboardManagerState();
  }

  Future<NodeDeviceInfo> checkRouterIsBack() async {
    NodeDeviceInfo? nodeDeviceInfo;
    final routerRepository = ref.read(routerRepositoryProvider);
    final result = await routerRepository.send(
      JNAPAction.getDeviceInfo,
      fetchRemote: true,
      retries: 0,
    );
    nodeDeviceInfo = NodeDeviceInfo.fromJson(result.output);
    final prefs = await SharedPreferences.getInstance();
    final currentSN =
        prefs.getString(pCurrentSN) ?? prefs.getString(pPnpConfiguredSN);
    if (currentSN == nodeDeviceInfo.serialNumber) {
      return nodeDeviceInfo;
    } else {
      logger.d('[CheckRouterBack]: SN not match');
      throw Exception('[CheckRouterBack]: SN not match');
    }
  }

  /// Reads this router's device info, from the dashboard state when it has
  /// it, and builds the action table for the services it reports (#1923).
  /// This is where a logged-in flow builds the table, and the gates read the
  /// same services. PnP builds its own, in `fetchDeviceInfo`
  /// (pnp_provider.dart).
  Future<NodeDeviceInfo> checkDeviceInfo() async {
    final benchMark = BenchMarkLogger(name: 'checkDeviceInfo');
    benchMark.start();
    NodeDeviceInfo? nodeDeviceInfo = state.deviceInfo;
    if (nodeDeviceInfo == null) {
      final isRemote =
          ref.read(authProvider).value?.loginType == LoginType.remote;
      final routerRepository = ref.read(routerRepositoryProvider);
      final result = await routerRepository.send(
        JNAPAction.getDeviceInfo,
        retries: isRemote ? 1 : 0,
        timeoutMs: isRemote ? 10000 : 3000,
      );
      nodeDeviceInfo = NodeDeviceInfo.fromJson(result.output);
    }
    benchMark.end();
    // state = state.copyWith(deviceInfo: nodeDeviceInfo);
    buildBetterActions(nodeDeviceInfo.services);
    return nodeDeviceInfo;
  }

  /// Budget for riding out a router service restart while a session starts.
  /// Deliberately short: a genuinely missing device must still fail fast, and
  /// the router's redirect, which the user is waiting on, runs this.
  static const int _deviceInfoMaxRetries = 2;
  static const Duration _deviceInfoRetryDelay = Duration(seconds: 2);

  /// The one sequence that starts a session on the router the app reaches
  /// (#1904). The router's redirect runs it for a local or a remote login, as
  /// the app opens and on every later page change. PrepareDashboardView runs
  /// it once PnP has logged in.
  ///
  /// 1. A local login finds out which router the app reaches. When polling
  ///    already knows the stored one, nothing is asked. A router other than
  ///    the stored one, or the first one, is saved as the selected network. A
  ///    remote login's router is the one its Guardian session names, which
  ///    the redirect has saved already.
  /// 2. The device cache of that router is loaded.
  /// 3. Its device info is read ([checkDeviceInfo]), again while the router
  ///    is briefly unreachable, and its model number is shown.
  /// 4. Polling is asked to start: forced when the router changed, or when
  ///    [forcePolling] says the caller held it, as PnP does.
  ///
  /// Returns the device info, or null when the router gives none.
  Future<NodeDeviceInfo?> startSession({bool forcePolling = false}) async {
    await ref.read(connectivityProvider.notifier).forceUpdate();
    final prefs = await SharedPreferences.getInstance();
    final storedSerial = prefs.getString(pCurrentSN);
    var serialNumber = storedSerial;
    final loginType = ref.read(authProvider).value?.loginType;
    final known =
        storedSerial != null && storedSerial == state.deviceInfo?.serialNumber;
    if (loginType == LoginType.local && !known) {
      logger.i('[Prepare]: local - $storedSerial');
      final reached = await ref
          .read(routerRepositoryProvider)
          .send(JNAPAction.getDeviceInfo, fetchRemote: true)
          .then<String>(
              (value) => NodeDeviceInfo.fromJson(value.output).serialNumber);
      if (reached != storedSerial) {
        await saveSelectedNetwork(reached, '');
      }
      serialNumber = reached;
    }
    logger.d('[Prepare]: cache check - $serialNumber');
    await ref
        .read(linksysCacheManagerProvider)
        .loadCache(serialNumber: serialNumber ?? '');
    final nodeDeviceInfo = await _checkDeviceInfoWithRetry();
    if (nodeDeviceInfo == null) {
      return null;
    }
    ref.read(globalModelNumberProvider.notifier).state =
        nodeDeviceInfo.modelNumber;
    await ref.read(connectivityProvider.notifier).forceUpdate();
    ref.read(pollingProvider.notifier).checkAndStartPolling(
        forcePolling || nodeDeviceInfo.serialNumber != storedSerial);
    return nodeDeviceInfo;
  }

  /// Reads the device info, retrying only while the failure looks like the
  /// router being temporarily unreachable rather than genuinely absent.
  ///
  /// The router drops its HTTP service while it restarts services - the
  /// make-Master credential rotation is one such window - and the local
  /// deviceInfo call is issued with `retries: 0` / `timeoutMs: 3000`, so that
  /// window is guaranteed to surface as a socket/timeout failure. Treating it
  /// as "no device info" sends the user to the login page with an error they
  /// can do nothing about, when waiting a couple of seconds would have worked.
  ///
  /// Any other failure (JNAP error, unparsable payload) is final: return null
  /// and let the caller show the error.
  Future<NodeDeviceInfo?> _checkDeviceInfoWithRetry() async {
    for (var attempt = 0;; attempt++) {
      try {
        return await checkDeviceInfo();
      } catch (error) {
        if (!_isRouterTemporarilyUnreachable(error) ||
            attempt >= _deviceInfoMaxRetries) {
          logger.e('[Prepare]: device info check failed - $error');
          return null;
        }
        logger.i(
            '[Prepare]: router temporarily unreachable ($error), retry ${attempt + 1}/$_deviceInfoMaxRetries');
        await Future.delayed(_deviceInfoRetryDelay);
      }
    }
  }

  /// Connection-class failures, i.e. the request never reached a router that
  /// could answer it. Mirrors the transient-error test in `PnpNotifier`.
  bool _isRouterTemporarilyUnreachable(Object? error) =>
      error is ClientException || error is TimeoutException;

  bool isHealthCheckModuleSupported(String module) {
    return state.healthCheckModules.contains(module);
  }

  // DashboardManagerState _getAvailableDeviceServices(
  //   DashboardManagerState state,
  //   Map<String, dynamic> data,
  // ) {
  //   final nodeDeviceInfo = NodeDeviceInfo.fromJson(data);
  //   final services = nodeDeviceInfo.services;
  //   // Build/Update better actions
  //   buildBetterActions(services);
  //   return state.copyWith(
  //     serialNumber: nodeDeviceInfo.serialNumber,
  //     deviceServices: services,
  //   );
  // }

  DashboardManagerState _getMainRadioList(
    DashboardManagerState state,
    Map<String, dynamic> data,
  ) {
    final getRadioInfoData = GetRadioInfo.fromMap(data);
    return state.copyWith(
      mainRadios: getRadioInfoData.radios,
    );
  }

  DashboardManagerState _getGuestRadioList(
    DashboardManagerState state,
    Map<String, dynamic> data,
  ) {
    final guestRadioSettings = GuestRadioSettings.fromMap(data);
    return state.copyWith(
      guestRadios: guestRadioSettings.radios,
      isGuestNetworkEnabled: guestRadioSettings.isGuestNetworkEnabled,
    );
  }

  DashboardManagerState _getSpeedTestResult(
    DashboardManagerState state,
    Map<String, dynamic> data,
  ) {
    final List<dynamic> healthCheckResults = List.from(
      data['healthCheckResults'],
    );
    final historyResults = healthCheckResults
        .map((result) => HealthCheckResult.fromJson(result))
        .toList();
    historyResults.sort((r1, r2) => r2.timestamp.compareTo(r1.timestamp));
    return state.copyWith(
      latestSpeedTest: historyResults.firstOrNull,
    );
  }

  DashboardManagerState _getHealthCheckModuleResult(
    DashboardManagerState state,
    Map<String, dynamic> data,
  ) {
    final supportedModules =
        List<String>.from(data['supportedHealthCheckModules']);
    return state.copyWith(healthCheckModules: supportedModules);
  }
}

final selectedNetworkIdProvider = StateProvider<String?>((ref) {
  return null;
});
