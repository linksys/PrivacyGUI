import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpView extends StatefulWidget {
  const OtpView({
    Key? key,
    required this.destination,
    required this.onNext,
  }) : super(key: key);

  final String destination;
  final void Function() onNext;

  @override
  _OtpViewState createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  static const otpChannel = MethodChannel('com.linksys.native.channel.otp');
  final TextEditingController _otpController = TextEditingController();

  _startListenOtp() async {
    if (Platform.isAndroid) {
      final message = await otpChannel.invokeMethod('otp');
      print('receive message: $message');
      RegExp regex = RegExp(r"(\d{4})");
      final code = regex.allMatches(message).first.group(0);
      print('receive code: $code');
      _otpController.text = code ?? '';
    }
  }

  @override
  initState() {
    super.initState();
    _startListenOtp();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: widget.destination.isValidEmailFormat()
              ? 'Enter the code we sent to ${widget.destination}'
              : 'Enter the code we texted to ${widget.destination}',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 61,
            ),
            SizedBox(
              width: 242,
              child: PinCodeTextField(
                onChanged: (String value) {
                  setState(() {});
                },
                length: 4,
                appContext: context,
                controller: _otpController,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                    shape: PinCodeFieldShape.underline,
                    fieldHeight: 46,
                    fieldWidth: 48,
                    activeFillColor: Colors.transparent,
                    inactiveFillColor: Colors.transparent,
                    selectedFillColor: Colors.transparent,
                    inactiveColor: Colors.white),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            SimpleTextButton(text: 'Resend code', onPressed: () {}),
            const SizedBox(
              height: 41,
            ),
            Visibility(
                visible: _otpController.text.isNotEmpty,
                child: PrimaryButton(
                  text: 'Next',
                  onPress: widget.onNext,
                )),
          ],
        ),
      ),
    );
  }
}
