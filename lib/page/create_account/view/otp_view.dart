import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpView extends ArgumentsStatefulView {
  const OtpView(
      {Key? key, super.args})
      : super(key: key);

  @override
  _OtpViewState createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  bool _isLoading = false;
  late OtpInfo _dest;
  late String _token;
  late BasePath _nextPath;
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
    _dest = widget.args!['dest'] as OtpInfo;
    _token = widget.args!['token'] as String;
    _nextPath = widget.args!['onNext'] as BasePath;
    _startListenOtp();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => _isLoading
          ? const FullScreenSpinner(text: 'processing...')
          : _contentView(),
    );
  }

  Widget _contentView() {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: _dest.method == OtpMethod.email
              ? 'Enter the code we sent to ${_dest.data}'
              : 'Enter the code we texted to ${_dest.data}',
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
            SimpleTextButton(
                text: 'Resend code',
                onPressed: () {
                  context
                      .read<AuthBloc>()
                      .resendCode(_token, _dest.method.name);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Wrap(children: [
                      Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                      ),
                      const Text('Code resent!')
                    ]),
                    duration: const Duration(seconds: 5),
                  ));
                }),
            const SizedBox(
              height: 41,
            ),
            Visibility(
                visible: _otpController.text.isNotEmpty,
                child: PrimaryButton(
                  text: 'Next',
                  onPress: () {
                    NavigationCubit.of(context).push(_nextPath);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
