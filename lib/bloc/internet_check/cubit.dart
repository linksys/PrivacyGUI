import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/cubit.dart';
import 'package:linksys_moab/bloc/internet_check/state.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/model/router/wan_settings.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/core_extension.dart';
import 'package:linksys_moab/repository/router/router_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/repository/router/setup_extension.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';

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

  init({bool isPlugModemBack = false}) {
    emit(InternetCheckState(afterPlugModemBack: isPlugModemBack));
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

  detectWANStatusUntilConnected() async {
    return detectWANStatus(
        retryDelayInSec: 6,
        maxRetry: 20,
        condition: () =>
            state.wanConnectionStatus == 'Connected' ||
            state.wanConnectionStatus == 'Disconnected');
  }

  ///
  /// {
  ///     "wanStatus": "Disconnected",
  ///     "wanIPv6Status": "Disconnected",
  ///     "isDetectingWANType": false
  /// }
  ///
  detectWANStatus(
      {int retryDelayInSec = 5,
      int maxRetry = 10,
      bool Function()? condition}) async {
    _detectWANStatusSubscription?.cancel();
    _detectWANStatusSubscription = _routerRepository
        .scheduledCommand(
            action: JNAPAction.getWANDetectionStatus,
            retryDelayInSec: retryDelayInSec,
            maxRetry: maxRetry,
            condition: condition ??
                () =>
                    state.wanConnectionStatus == "Connected" ||
                    state.wanConnectionStatus == "Connecting" ||
                    state.wanConnectionStatus == "DHCP")
        .listen((event) {
      if (event is JnapSuccess) {
        final output = event.output;
        final String wanStatus = output['wanStatus'];
        final bool isDetectingWANType = output['isDetectingWANType'];
        emit(state.copyWith(
            wanConnectionStatus: wanStatus,
            isDetectingWANType: isDetectingWANType));
      }
    }, onDone: () {
      logger.d('done detect WAN status');
      _detectWANStatusSubscription?.cancel();
      _finalCheckWANStatus(condition: condition);
    });
  }

  ///
  /// {"connectionStatus":"NoPortConnected"}
  ///
  getInternetConnectionStatus() {
    _getInternetStatusSubscription?.cancel();
    _getInternetStatusSubscription = _routerRepository
        .scheduledCommand(
            action: JNAPAction.getInternetConnectionStatus,
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

  testGetOwnedNetworkId() {}

  Future fetchRouterWANSettings() async {
    final routerWANSettings = await _routerRepository
        .getWANSettings()
        .then<RouterWANSettings?>(
            (value) => RouterWANSettings.fromJson(value.output))
        .onError((error, stackTrace) => null);
    emit(state.copyWith(routerWANSettings: routerWANSettings));
  }

  Future<bool> checkInternetConnectionStatus() async {
    return await _routerRepository
        .getInternetConnectionStatus()
        .then((value) => value.output['connectionStatus'] != 'NoPortConnected');
  }

  Future setPPPoESettings(String username, String password, String vlan) async {
    final newPPPoESettings = PPPoESettings(
      username: username,
      password: password,
      serviceName: state.routerWANSettings?.pppoeSettings?.serviceName ?? '',
      behavior: 'KeepAlive',
      maxIdleMinutes: 1,
      reconnectAfterSeconds: 20,
    );

    SinglePortVLANTaggingSettings? wanTaggedSettings;
    if (vlan.isNotEmpty) {
      int min = state.routerWANSettings?.wanTaggingSettings?.vlanTaggingSettings
              ?.vlanLowerLimit ??
          -1;
      int max = state.routerWANSettings?.wanTaggingSettings?.vlanTaggingSettings
              ?.vlanUpperLimit ??
          -1;
      if (min == -1 || max == -1) {
        // need to fetch WANSettings
        return;
      }
      wanTaggedSettings = SinglePortVLANTaggingSettings(
        isEnabled: true,
        vlanTaggingSettings: PortTaggingSettings(
          vlanID: int.parse(vlan),
          vlanLowerLimit: state.routerWANSettings!.wanTaggingSettings!
              .vlanTaggingSettings!.vlanLowerLimit,
          vlanUpperLimit: state.routerWANSettings!.wanTaggingSettings!
              .vlanTaggingSettings!.vlanUpperLimit,
          vlanStatus: 'Tagged',
        ),
      );
    }
    var newWANSettings = RouterWANSettings(
      wanType: 'PPPoE',
      mtu: state.routerWANSettings?.mtu ?? 0,
      pppoeSettings: newPPPoESettings,
    );
    if (wanTaggedSettings != null) {
      newWANSettings =
          newWANSettings.copyWith(wanTaggingSettings: wanTaggedSettings);
    }
    // WAN Interrupted
    await _routerRepository
        .setWANSettings(newWANSettings)
        .then((_) => Future.delayed(const Duration(seconds: 10)));
    emit(state.copyWith(status: InternetCheckStatus.detectWANStatus));
  }

  Future setStaticSettings({
    required String ipAddress,
    required String subnetMask,
    required String gateway,
    required String dns1,
    String dns2 = '',
  }) async {
    final staticWANSettings = StaticSettings(
      ipAddress: ipAddress,
      networkPrefixLength: Utils.subnetMaskToPrefixLength(subnetMask),
      gateway: gateway,
      dnsServer1: dns1,
      dnsServer2: dns2.isEmpty ? null : dns2,
    );

    final newWANSettings = RouterWANSettings(
        wanType: 'Static', mtu: 0, staticSettings: staticWANSettings);

    await _routerRepository.setWANSettings(newWANSettings).then(
          (_) => Future.delayed(
            const Duration(seconds: 90),
          ),
        );
    emit(state.copyWith(status: InternetCheckStatus.detectWANStatus));
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

  _finalCheckWANStatus({bool Function()? condition}) {
    if (condition != null
        ? condition.call()
        : (state.wanConnectionStatus == 'Connected' ||
            state.wanConnectionStatus == 'Connecting' ||
            state.wanConnectionStatus == 'DHCP')) {
      emit(state.copyWith(
          status: InternetCheckStatus.getInternetConnectionStatus));
    } else if (state.wanConnectionStatus == 'PPPoE') {
      emit(state.copyWith(status: InternetCheckStatus.pppoe));
    } else if (state.wanConnectionStatus == 'Static') {
      emit(state.copyWith(status: InternetCheckStatus.static));
    } else {
      emit(state.copyWith(status: InternetCheckStatus.checkWiring));
    }
  }

  _finalCheckInternetStatus() async {
    if (state.isInternetConnected) {
      await _checkUnsecureWiFiWarning();
      emit(state.copyWith(status: InternetCheckStatus.connected));
    } else {
      emit(state.copyWith(
        status: InternetCheckStatus.noInternet,
      ));
    }
  }

  _checkUnsecureWiFiWarning() async {
    final result = await _routerRepository.getUnsecuredWiFiWarning();
    final bool enabled = result.output['enabled'] ?? false;
    if (enabled) {
      await _routerRepository.setUnsecuredWiFiWarning(!enabled);
      // TODO #REFACTOR wireless interrupt
      await Future.delayed(Duration(seconds: 3));
      await _routerRepository.connectToLocalWithPassword();
    }
  }

  @override
  void onChange(Change<InternetCheckState> change) {
    super.onChange(change);
    logger.d('Internet Check onChange: $change');
  }
}
