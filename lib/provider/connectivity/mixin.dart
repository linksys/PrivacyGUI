import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:linksys_app/provider/connectivity/connectivity_state.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/constants/cloud_const.dart';
import 'package:linksys_app/core/http/linksys_http_client.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'availability_info.dart';
import 'connectivity_info.dart';

mixin AvailabilityChecker {
  static const defaultInternetCheckPeriodSec = 60;
  Duration internetCheckPeriod =
      const Duration(seconds: defaultInternetCheckPeriodSec);
  Timer? timer;
  final _client = LinksysHttpClient(timeoutMs: 3000);
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
    return _client
        .get(Uri.parse(cloudEnvironmentConfig[kCloudStatus]))
        .then((response) {
      final isCloudOk = json.decode(response.body)['cloudStatus'] == 'OK';
      return AvailabilityInfo(isCloudOk: isCloudOk);
    });
  }
}

mixin ConnectivityListener {
  final Connectivity connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  void start() {
    if (_connectivitySubscription != null) {
      return;
    }
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen(updateConnectivity);
  }

  void stop() {
    _connectivitySubscription?.cancel();
  }

  updateConnectivity(ConnectivityResult result) async {
    if (kIsWeb) {
      return;
    }
    logger.d('Connectivity Result: $result');
    final connectivityInfo = await _updateNetworkInfo(result);
    await onConnectivityChanged(connectivityInfo);
  }

  Future<ConnectivityInfo> _updateNetworkInfo(ConnectivityResult result) async {
    final networkInfo = NetworkInfo();

    String? wifiName, wifiGatewayIP;

    try {
      if (!kIsWeb && Platform.isIOS) {
        var status = await networkInfo.getLocationServiceAuthorization();
        if (status == LocationAuthorizationStatus.notDetermined) {
          status = await networkInfo.requestLocationServiceAuthorization();
        }
        if (status == LocationAuthorizationStatus.authorizedAlways ||
            status == LocationAuthorizationStatus.authorizedWhenInUse) {
          wifiName = await networkInfo.getWifiName();
        } else {
          wifiName = await networkInfo.getWifiName();
        }
      } else {
        wifiName = await networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      logger.e('Failed to get Wifi Name', error: e);
      wifiName = 'Unknown SSID';
    }

    try {
      wifiGatewayIP = await networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      logger.e('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Unknown Gateway IP';
    }

    if ((wifiGatewayIP?.isNotEmpty ?? false) && (wifiName?.isEmpty ?? true)) {
      // get wifi name again if there has gateway ip but no wifi name
      wifiName = await networkInfo.getWifiName();
    }
    final info = ConnectivityInfo(
        type: result, gatewayIp: wifiGatewayIP ?? "", ssid: wifiName ?? "");
    return info;
  }

  Future onConnectivityChanged(ConnectivityInfo info);
}
