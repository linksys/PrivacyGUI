import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/test_repository/local_test_repository.dart';
import 'package:moab_poc/page/landing_page/event.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'state.dart';

enum LandingStatus {
  unknown,
  initialize,
  connected,
  notConnected,
  scan,
  scanResult,
  loading
}

class LandingBloc extends Bloc<LandingEvent, LandingState> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final _networkInfo = NetworkInfo();

  LandingBloc() : super(const LandingState.init()) {
    on<Initial>(_init);
    on<CheckingConnection>(_checkConnection);
    on<ScanQrCode>(_scanQRCode);

    add(Initial());
  }

  FutureOr<void> _checkConnection(
      LandingEvent event, Emitter<LandingState> emit) async {
    final info = await _updateNetworkInfo();
    String ip = info['ip'] ?? "";
    String ssid = info['name'] ?? "";
    final repo =
        LocalTestRepository(OpenWRTClient(Device(port: '80', address: ip)));
    bool isConnect = await repo.test();
    log('_checkConnection: $isConnect, $ip, $ssid');
    return emit(LandingState.connectionChanged(
        ip: ip, ssid: ssid, isConnected: ssid == 'ASUS_HAO'));
  }

  FutureOr<void> _scanQRCode(LandingEvent event, Emitter<LandingState> emit) {
    emit(const LandingState.scan());
  }

  FutureOr<void> _init(LandingEvent event, Emitter<LandingState> emit) {
    return _checkConnection(event, emit);
  }

  Future<Map<String, String>> _updateNetworkInfo() async {
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

    // emit?
    // setState(() {
    //   _wifiName = wifiName ?? "";
    //   _gatewayIp = wifiGatewayIP ?? "";
    // });
    return {'name': wifiName ?? "", 'ip': wifiGatewayIP ?? ""};
  }
}
