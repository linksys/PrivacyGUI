import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/page/poc/login/view.dart';
import 'package:moab_poc/util/permission.dart';
import 'package:moab_poc/util/wifi_credential.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../channel/wifi_connect_channel.dart';
import '../../../util/connectivity.dart';
import '../../components/customs/qr_view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class LandingView extends StatefulWidget {
  const LandingView({Key? key}) : super(key: key);

  @override
  State<LandingView> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingView> with Permissions {
  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initConnectivity() async {
    await checkLocationPermissions().then((value) {
      BlocProvider.of<LandingBloc>(context).startListen();
      if (!value) {
        openAppSettings();
      } else {
        BlocProvider.of<LandingBloc>(context).startListen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LandingBloc, LandingState>(
      listenWhen: (context, state) {
        return state.isConnectToDevice;
      },
      listener: (context, state) {
        if (state.isConnectToDevice) {
          Navigator.popAndPushNamed(context, LoginPage.routeName,
              arguments: {'ip': state.gatewayIp, 'ssid': state.ssid});
        }
      },
      builder: (context, state) {
        return Scaffold(
          // appBar: AppBar(),
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
      child = Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: BackButton(
              onPressed: () =>
                  context.read<LandingBloc>().add(StopScanningQrCode())),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: CustomQRView(onResult: (code) async {
          log('QR: onFinish: ${code.rawValue}');
          final creds = WiFiCredential.parse(code.rawValue ?? "");
          log('Parsed WiFI: ${creds.ssid}, ${creds.password}');
          await NativeConnectWiFiChannel()
              .connectToWiFi(ssid:creds.ssid, password: creds.password);
        }),
      );
    } else {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('You are not connecting to a Kauai device!'),
          Text("SSID: ${state.ssid.isEmpty ? 'unknown' : state.ssid}"),
          const SizedBox(
            height: 32,
          ),
          ElevatedButton(
              onPressed: () {
                if (Platform.isAndroid) {
                  NativeConnectWiFiChannel().connectToWiFi(ssid: '', password: '');
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
