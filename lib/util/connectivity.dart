import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/bloc/connectivity/connectivity_info.dart';
import 'package:moab_poc/packages/openwrt/model/identity.dart';
import 'package:network_info_plus/network_info_plus.dart';

@Deprecated('See Connectivity Cubit')
class ConnectivityUtil {
  static Identity? identity;
  static ConnectivityInfo latest =
      const ConnectivityInfo(gatewayIp: '', ssid: '');
  static final StreamController<ConnectivityInfo> _streamController = StreamController();
  static Stream<ConnectivityInfo> get stream => _streamController.stream;

  Future onConnectivityChanged(ConnectivityInfo info) async {
    latest = info;
    _streamController.add(info);
  }
}
