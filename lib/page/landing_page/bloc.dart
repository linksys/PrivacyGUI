import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/test_repository/local_test_repository.dart';
import 'package:moab_poc/page/landing_page/event.dart';
import 'package:moab_poc/util/connectivity.dart';

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

class LandingBloc extends Bloc<LandingEvent, LandingState>
    with ConnectivityListener {
  LandingBloc() : super(const LandingState.init()) {
    on<Initial>(_init);
    on<CheckingConnection>(_checkConnection);
    on<ScanQrCode>(_scanQRCode);

    add(Initial());
  }

  @override
  Future<void> close() async {
    stop();
    return super.close();
  }

  FutureOr<void> _checkConnection(
      LandingEvent event, Emitter<LandingState> emit) async {
    String ip = connectivityInfo.gatewayIp;
    String ssid = connectivityInfo.ssid;
    final repo =
        LocalTestRepository(OpenWRTClient(Device(port: '80', address: ip)));
    bool isConnect = await repo.test();
    log('_checkConnection: $isConnect, $ip, $ssid');
    return emit(LandingState.connectionChanged(
        ip: ip, ssid: ssid, isConnected: isConnect));
  }

  FutureOr<void> _scanQRCode(LandingEvent event, Emitter<LandingState> emit) {
    emit(const LandingState.scan());
  }

  FutureOr<void> _init(LandingEvent event, Emitter<LandingState> emit) {
    return _checkConnection(event, emit);
  }

  @override
  Future onConnectivityChanged(
      ConnectivityResult result, ConnectivityInfo info) async {
    log("onConnectivityChanged:: $result, $info");
    add(CheckingConnection());
  }
}
