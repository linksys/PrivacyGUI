import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      newState = newState.copyWith(uptimes: uptimeSeconds);
    }

    if (getEthernetPortConnections != null) {
      final lanPortConnections =
          List<String>.from(getEthernetPortConnections['lanPortConnections']);
      final wanPortConnection = getEthernetPortConnections['wanPortConnection'];
      newState = newState.copyWith(
          lanConnections: lanPortConnections, wanConnection: wanPortConnection);
    }

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
    // Update latest selected network ID in storage
    final pref = await SharedPreferences.getInstance();
    // await pref.remove(pCurrentSN);
    await pref.setString(pCurrentSN, serialNumber);
    await pref.setString(pSelectedNetworkId, networkId);
    // Update provider
    ref.read(selectedNetworkIdProvider.notifier).state = networkId;
    state = const DashboardManagerState();
  }

  Future<NodeDeviceInfo> checkDeviceInfo(String? serialNumber) async {
    final benchMark = BenchMarkLogger(name: 'checkDeviceInfo');
    benchMark.start();
    NodeDeviceInfo? nodeDeviceInfo =
        await _checkDeviceInfoFromCache(serialNumber);
    if (nodeDeviceInfo == null) {
      final routerRepository = ref.read(routerRepositoryProvider);
      final result = await routerRepository.send(
        JNAPAction.getDeviceInfo,
        fetchRemote: true,
      );
      nodeDeviceInfo = NodeDeviceInfo.fromJson(result.output);
    }
    benchMark.end();
    state = state.copyWith(deviceInfo: nodeDeviceInfo);
    return nodeDeviceInfo;
  }

  bool isHealthCheckModuleSupported(String module) {
    return state.healthCheckModules.contains(module);
  }

  Future<NodeDeviceInfo?> _checkDeviceInfoFromCache(
      String? serialNumber) async {
    if (serialNumber == null) {
      return null;
    }
    final data =
        await ref.read(linksysCacheManagerProvider).getCache(serialNumber);
    if (data == null) {
      return null;
    }
    final deviceInfoRaw = data[JNAPAction.getDeviceInfo.actionValue];
    if (deviceInfoRaw == null) {
      return null;
    }
    return NodeDeviceInfo.fromJson(
        JNAPSuccess.fromJson(deviceInfoRaw['data']).output);
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
