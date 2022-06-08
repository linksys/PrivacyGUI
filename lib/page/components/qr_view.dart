import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef OnResultScanned = Function(Barcode barcode);

class CustomQRView extends StatefulWidget {
  final OnResultScanned? onResult;

  const CustomQRView({
    Key? key,
    this.onResult,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<CustomQRView> {
  Barcode? result;
  MobileScannerController? controller =
      MobileScannerController(facing: CameraFacing.front, torchEnabled: true);
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QRCode');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    // return QRView(
    //   key: qrKey,
    //   onQRViewCreated: _onQRViewCreated,
    //   overlay: widget.overlay,
    //   onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    // );
    return MobileScanner(
        allowDuplicates: false,
        controller: controller,
        onDetect: (barcode, args) {
          if (barcode.rawValue == null) {
            debugPrint('Failed to scan Barcode');
          } else {
            debugPrint('Barcode found: ${barcode.toString()}');
          }
          widget.onResult?.call(barcode);
        });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
