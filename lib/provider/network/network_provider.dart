import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/device_info.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';
import 'package:linksys_app/core/jnap/models/health_check_result.dart';
import 'package:linksys_app/core/jnap/models/iot_network_settings.dart';
import 'package:linksys_app/core/jnap/models/network.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/repository/router/extensions/core_extension.dart';
import 'package:linksys_app/main.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:shared_preferences/shared_preferences.dart';

final networkProvider =
    NotifierProvider<NetworkNotifier, NetworkState>(() => NetworkNotifier());

class NetworkNotifier extends Notifier<NetworkState> {
  NetworkNotifier() {
    container.listen(pollingProvider, (previous, next) {
      next.whenData((value) => pollingData(value.data));
    });
  }

  @override
  NetworkState build() => const NetworkState();

  Future selectNetwork(CloudNetworkModel network) async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(pCurrentSN);
    await pref.setString(pSelectedNetworkId, network.network.networkId);
    state =
        state.copyWith(selected: MoabNetwork(id: network.network.networkId));
  }

  Future<void> createAdminPassword(String password, String hint) async {
    final repo = ref.read(routerRepositoryProvider);
    await repo.createAdminPassword('admin', hint);
  }

  HealthCheckResult getLatestHealthCheckResult(
      List<HealthCheckResult> healthCheckResults) {
    healthCheckResults.sort((e1, e2) => e2.timestamp.compareTo(e1.timestamp));
    return healthCheckResults.first;
  }

  Future<RouterDeviceInfo> getDeviceInfo() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(JNAPAction.getDeviceInfo);
    final routerDeviceInfo = RouterDeviceInfo.fromJson(result.output);
    _handleDeviceInfoResult(routerDeviceInfo);
    return routerDeviceInfo;
  }

  Future<void> runHealthCheck() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(JNAPAction.runHealthCheck);
    if (result.output['resultID'] != null) {
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        final speedTestResult = await getHealthCheckStatus();
        if (speedTestResult.exitCode != 'Unavailable') {
          final selected = state.selected!;
          MoabNetwork selectedCopy = MoabNetwork(
              id: selected.id,
              deviceInfo: selected.deviceInfo,
              wanStatus: selected.wanStatus,
              radioInfo: selected.radioInfo,
              devices: selected.devices,
              healthCheckResults: selected.healthCheckResults,
              currentSpeedTestStatus: null);
          state = state.copyWith(selected: selectedCopy);
          getHealthCheckResults();
          timer.cancel();
        }
      });
    }
  }

  Future<void> getHealthCheckResults() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(JNAPAction.getHealthCheckResults);
    final healthCheckResults = List.from(result.output['healthCheckResults'])
        .map((e) => HealthCheckResult.fromJson(e))
        .toList();
    _handleHealthCheckResults(healthCheckResults);
  }

  Future<SpeedTestResult> getHealthCheckStatus() async {
    final repo = ref.read(routerRepositoryProvider);
    SpeedTestResult speedTestResult =
        const SpeedTestResult(resultID: 0, exitCode: '');
    final result = await repo.send(JNAPAction.getHealthCheckStatus);
    if (result.output['healthCheckModuleCurrentlyRunning'] == 'SpeedTest') {
      speedTestResult =
          SpeedTestResult.fromJson(result.output['speedTestResult']);
      state = state.copyWith(
          selected: state.selected!
              .copyWith(currentSpeedTestStatus: speedTestResult));
    }
    return speedTestResult;
  }

  void logout() {
    state = const NetworkState();
  }

  ///
  /// PollingData
  ///

  Future pollingData(Map<JNAPAction, JNAPResult> result) async {
    if (result.containsKey(JNAPAction.getDeviceInfo)) {
      final output = (result[JNAPAction.getDeviceInfo] as JNAPSuccess).output;
      final routerDeviceInfo = RouterDeviceInfo.fromJson(output);
      _handleDeviceInfoResult(routerDeviceInfo);
    }
    if (result.containsKey(JNAPAction.getWANStatus)) {
      final output = (result[JNAPAction.getWANStatus] as JNAPSuccess).output;
      final wanStatus = RouterWANStatus.fromJson(output);
      _handleWANStatusResult(wanStatus);
    }
    if (result.containsKey(JNAPAction.getRadioInfo)) {
      final output = (result[JNAPAction.getRadioInfo] as JNAPSuccess).output;
      final radioInfo = List.from(output['radios'])
          .map((e) => RouterRadioInfo.fromJson(e))
          .toList();
      _handleRadioInfoResult(radioInfo);
    }
    if (result.containsKey(JNAPAction.getGuestRadioSettings)) {
      final output =
          (result[JNAPAction.getGuestRadioSettings] as JNAPSuccess).output;
      final guestRadioInfoSetting = GuestRadioSetting.fromJson(output);
      _handleGuestRadioSettingsResult(guestRadioInfoSetting);
    }

    if (result.containsKey(JNAPAction.getDevices)) {
      final output = (result[JNAPAction.getDevices] as JNAPSuccess).output;
      final devices = List.from(output['devices'])
          .map((e) => RouterDevice.fromMap(e))
          .toList();
      _handleDevicesResult(devices);
    }
    if (result.containsKey(JNAPAction.getHealthCheckResults)) {
      final output =
          (result[JNAPAction.getHealthCheckResults] as JNAPSuccess).output;
      final healthCheckResults = List.from(output['healthCheckResults'])
          .map((e) => HealthCheckResult.fromJson(e))
          .toList();
      _handleHealthCheckResults(healthCheckResults);
    }
  }

  ///
  /// Handle JNAP results
  ///

  _handleDeviceInfoResult(RouterDeviceInfo routerDeviceInfo) {
    buildBetterActions(routerDeviceInfo.services);
    state = state.copyWith(
        selected: state.selected?.copyWith(deviceInfo: routerDeviceInfo) ??
            MoabNetwork(
                id: routerDeviceInfo.serialNumber,
                deviceInfo: routerDeviceInfo));
  }

  _handleWANStatusResult(RouterWANStatus wanStatus) {
    state = state.copyWith(
        selected: state.selected!.copyWith(wanStatus: wanStatus));
  }

  _handleRadioInfoResult(List<RouterRadioInfo> radioInfo) {
    state = state.copyWith(
        selected: state.selected!.copyWith(radioInfo: radioInfo));
  }

  _handleGuestRadioSettingsResult(GuestRadioSetting guestRadioSetting) {
    state = state.copyWith(
        selected:
            state.selected!.copyWith(guestRadioSetting: guestRadioSetting));
  }

  _handleIoTNetworkSettingResult(IoTNetworkSetting ioTNetworkSetting) {
    state = state.copyWith(
        selected:
            state.selected!.copyWith(iotNetworkSetting: ioTNetworkSetting));
  }

  _handleDevicesResult(List<RouterDevice> devices) {
    state =
        state.copyWith(selected: state.selected!.copyWith(devices: devices));
  }

  _handleHealthCheckResults(List<HealthCheckResult> healthCheckResults) {
    state = state.copyWith(
        selected:
            state.selected!.copyWith(healthCheckResults: healthCheckResults));
  }
}
