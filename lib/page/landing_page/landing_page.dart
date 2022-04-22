import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/page/login/view.dart';
import 'package:moab_poc/util/permission.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../channel/wifi_connect_channel.dart';
import '../components/qr_view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class LandingView extends StatefulWidget {
  const LandingView({Key? key}) : super(key: key);

  @override
  State<LandingView> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingView> with Permissions {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();

    BlocProvider.of<LandingBloc>(context);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initConnectivity() async {
    final permission = await checkLocationPermissions();
    if (!permission) {
      openAppSettings();
      return;
    }

    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      log('Couldn\'t check connectivity status', error: e);
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    _updateConnectionStatus(result);
  }

  _updateConnectionStatus(ConnectivityResult result) async {
    context.read<LandingBloc>().add(CheckingConnection());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LandingBloc, LandingState>(
      listenWhen: (context, state) {
        return state.isConnectToDevice;
      },
      listener: (context, state) {
        if (state.isConnectToDevice) {
          Navigator.pushNamed(context, LoginPage.routeName,
              arguments: {'ip': state.gatewayIp, 'ssid': state.ssid});
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: _buildContent(context, state),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, LandingState state) {
    late Widget child;
    if (state.isConnectToDevice) {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          Text('You are already connected...'),
        ],
      );
    } else if (state.scanning) {
      child = CustomQRView(callback: (code) {
        log('QR code: ${code.code}');
      }, onFinish: (code) async {
        log('QR: onFinish: ${code.code}');
        final token = code.code!.split(';');
        final ssid = token[1].replaceAll('S:', '');
        final password = token[2].replaceAll('P:', '');
        log('Parsed WiFI: $ssid, $password');
        await NativeConnectWiFiChannel().connectToWiFi(ssid, password);
      });
    } else {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('You are not connect to a Kauai device!'),
          Text("SSID: ${state.ssid.isEmpty ? 'unknown' : state.ssid}"),
          const SizedBox(
            height: 32,
          ),
          ElevatedButton(
              onPressed: () {
                if (Platform.isAndroid) {
                  NativeConnectWiFiChannel().connectToWiFi('', '');
                } else {
                  context.read<LandingBloc>().add(ScanQrCode());
                }
              },
              child: const Text('Connect'))
        ],
      );
    }
    return child;
  }
}
