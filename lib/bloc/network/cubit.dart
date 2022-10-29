import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/mixin/stream_mixin.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/pref_key.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/model/router/health_check_result.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/http/extension_requests/network_requests.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_network.dart';
import 'package:linksys_moab/repository/networks/cloud_networks_repository.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/core_extension.dart';
import 'package:linksys_moab/repository/router/device_list_extension.dart';
import 'package:linksys_moab/repository/router/health_check_extension.dart';
import 'package:linksys_moab/repository/router/router_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/repository/router/wireless_ap_extension.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkCubit extends Cubit<NetworkState> with StateStreamRegister {
  NetworkCubit(
      {required CloudNetworksRepository networksRepository,
      required RouterRepository routerRepository})
      : _networksRepository = networksRepository,
        _routerRepository = routerRepository,
        super(const NetworkState()) {
    shareStream = stream;
    register(_routerRepository);
  }

  final CloudNetworksRepository _networksRepository;
  final RouterRepository _routerRepository;

  @override
  Future<void> close() async {
    unregisterAll();
    super.close();
  }

  ///
  /// Cloud API
  ///

  Future<List<CloudNetwork>> getNetworks({required String accountId}) async {
    final networks =
        await _networksRepository.getNetworks(accountId: accountId);
    if (networks.length == 1) {
      // await getDeviceInfo();
    } else {}
    emit(state.copyWith(networks: networks, selected: state.selected));
    return networks;
  }

  ///
  /// JNAP commands
  ///

  Future<RouterDeviceInfo> getDeviceInfo() async {
    final result = await _routerRepository.getDeviceInfo();
    final routerDeviceInfo = RouterDeviceInfo.fromJson(result.output);
    _handleDeviceInfoResult(routerDeviceInfo);
    return routerDeviceInfo;
  }

  Future<RouterWANStatus> getWANStatus() async {
    final result = await _routerRepository.getWANStatus();
    final wanStatus = RouterWANStatus.fromJson(result.output);
    _handleWANStatusResult(wanStatus);
    return wanStatus;
  }

  Future<List<RouterRadioInfo>> getRadioInfo() async {
    final result = await _routerRepository.getRadioInfo();
    final radioInfo = List.from(result.output['radios'])
        .map((e) => RouterRadioInfo.fromJson(e))
        .toList();
    _handleRadioInfoResult(radioInfo);
    return radioInfo;
  }

  Future<List<RouterDevice>> getDevices() async {
    final result = await _routerRepository.getDevices();
    final devices = List.from(result.output['devices'])
        .map((e) => RouterDevice.fromJson(e))
        .toList();
    _handleDevicesResult(devices);
    return devices;
  }

  Future<void> getHealthCheckResults() async {
    final result = await _routerRepository.getHealthCheckResults();
    final healthCheckResults = List.from(result.output['healthCheckResults'])
        .map((e) => HealthCheckResult.fromJson(e))
        .toList();
    _handleHealthCheckResults(healthCheckResults);
  }

  Future<SpeedTestResult> getHealthCheckStatus() async {
    SpeedTestResult speedTestResult = const SpeedTestResult(resultID: 0, exitCode: '');
    final result = await _routerRepository.getHealthCheckStatus();
    if (result.output['healthCheckModuleCurrentlyRunning'] == 'SpeedTest') {
      speedTestResult =
          SpeedTestResult.fromJson(result.output['speedTestResult']);
      emit(state.copyWith(
          selected: state.selected!
              .copyWith(currentSpeedTestStatus: speedTestResult)));
    }
    return speedTestResult;
  }

  Future<void> runHealthCheck() async {
    final result = await _routerRepository.runHealthCheck();
    if (result.output['resultID'] != null) {
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        final speedTestResult = await getHealthCheckStatus();
        if (speedTestResult.exitCode != 'Unavailable') {
          final _selected = state.selected!;
          MoabNetwork _selectedCopy = MoabNetwork(
              id: _selected.id,
              deviceInfo: _selected.deviceInfo,
              wanStatus: _selected.wanStatus,
              radioInfo: _selected.radioInfo,
              devices: _selected.devices,
              healthCheckResults: _selected.healthCheckResults,
              currentSpeedTestStatus: null);
          emit(state.copyWith(selected: _selectedCopy));
          getHealthCheckResults();
          timer.cancel();
        }
      });
    }
  }

  createAdminPassword(String password, String hint) async {
    await _routerRepository.createAdminPassword('admin', hint);
  }

  ///
  /// Handle JNAP results
  ///

  _handleDeviceInfoResult(RouterDeviceInfo routerDeviceInfo) {
    buildBetterActions(routerDeviceInfo.services);
    emit(state.copyWith(
        selected: state.selected?.copyWith(deviceInfo: routerDeviceInfo) ??
            MoabNetwork(
                id: routerDeviceInfo.serialNumber,
                deviceInfo: routerDeviceInfo)));
  }

  _handleWANStatusResult(RouterWANStatus wanStatus) {
    emit(state.copyWith(
        selected: state.selected!.copyWith(wanStatus: wanStatus)));
  }

  _handleRadioInfoResult(List<RouterRadioInfo> radioInfo) {
    emit(state.copyWith(
        selected: state.selected!.copyWith(radioInfo: radioInfo)));
  }

  _handleDevicesResult(List<RouterDevice> devices) {
    emit(state.copyWith(selected: state.selected!.copyWith(devices: devices)));
  }

  _handleHealthCheckResults(List<HealthCheckResult> healthCheckResults) {
    emit(state.copyWith(
        selected:
            state.selected!.copyWith(healthCheckResults: healthCheckResults)));
  }

  ///
  /// UI methods
  ///

  Future pollingData() async {
    logger.d('start polling data');
    final result = await _routerRepository.pollingData();
    if (result.containsKey(JNAPAction.getDeviceInfo.actionValue)) {
      final routerDeviceInfo = RouterDeviceInfo.fromJson(
          result[JNAPAction.getDeviceInfo.actionValue]!.output);
      _handleDeviceInfoResult(routerDeviceInfo);
    }
    if (result.containsKey(JNAPAction.getWANStatus.actionValue)) {
      final wanStatus = RouterWANStatus.fromJson(
          result[JNAPAction.getWANStatus.actionValue]!.output);
      _handleWANStatusResult(wanStatus);
    }
    if (result.containsKey(JNAPAction.getRadioInfo.actionValue)) {
      final radioInfo = List.from(
              result[JNAPAction.getRadioInfo.actionValue]!.output['radios'])
          .map((e) => RouterRadioInfo.fromJson(e))
          .toList();
      _handleRadioInfoResult(radioInfo);
    }
    if (result.containsKey(JNAPAction.getDevices.actionValue)) {
      final devices = List.from(
              result[JNAPAction.getDevices.actionValue]!.output['devices'])
          .map((e) => RouterDevice.fromJson(e))
          .toList();
      _handleDevicesResult(devices);
    }
    if (result.containsKey(JNAPAction.getHealthCheckResults.actionValue)) {
      final healthCheckResults = List.from(
              result[JNAPAction.getHealthCheckResults.actionValue]!
                  .output['healthCheckResults'])
          .map((e) => HealthCheckResult.fromJson(e))
          .toList();
      _handleHealthCheckResults(healthCheckResults);
    }

    logger.d('finish polling data');
  }

  init() {
    emit(const NetworkState());
  }

  Future selectNetwork(CloudNetwork network) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(moabPrefSelectedNetworkId, network.networkId);
    CloudEnvironmentManager().applyNewConfig(network.region);
    emit(state.copyWith(selected: MoabNetwork(id: network.networkId)));
  }

  HealthCheckResult getLatestHealthCheckResult(List<HealthCheckResult> healthCheckResults) {
    healthCheckResults.sort((e1, e2) => e2.timestamp.compareTo(e1.timestamp));
    return healthCheckResults.first;
  }
}
