import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ConnectivityInfo {
  const ConnectivityInfo({required this.gatewayIp, required this.ssid});

  final String gatewayIp;
  final String ssid;
}

class ConnectivityUtil {
  static String gatewayIp = '';

  static Future<ConnectivityInfo> updateNetworkInfo() async {
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
      log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }

    gatewayIp = wifiGatewayIP ?? '';

    return ConnectivityInfo(
        gatewayIp: wifiGatewayIP ?? "", ssid: wifiName ?? "");
  }
}

mixin ConnectivityListener {
  ConnectivityResult connectionStatus = ConnectivityResult.none;
  ConnectivityInfo connectivityInfo =
      const ConnectivityInfo(gatewayIp: '', ssid: '');
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  void start() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectivity);
  }

  void stop() {
    _connectivitySubscription?.cancel();
  }

  _updateConnectivity(ConnectivityResult result) async {
    connectionStatus = result;
    connectivityInfo = await ConnectivityUtil.updateNetworkInfo();

    onConnectivityChanged(connectionStatus, connectivityInfo);
  }

  Future onConnectivityChanged(
      ConnectivityResult result, ConnectivityInfo info);
}
