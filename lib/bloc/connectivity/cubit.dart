import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connecting_wifi_plugin/connecting_wifi_plugin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/availability_info.dart';
import 'package:linksys_moab/bloc/mixin/stream_mixin.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../constants/_constants.dart';
import 'connectivity_info.dart';
import 'state.dart';

class RouterConfiguredData {

  const RouterConfiguredData({
    required this.isDefaultPassword,
    required this.isSetByUser,
  });
  
  final bool isDefaultPassword;
  final bool isSetByUser;


}

class ConnectivityCubit extends Cubit<ConnectivityState>
    with ConnectivityListener, AvailabilityChecker, StateStreamRegister {
  ConnectivityCubit({required RouterRepository routerRepository})
      : _routerRepository = routerRepository, super(const ConnectivityState(
            hasInternet: false, connectivityInfo: ConnectivityInfo())) {
    shareStream = stream;
    register(routerRepository);
  }

  final RouterRepository _routerRepository;
  // TODO refactor
  bool isAndroid9 = false;
  bool isAndroid10AndSupportEasyConnect = false;

  @override
  Future<void> close() async {
    unregisterAll();
    super.close();
  }

  @override
  Future onConnectivityChanged(ConnectivityInfo info) async {
    if (info.type != ConnectivityResult.none) {
      await scheduleCheck(immediate: true);
    }
    emit(state.copyWith(connectivityInfo: info));
  }

  void init() {
    callback = _internetCheckCallback;
    scheduleCheck();
    start();
  }

  Future<ConnectivityState> forceUpdate() async {
    _checkAndroidVersionAndEasyConnect();
    _updateConnectivity(await _connectivity.checkConnectivity());
    return state;
  }

  void _internetCheckCallback(
      bool hasConnection, AvailabilityInfo? cloudInfo) async {
    if (hasConnection) {
      await CloudEnvironmentManager().fetchCloudConfig();
      await CloudEnvironmentManager().fetchAllCloudConfigs();
    }
    logger.d('internet check result: $state');
    emit(state.copyWith(
        hasInternet: hasConnection, cloudAvailabilityInfo: cloudInfo));
  }

  void _checkAndroidVersionAndEasyConnect() async {
    isAndroid9 = await ConnectingWifiPlugin().isAndroidVersionUnderTen();
    isAndroid10AndSupportEasyConnect = isAndroid9
        ? false
        : await ConnectingWifiPlugin().isAndroidTenAndSupportEasyConnect();
  }

  @override
  void onChange(Change<ConnectivityState> change) {
    super.onChange(change);
    logger.i(
        'Connectivity Cubit change: ${change.currentState} -> ${change.nextState}');
  }

  Future<bool> connectToLocalBroker() async {
    return _routerRepository
        .downloadCert().onError((error, stackTrace) => false)
        .then((value) => _routerRepository.connectToLocal());
  }

  Future<RouterConfiguredData> isRouterConfigured() async {
    final results = await _routerRepository.fetchIsConfigured();
    bool isDefaultPassword = results.firstWhere((element) => element.output.containsKey('isAdminPasswordDefault')).output['isAdminPasswordDefault'];
    bool isSetByUser = results.firstWhere((element) => element.output.containsKey('isAdminPasswordSetByUser')).output['isAdminPasswordSetByUser'];
    return RouterConfiguredData(isDefaultPassword: isDefaultPassword, isSetByUser: isSetByUser);
  }
}

mixin AvailabilityChecker {
  static const defaultInternetCheckPeriodSec = 60;
  Duration internetCheckPeriod = const Duration(seconds: defaultInternetCheckPeriodSec);
  Timer? timer;
  final _client = MoabHttpClient(timeoutMs: 3000);
  Function(bool, AvailabilityInfo?)? _callback;

  set callback(Function(bool, AvailabilityInfo?) callback) =>
      _callback = callback;

  scheduleCheck({bool immediate = false, int? periodInSec}) async {
    logger.d("Connectivity start schedule check");
    if (periodInSec != null) {
      internetCheckPeriod = Duration(seconds: periodInSec);
    }
    if (immediate) {
      await check();
    }
    timer?.cancel();
    timer = Timer.periodic(internetCheckPeriod, (timer) async {
      logger.d('Start period check internet...');
      await check();
    });
  }

  stopChecking() {
    timer?.cancel();
  }

  check() async {
    final hasConnection = await testConnection();
    if (!hasConnection) {
      _callback?.call(hasConnection, null);
      return;
    }
    // final cloudAvailability = await testCloudAvailability();
    final cloudAvailability = AvailabilityInfo(isCloudOk: true);

    _callback?.call(hasConnection, cloudAvailability);
  }

  Future<bool> testConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<AvailabilityInfo> testCloudAvailability() async {
    return _client.get(Uri.parse(availabilityUrl)).then((response) {
      final isCloudOk = json.decode(response.body)['cloudStatus'] == 'OK';
      return AvailabilityInfo(isCloudOk: isCloudOk);
    });
  }
}

mixin ConnectivityListener {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  void start() {
    if (_connectivitySubscription != null) {
      return;
    }
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectivity);
  }

  void stop() {
    _connectivitySubscription?.cancel();
  }

  _updateConnectivity(ConnectivityResult result) async {
    logger.d('Connectivity Result: $result');
    final connectivityInfo = await _updateNetworkInfo(result);
    await onConnectivityChanged(connectivityInfo);
  }

  Future<ConnectivityInfo> _updateNetworkInfo(ConnectivityResult result) async {
    final _networkInfo = NetworkInfo();

    String? wifiName, wifiGatewayIP;

    try {
      if (!kIsWeb && Platform.isIOS) {
        var status = await _networkInfo.getLocationServiceAuthorization();
        if (status == LocationAuthorizationStatus.notDetermined) {
          status = await _networkInfo.requestLocationServiceAuthorization();
        }
        if (status == LocationAuthorizationStatus.authorizedAlways ||
            status == LocationAuthorizationStatus.authorizedWhenInUse) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = await _networkInfo.getWifiName();
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      logger.e('Failed to get Wifi Name', e);
      wifiName = 'Unknown SSID';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      logger.e('Failed to get Wifi gateway address', e);
      wifiGatewayIP = 'Unknown Gateway IP';
    }


    final info = ConnectivityInfo(
        type: result, gatewayIp: wifiGatewayIP ?? "", ssid: wifiName ?? "");
    return info;
  }

  Future onConnectivityChanged(ConnectivityInfo info);
}
