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
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_app.dart';
import 'package:linksys_moab/repository/router/commands/batch_extension.dart';
import 'package:linksys_moab/repository/router/commands/core_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      : _routerRepository = routerRepository,
        super(const ConnectivityState(
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
      // await scheduleCheck(immediate: true);
      final newState = await check(info);
      emit(newState);
    } else {
      emit(state.copyWith(connectivityInfo: info));
    }
  }

  void init() {
    callback = _internetCheckCallback;
    // scheduleCheck();
    start();
  }

  Future<ConnectivityState> forceUpdate() async {
    _checkAndroidVersionAndEasyConnect();
    await _updateConnectivity(await _connectivity.checkConnectivity());
    return state;
  }

  Future<ConnectivityState> _internetCheckCallback(bool hasConnection,
      ConnectivityInfo connectivityInfo, AvailabilityInfo? cloudInfo) async {
    logger.d('_internetCheckCallback: $hasConnection, $connectivityInfo');

    var routerType = RouterType.others;
    if (hasConnection) {
      routerType = await _testRouterType(connectivityInfo.gatewayIp);
    }
    logger.d('_internetCheckCallback: $routerType');
    return state.copyWith(
        connectivityInfo: connectivityInfo.copyWith(routerType: routerType),
        hasInternet: hasConnection,
        cloudAvailabilityInfo: cloudInfo);
  }

  void _checkAndroidVersionAndEasyConnect() async {
    isAndroid9 = await ConnectingWifiPlugin().isAndroidVersionUnderTen();
    isAndroid10AndSupportEasyConnect = isAndroid9
        ? false
        : await ConnectingWifiPlugin().isAndroidTenAndSupportEasyConnect();
  }

  Future<RouterType> _testRouterType(String? newIp) async {
    final testJNAP = await _routerRepository
        .isAdminPasswordDefault()
        .then((value) => true)
        .onError((error, stackTrace) => false);
    if (!testJNAP) {
      return RouterType.others;
    }

    final routerSN = await _routerRepository
        .getDeviceInfo()
        .then<String>(
            (value) => RouterDeviceInfo.fromJson(value.output).serialNumber)
        .onError((error, stackTrace) => '');
    final prefs = await SharedPreferences.getInstance();
    final currentSN = prefs.get(linkstyPrefCurrentSN);
    if (routerSN.isNotEmpty && routerSN == currentSN) {
      return RouterType.behindManaged;
    }
    return RouterType.behind;
  }

  @override
  void onChange(Change<ConnectivityState> change) {
    super.onChange(change);
    logger.i(
        'Connectivity Cubit change: ${change.currentState} -> ${change.nextState}');
  }

  Future<RouterConfiguredData> isRouterConfigured() async {
    final results = await _routerRepository.fetchIsConfigured();
    bool isDefaultPassword =
        results['isAdminPasswordDefault']?.output['isAdminPasswordDefault'];
    bool isSetByUser =
        results['isAdminPasswordSetByUser']?.output['isAdminPasswordSetByUser'];
    return RouterConfiguredData(
        isDefaultPassword: isDefaultPassword, isSetByUser: isSetByUser);
  }
}

mixin AvailabilityChecker {
  static const defaultInternetCheckPeriodSec = 60;
  Duration internetCheckPeriod =
      const Duration(seconds: defaultInternetCheckPeriodSec);
  Timer? timer;
  final _client = MoabHttpClient(timeoutMs: 3000);
  Function(bool, ConnectivityInfo, AvailabilityInfo?)? _callback;

  set callback(Function(bool, ConnectivityInfo, AvailabilityInfo?) callback) =>
      _callback = callback;

  // scheduleCheck({bool immediate = false, int? periodInSec}) async {
  //   logger.d("Connectivity start schedule check");
  //   if (periodInSec != null) {
  //     internetCheckPeriod = Duration(seconds: periodInSec);
  //   }
  //   if (immediate) {
  //     await check();
  //   }
  //   timer?.cancel();
  //   timer = Timer.periodic(internetCheckPeriod, (timer) async {
  //     logger.d('Start period check internet...');
  //     await check();
  //   });
  // }
  //
  // stopChecking() {
  //   timer?.cancel();
  // }

  Future<ConnectivityState> check(ConnectivityInfo info) async {
    final hasConnection = await testConnection();
    if (!hasConnection) {
      return _callback?.call(hasConnection, info, null);
    }
    final cloudAvailability = await testCloudAvailability();

    return _callback?.call(hasConnection, info, cloudAvailability);
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

    if ((wifiGatewayIP?.isNotEmpty ?? false) && (wifiName?.isEmpty ?? true)) {
      // get wifi name again if there has gateway ip but no wifi name
      wifiName = await _networkInfo.getWifiName();
    }
    final info = ConnectivityInfo(
        type: result, gatewayIp: wifiGatewayIP ?? "", ssid: wifiName ?? "");
    return info;
  }

  Future onConnectivityChanged(ConnectivityInfo info);
}
