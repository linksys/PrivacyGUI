import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/page/mesh/event.dart';
import 'package:moab_poc/page/mesh/mesh.dart';
import 'package:moab_poc/page/mesh/spinner_page.dart';
import 'package:moab_poc/util/permission.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../components/qr_view.dart';

class MeshView extends StatelessWidget {
  const MeshView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const QRCodeScanner(),
    );
  }
}

class QRCodeScanner extends StatefulWidget {
  const QRCodeScanner({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _QRCodeScannerState();
  }
}

class _QRCodeScannerState extends State<QRCodeScanner> with Permissions {

  @override
  void initState() {
    super.initState();
    _initCameraPermission();
    _initMeshStatus();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initCameraPermission() async {
    await checkCameraPermissions().then((value) {
      if (!value) {
        openAppSettings();
      }
    });
  }

  Future<void> _initMeshStatus() async {
    context.read<MeshBloc>().add(const StartMesh());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MeshBloc, MeshState>(
      listener: (context, state) {
        if (state.runtimeType == MeshComplete) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        switch (state.runtimeType) {
          case MeshLoading:
            return const SpinnerPage();
          case QRCodeScanner:
            return CustomQRView(onResult: handleScannerResult);
          default:
            return Container();
        }
      },
    );
  }

  void handleScannerResult(Barcode result) {
    if (result.rawValue != null) {
      log('QR code result: ' + result.rawValue!);
      var dpp = parseDpp(result.rawValue!);
      context.read<MeshBloc>().add(SyncDPPWithChild(dpp: dpp));
    }
  }

  String parseDpp(String code) {
    // TODO: Parse boostrap
    return code;
  }
}
