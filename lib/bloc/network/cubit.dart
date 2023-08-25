import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/bloc/mixin/stream_mixin.dart';
import 'package:linksys_app/bloc/network/cloud_network_model.dart';
import 'package:linksys_app/bloc/network/state.dart';
import 'package:linksys_app/constants/jnap_const.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:linksys_app/main.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/device_info.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';
import 'package:linksys_app/core/jnap/models/health_check_result.dart';
import 'package:linksys_app/core/jnap/models/iot_network_settings.dart';
import 'package:linksys_app/core/jnap/models/network.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/cloud/linksys_cloud_repository.dart';

class NetworkCubit extends Cubit<NetworkState> with StateStreamRegister {
  NetworkCubit({
    required LinksysCloudRepository cloudRepository,
    required RouterRepository routerRepository,
  })  : _cloudRepository = cloudRepository,
        _routerRepository = routerRepository,
        super(const NetworkState()) {
    shareStream = stream;
    register(_routerRepository);

    container.listen(pollingProvider, (previous, next) {
      next.whenData((value) => pollingData(value.data));
    });
  }

  final LinksysCloudRepository _cloudRepository;
  final RouterRepository _routerRepository;

  @override
  Future<void> close() async {
    unregisterAll();
    super.close();
  }

  ///
  /// Cloud API
  ///

  reset() {
    emit(const NetworkState());
  }

  Future<List<CloudNetworkModel>> getNetworks(
      {required String accountId}) async {
    final networks = await Future.wait(
        (await _cloudRepository.getNetworks()).map((network) async {
      bool isOnline = await _routerRepository
          .send(
            JNAPAction.isAdminPasswordDefault,
            extraHeaders: {
              kJNAPNetworkId: network.network.networkId,
            },
            type: CommandType.remote,
          )
          .then((value) => value.result == 'OK')
          .onError((error, stackTrace) => false);
      return CloudNetworkModel(network: network.network, isOnline: isOnline);
    }).toList());
    if (networks.length == 1) {
      // await getDeviceInfo();
    } else {}
    emit(state.copyWith(
      networks: [
        ...networks.where((element) => element.isOnline),
        ...networks.where((element) => !element.isOnline),
      ],
      selected: state.selected,
    ));
    return networks;
  }

  ///
  /// JNAP commands
  ///

  Future<RouterDeviceInfo> getDeviceInfo() async {
    final result = await _routerRepository.send(JNAPAction.getDeviceInfo);
    final routerDeviceInfo = RouterDeviceInfo.fromJson(result.output);
    _handleDeviceInfoResult(routerDeviceInfo);
    return routerDeviceInfo;
  }

  Future<RouterWANStatus> getWANStatus() async {
    final result = await _routerRepository.send(
      JNAPAction.getWANStatus,
    );
    final wanStatus = RouterWANStatus.fromJson(result.output);
    _handleWANStatusResult(wanStatus);
    return wanStatus;
  }

  Future<List<RouterRadioInfo>> getRadioInfo() async {
    final result = await _routerRepository.send(
      JNAPAction.getRadioInfo,
      auth: true,
    );
    final radioInfo = List.from(result.output['radios'])
        .map((e) => RouterRadioInfo.fromJson(e))
        .toList();
    _handleRadioInfoResult(radioInfo);
    return radioInfo;
  }

  Future<List<RouterDevice>> getDevices() async {
    final result = await _routerRepository.send(JNAPAction.getDevices);
    final devices = List.from(result.output['devices'])
        .map((e) => RouterDevice.fromJson(e))
        .toList();
    _handleDevicesResult(devices);
    return devices;
  }

  Future<void> getHealthCheckResults() async {
    final result = await _routerRepository.send(
      JNAPAction.getHealthCheckResults,
      data: {'includeModuleResults': true},
      auth: true,
    );
    final healthCheckResults = List.from(result.output['healthCheckResults'])
        .map((e) => HealthCheckResult.fromJson(e))
        .toList();
    _handleHealthCheckResults(healthCheckResults);
  }

  Future<SpeedTestResult> getHealthCheckStatus() async {
    SpeedTestResult speedTestResult =
        const SpeedTestResult(resultID: 0, exitCode: '');
    final result = await _routerRepository.send(
      JNAPAction.getHealthCheckStatus,
      auth: true,
    );
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
    final result = await _routerRepository.send(
      JNAPAction.runHealthCheck,
      data: {'runHealthCheckModule': 'SpeedTest'},
      auth: true,
    );
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
          emit(state.copyWith(selected: selectedCopy));
          getHealthCheckResults();
          timer.cancel();
        }
      });
    }
  }

  createAdminPassword(String password, String hint) async {
    await _routerRepository.send(
      JNAPAction.coreSetAdminPassword,
      data: {
        'adminPassword': 'admin',
        'passwordHint': hint,
      },
      auth: true,
    );
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

  _handleGuestRadioSettingsResult(GuestRadioSetting guestRadioSetting) {
    emit(state.copyWith(
        selected:
            state.selected!.copyWith(guestRadioSetting: guestRadioSetting)));
  }

  _handleIoTNetworkSettingResult(IoTNetworkSetting ioTNetworkSetting) {
    emit(state.copyWith(
        selected:
            state.selected!.copyWith(iotNetworkSetting: ioTNetworkSetting)));
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
          .map((e) => RouterDevice.fromJson(e))
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

  init() {
    emit(const NetworkState());
  }

  Future selectNetwork(CloudNetworkModel network) async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(pCurrentSN);
    await pref.setString(prefSelectedNetworkId, network.network.networkId);
    // CloudEnvironmentManager().applyNewConfig(network.region);
    emit(state.copyWith(selected: MoabNetwork(id: network.network.networkId)));
  }

  HealthCheckResult getLatestHealthCheckResult(
      List<HealthCheckResult> healthCheckResults) {
    healthCheckResults.sort((e1, e2) => e2.timestamp.compareTo(e1.timestamp));
    return healthCheckResults.first;
  }

  @override
  void onChange(Change<NetworkState> change) {
    super.onChange(change);
    logger.d('on network state change: $change');
  }
}

extension NetworkCubitExts on NetworkCubit {
  String? getSerialNumber() {
    return state.selected?.deviceInfo?.serialNumber ??
        state.networks
            .firstWhereOrNull(
                (element) => element.network.networkId == state.selected?.id)
            ?.network
            .routerSerialNumber;
  }
}
