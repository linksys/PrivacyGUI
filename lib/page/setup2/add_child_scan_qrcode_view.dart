import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/qr_view.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../components/base_components/button/primary_button.dart';
import '../components/base_components/button/simple_text_button.dart';

class AddChildScanQRCodeView extends StatelessWidget {
  const AddChildScanQRCodeView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Scan child node QR code',
          description: 'The code is on the bottom of your child node',
        ),
        content: Center(
          child: Stack(
            children: [
              Container(
                margin: EdgeInsets.only(top: 30),
                width: double.infinity,
                height: 300,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomQRView(
                    onResult: (Barcode code) => _handleScanResult(code),
                  ),
                ),
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
    print('Scanned code: ${code.rawValue ?? ''}');
    onNext();
  }
}
