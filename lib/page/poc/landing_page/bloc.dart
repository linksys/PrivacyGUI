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

class LandingBloc extends Bloc<LandingEvent, LandingState> {
  StreamSubscription? _streamSubscription;
  
  LandingBloc() : super(const LandingState.init()) {
    on<Initial>(_init);
    on<CheckingConnection>(_checkConnection);
    on<ScanQrCode>(_scanQRCode);
    on<StopScanningQrCode>(_stopScanningQRCode);

    add(Initial());
  }

  void startListen() {
    _streamSubscription = ConnectivityUtil.stream.listen((info) {
      add(CheckingConnection(info: info));
    });
  }

  @override
  Future<void> close() async {
    _streamSubscription?.cancel();
    return super.close();
  }

  FutureOr<void> _checkConnection(
      CheckingConnection event, Emitter<LandingState> emit) async {
    String ip = event.info.gatewayIp;
    String ssid = event.info.ssid;
    if (ip.isEmpty) {
      return;
    }
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

  FutureOr<void> _stopScanningQRCode(
      LandingEvent event, Emitter<LandingState> emit) {
    emit(const LandingState.stopScanning());
  }

  FutureOr<void> _init(LandingEvent event, Emitter<LandingState> emit) {
    return _checkConnection(CheckingConnection(info: ConnectivityUtil.latest), emit);
  }

  @override
  void onChange(Change<LandingState> change) {
    super.onChange(change);
    print('Landing: $change');
  }
}
