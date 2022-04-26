import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:moab_poc/page/mesh/spinner_page.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../components/qr_view.dart';

class AddChildPage extends StatelessWidget {
  const AddChildPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   leading: BackButton(
      //     onPressed: () => Navigator.pop(context),
      //   ),
      // ),
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

class _QRCodeScannerState extends State<QRCodeScanner> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const SpinnerPage()
        : CustomQRView(
            onFinish: handleScannerResult,
          );
  }

  void handleScannerResult(Barcode result) {
    if (result.code != null) {
      // TODO: Parse boostrap and send it to parent
      log('QR code result: ' + result.code.toString());
      startAddChild();
    }
    setState(() {
      isLoading = true;
    });
  }

  Future<void> startAddChild() async {
    // TODO: Send info to parent
    await Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        isLoading = false;
      });
      Navigator.pop(context);
    });
  }
}
