
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'connectivity_info.dart';

class ConnectivityCubit extends Cubit<ConnectivityInfo> with ConnectivityListener {

  ConnectivityCubit(): super(const ConnectivityInfo(gatewayIp: '', ssid: ''));

  @override
  Future onConnectivityChanged(ConnectivityInfo info) async {
    emit(info);
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
      logger.e('Failed to get Wifi Name', e);
      wifiName = 'Unknown SSID';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      logger.e('Failed to get Wifi gateway address', e);
      wifiGatewayIP = 'Unknown Gateway IP';
    }

    final info =
    ConnectivityInfo(type: result, gatewayIp: wifiGatewayIP ?? "", ssid: wifiName ?? "");

    return info;
  }

  Future onConnectivityChanged(ConnectivityInfo info);
}