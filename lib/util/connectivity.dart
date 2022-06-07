import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/packages/openwrt/model/identity.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ConnectivityInfo {
  const ConnectivityInfo({this.type = ConnectivityResult.none, required this.gatewayIp, required this.ssid});
  final ConnectivityResult type;
  final String gatewayIp;
  final String ssid;
}


class ConnectivityUtil with ConnectivityListener {
  static Identity? identity;
  static ConnectivityInfo latest =
      const ConnectivityInfo(gatewayIp: '', ssid: '');
  static final StreamController<ConnectivityInfo> _streamController = StreamController();
  static Stream<ConnectivityInfo> get stream => _streamController.stream;

  @override
  Future onConnectivityChanged(ConnectivityInfo info) async {
    latest = info;
    _streamController.add(info);
  }
}

mixin ConnectivityListener {

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult>? _connectivitySubscription;

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
    final connectivityInfo = await _updateNetworkInfo(result);

    onConnectivityChanged(connectivityInfo);
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
      log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }

    final info =
        ConnectivityInfo(type: result, gatewayIp: wifiGatewayIP ?? "", ssid: wifiName ?? "");

    return info;
  }

  Future onConnectivityChanged(ConnectivityInfo info);
}
