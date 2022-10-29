import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/cubit.dart';
import 'package:linksys_moab/bloc/internet_check/state.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/core_extension.dart';
import 'package:linksys_moab/repository/router/router_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/repository/router/setup_extension.dart';
import 'package:linksys_moab/util/logger.dart';

class InternetCheckCubit extends Cubit<InternetCheckState> {
  InternetCheckCubit({required RouterRepository routerRepository})
      : _routerRepository = routerRepository,
        super(const InternetCheckState());

  final RouterRepository _routerRepository;
  StreamSubscription? _detectWANStatusSubscription;
  StreamSubscription? _getInternetStatusSubscription;

  setConnectToRouter(bool isConnected) {
    emit(state.copyWith(
        status: isConnected
            ? InternetCheckStatus.connectedToRouter
            : InternetCheckStatus.errorConnectedToRouter));
  }

  init() {
    emit(const InternetCheckState());
  }

  setManuallyInput() {
    _detectWANStatusSubscription?.cancel();
    _getInternetStatusSubscription?.cancel();
    emit(state.copyWith(status: InternetCheckStatus.manually));
  }

  initDevice() async {
    final deviceInfoResult = await _routerRepository.getDeviceInfo();
    final deviceInfo = RouterDeviceInfo.fromJson(deviceInfoResult.output);
    final wanStatusResult = await _routerRepository.getWANStatus();
    final wanStatus = RouterWANStatus.fromJson(wanStatusResult.output);
    final configuredResults = await _routerRepository.fetchIsConfigured();
    bool isDefaultPassword = configuredResults['isAdminPasswordDefault']
        ?.output['isAdminPasswordDefault'] ?? false;
    bool isSetByUser = configuredResults['isAdminPasswordSetByUser']
        ?.output['isAdminPasswordSetByUser'] ?? false;
    final configuredData = RouterConfiguredData(
        isDefaultPassword: isDefaultPassword, isSetByUser: isSetByUser);
    bool hasConfigured =
        !configuredData.isDefaultPassword & configuredData.isSetByUser;
    emit(state.copyWith(
      status: _checkWANTypeOnInitDevice(wanStatus, hasConfigured),
      device: state.device
              ?.copyWith(deviceInfo: deviceInfo, wanStatus: wanStatus) ??
          MoabNetwork(
            id: deviceInfo.serialNumber,
            deviceInfo: deviceInfo,
            wanStatus: wanStatus,
          ),
      isConfigured: hasConfigured,
    ));
  }

  ///
  /// {
  ///     "wanStatus": "Disconnected",
  ///     "wanIPv6Status": "Disconnected",
  ///     "isDetectingWANType": false
  /// }
  ///
  detectWANStatus() async {
    _detectWANStatusSubscription?.cancel();
    _detectWANStatusSubscription = _routerRepository
        .testGetWANDetectionStatus(
            condition: () =>
                state.wanConnectionStatus == "Connected" ||
                state.wanConnectionStatus == "Connecting" ||
                state.wanConnectionStatus == "DHCP")
        .listen((event) {
      if (event is JnapSuccess) {
        final output = event.output;
        final String wanStatus = output['wanStatus'];
        final bool isDetectingWANType = output['isDetectingWANType'];
        emit(state.copyWith(
            status: InternetCheckStatus.detectWANStatus,
            wanConnectionStatus: wanStatus,
            isDetectingWANType: isDetectingWANType));
      }
    }, onDone: () {
      logger.d('done detect WAN status');
      _detectWANStatusSubscription?.cancel();
      _finalCheckWANStatus();
    });
  }

  ///
  /// {"connectionStatus":"NoPortConnected"}
  ///
  getInternetConnectionStatus() {
    _getInternetStatusSubscription?.cancel();
    _getInternetStatusSubscription = _routerRepository
        .testGetInternetConnectionStatus(
            condition: () => state.isInternetConnected)
        .listen((event) {
      if (event is JnapSuccess) {
        final output = event.output;
        final connectionStatus = output['connectionStatus'];
        emit(state.copyWith(
            isInternetConnected: connectionStatus == 'InternetConnected'));
      }
    }, onDone: () {
      logger.d('done get Internet status');
      _getInternetStatusSubscription?.cancel();
      _finalCheckInternetStatus();
    });
  }

  InternetCheckStatus _checkWANTypeOnInitDevice(
      RouterWANStatus wanStatus, bool isRouterConfigured) {
    // TODO handle configured case!!!
    switch (wanStatus.detectedWANType) {
      case 'PPPoE':
        return InternetCheckStatus.pppoe;
      case 'Static':
        return InternetCheckStatus.static;
      case 'DHCP':
        return InternetCheckStatus.detectWANStatus;
      default:
        return InternetCheckStatus.detectWANStatus;
    }
  }

  _finalCheckWANStatus() {
    if (state.wanConnectionStatus == "Connected" ||
        state.wanConnectionStatus == "Connecting" ||
        state.wanConnectionStatus == "DHCP") {
      emit(state.copyWith(
          status: InternetCheckStatus.getInternetConnectionStatus));
    } else {
      emit(state.copyWith(status: InternetCheckStatus.checkWiring));
    }
  }

  _finalCheckInternetStatus() async {
    if (state.isInternetConnected) {
      await _checkUnsecureWiFiWarning();
      emit(state.copyWith(status: InternetCheckStatus.connected));
    } else {
      emit(state.copyWith(status: InternetCheckStatus.noInternet));
    }
  }

  _checkUnsecureWiFiWarning() async {
    final result = await _routerRepository.getUnsecuredWiFiWarning();
    final bool enabled = result.output['enabled'] ?? false;
    if (enabled) {
      await _routerRepository.setUnsecuredWiFiWarning(!enabled);
    }
  }

  @override
  void onChange(Change<InternetCheckState> change) {
    super.onChange(change);
    logger.d('Internet Check onChange: $change');
  }
}
