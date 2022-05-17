import 'package:flutter/material.dart';
import 'package:moab_poc/design/colors.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/qr_view.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../components/base_components/button/primary_button.dart';
import '../components/base_components/button/simple_text_button.dart';

class ParentScanQRCodeView extends StatelessWidget {
  const ParentScanQRCodeView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Scan QR code',
          description: 'The code is on the bottom of your node',
        ),
        content: Center(
          child: Stack(
            children: [
              CustomQRView(
                callback: (Barcode code) => _handleScanResult,
                overlay: QrScannerOverlayShape(
                    borderColor: MoabColor.scannerBoarder,
                    borderRadius: 0,
                    borderLength: 100,
                    borderWidth: 2,
                    cutOutSize: 200,
                    overlayColor: Theme.of(context).backgroundColor,
                    cutOutBottomOffset: 120),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 200, 0, 0), // TODO
                child: Center(
                  child: SimpleTextButton(
                      text: 'Use a different method',
                      onPressed: () {
                        //TODO: onPressed Action
                      }),
                ),
              )
            ],
          ),
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: 'Next',
              onPress: onNext,
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }

  _handleScanResult(Barcode code) {
    print('Scanned code: ${code.code ?? ''}');
    onNext();
  }
}
