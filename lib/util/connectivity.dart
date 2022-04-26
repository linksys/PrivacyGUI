import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/packages/openwrt/model/identity.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ConnectivityInfo {
  const ConnectivityInfo({required this.gatewayIp, required this.ssid});

  final String gatewayIp;
  final String ssid;
}

class ConnectivityUtil {
  static Identity? identity;
  static ConnectivityInfo info =
      const ConnectivityInfo(gatewayIp: '', ssid: '');

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

    info =
        ConnectivityInfo(gatewayIp: wifiGatewayIP ?? "", ssid: wifiName ?? "");

    return info;
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

enum SecurityType { wpa, wep, none }

class WiFiCredential {
  const WiFiCredential._(
      {this.ssid = '',
      this.password = '',
      this.type = SecurityType.none,
      this.isHidden = false});

  factory WiFiCredential.parse(String raw) {
    String ssid = '', password = '';
    bool isHidden = false;
    SecurityType type = SecurityType.none;

    RegExp regex =
        RegExp(r"([(?=S|T|P|H):]{1}:[\S\s]*?(?=;T:|;H:|;P:|;S:|;;$))");
    regex.allMatches(raw).forEach((element) {
      final data = element.group(0) ?? "";
      print(data);
      RegExp regex = RegExp(r"([(?=S|T|P|H):]{1}):([\S\s]*)");
      regex.allMatches(data).forEach((element) {
        switch (element.group(1)) {
          case 'S':
            ssid = element.group(2) ?? '';
            break;
          case 'T':
            type = SecurityType.values.firstWhere(
                (e) => e.toString() == (element.group(2) ?? 'none'),
                orElse: () => SecurityType.none);
            break;
          case 'P':
            password = element.group(2) ?? '';
            break;
          case 'H':
            isHidden = (element.group(2) ?? '') == 'true';
            break;
        }
      });
    });

    return WiFiCredential._(
        ssid: ssid, password: password, type: type, isHidden: isHidden);
  }

  WiFiCredential copyWith(
      {String? ssid, String? password, bool? isHidden, SecurityType? type}) {
    return WiFiCredential._(
        ssid: ssid ?? this.ssid,
        password: password ?? this.password,
        isHidden: isHidden ?? this.isHidden,
        type: type ?? this.type);
  }

  final String ssid;
  final String password;
  final SecurityType type;
  final bool isHidden;
}
