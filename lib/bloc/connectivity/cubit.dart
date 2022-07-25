import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/connectivity/availability_info.dart';
import 'package:moab_poc/network/http/constant.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../channel/wifi_connect_channel.dart';
import 'connectivity_info.dart';

class ConnectivityCubit extends Cubit<ConnectivityInfo>
    with ConnectivityListener, AvailabilityChecker {
  ConnectivityCubit() : super(const ConnectivityInfo(gatewayIp: '', ssid: ''));
  bool isAndroid9 = false;
  bool isAndroid10AndSupportEasyConnect = false;

  @override
  Future onConnectivityChanged(ConnectivityInfo info) async {
    if (info.type != ConnectivityResult.none) {
      testAvailability().then((value) => emit(info.copyWith(availabilityInfo: value)));
    } else {
      emit(info.copyWith(availabilityInfo: null));
    }
  }

  void forceUpdate() async {
    _checkAndroidVersionAndEasyConnect();
    _updateConnectivity(await _connectivity.checkConnectivity());
  }

  void _checkAndroidVersionAndEasyConnect() async {
    isAndroid9 = await NativeConnectWiFiChannel().isAndroidVersionUnderTen();
    isAndroid10AndSupportEasyConnect = isAndroid9
        ? false
        : await NativeConnectWiFiChannel().isAndroidTenAndSupportEasyConnect();
  }

  @override
  void onChange(Change<ConnectivityInfo> change) {
    super.onChange(change);
    logger.i('Connectivity Cubit change: ${change.currentState.type} -> ${change.nextState.type}');
  }
}

mixin AvailabilityChecker {
  final _client = MoabHttpClient(timeout: 3);

  Future<AvailabilityInfo> testAvailability() async {
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

    final info = ConnectivityInfo(
        type: result, gatewayIp: wifiGatewayIP ?? "", ssid: wifiName ?? "");

    return info;
  }

  Future onConnectivityChanged(ConnectivityInfo info);
}
