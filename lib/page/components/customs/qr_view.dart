import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef OnResultScanned = Function(Barcode barcode);

class CustomQRView extends ConsumerStatefulWidget {
  final OnResultScanned? onResult;

  const CustomQRView({
    Key? key,
    this.onResult,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends ConsumerState<CustomQRView> {
  Barcode? result;
  MobileScannerController? controller =
      MobileScannerController(facing: CameraFacing.back, torchEnabled: false);
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
    // we need to listen for Flutter SizeChanged notification and update controllerSetupParentQrCodeScanPath
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
            debugPrint('Barcode found: ${barcode.rawValue}');
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
