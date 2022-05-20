import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../components/base_components/button/primary_button.dart';
import '../components/base_components/button/simple_text_button.dart';
import '../components/layouts/basic_header.dart';
import '../components/layouts/basic_layout.dart';

class LoginCloudAccountWithOtpView extends StatefulWidget {
  const LoginCloudAccountWithOtpView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  _LoginCloudAccountWithOtpState createState() =>
      _LoginCloudAccountWithOtpState();
}

class _LoginCloudAccountWithOtpState
    extends State<LoginCloudAccountWithOtpView> {
  bool isValidWifiInfo = false;
  String otpCode = '';
  static const otpChannel = MethodChannel('com.linksys.native.channel.otp');

  final TextEditingController _otpController = TextEditingController();

  void _checkFilledInfo(_) {
    setState(() {
      isValidWifiInfo = _otpController.text.isNotEmpty;
    });
  }

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
          header: const BasicHeader(
            title: 'Log in',
            description: 'Enter the code we sent over SMS to (xxx)xxx-xxxx',
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 36.0,
                    ),
                    child: PinCodeTextField(
                      appContext: context,
                      // pastedTextStyle: TextStyle(
                      //   color: Colors.green.shade600,
                      //   fontWeight: FontWeight.bold,
                      // ),
                      length: 4,
                      animationType: AnimationType.fade,
                      validator: (v) {
                        if (v!.length < 3) {
                          return "I'm from validator";
                        } else {
                          return null;
                        }
                      },
                      pinTheme: PinTheme(
                          shape: PinCodeFieldShape.underline,
                          fieldHeight: 50,
                          fieldWidth: 60,
                          activeFillColor: Colors.transparent,
                          inactiveFillColor: Colors.transparent,
                          selectedFillColor: Colors.transparent,
                          inactiveColor: Colors.white),
                      cursorColor: Colors.black,
                      animationDuration: const Duration(milliseconds: 300),
                      enableActiveFill: true,
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      boxShadows: const [
                        BoxShadow(
                          offset: Offset(0, 1),
                          color: Colors.black12,
                          blurRadius: 10,
                        )
                      ],
                      onCompleted: (v) {
                        debugPrint("Completed");
                      },
                      // onTap: () {
                      //   print("Pressed");
                      // },
                      onChanged: (value) {
                        debugPrint(value);
                        setState(() {
                          // currentText = value;
                        });
                      },
                      beforeTextPaste: (text) {
                        debugPrint("Allowing to paste $text");
                        //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                        //but you can show anything you want here, like your pop up saying wrong paste format or etc
                        return true;
                      },
                    )),
              ),
              SimpleTextButton(text: 'Resend code', onPressed: () {}),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: PrimaryButton(
                  text: 'Next',
                  onPress: widget.onNext,
                ),
              ),
              const Spacer(),
            ],
          ),
          alignment: CrossAxisAlignment.start,
        ));
  }
}
