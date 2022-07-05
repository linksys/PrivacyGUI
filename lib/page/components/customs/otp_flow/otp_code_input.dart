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
import 'package:moab_poc/page/components/customs/otp_flow/otp_cubit.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/route/route.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'otp_state.dart';

class OtpCodeInputView extends StatefulWidget {
  const OtpCodeInputView({Key? key, required this.nextPath}) : super(key: key);

  final BasePath nextPath;

  @override
  _OtpCodeInputViewState createState() => _OtpCodeInputViewState();
}

class _OtpCodeInputViewState extends State<OtpCodeInputView> {

  String _errorReason = '';

  static const otpChannel = MethodChannel('com.linksys.native.channel.otp');
  final TextEditingController _otpController = TextEditingController();

  _startListenOtp() async {
    if (Platform.isAndroid) {
      final message = await otpChannel.invokeMethod('otp');
      print('receive message: $message');
      RegExp regex = RegExp(r"(\d{4})");
      final code = regex
          .allMatches(message)
          .first
          .group(0);
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
    return BlocBuilder<OtpCubit, OtpState>(
      builder: (context, state) => _contentView(state)
    );
  }

  Widget _contentView(OtpState state) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: state.selectedMethod?.method == OtpMethod.email
              ? 'Enter the code we sent to ${state.selectedMethod?.data}'
              : 'Enter the code we texted to ${state.selectedMethod?.data}',
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
                  setState(() {
                    _errorReason = '';
                  });
                },
                onCompleted: (String? value) => _onNext(value, state.token),
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
                  _setLoading(true);
                  context
                      .read<AuthBloc>()
                      .resendCode(state.token, state.selectedMethod?.method.name ?? '')
                      .then((value) => _showCodeResentHint())
                      .onError((error, stackTrace) =>
                      _handleError(error as CloudException));
                  _setLoading(false);
                }),
            if (_errorReason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  _errorReason,
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(color: Colors.red),
                ),
              ),
            const SizedBox(
              height: 41,
            ),
          ],
        ),
      ),
    );
  }

  _onNext(String? value, String token) async {
    _setLoading(true);
    await context
        .read<AuthBloc>()
        .validPasswordLess(value!, token)
        .then((value) => NavigationCubit.of(context).replace(widget.nextPath))
        .onError((error, stackTrace) => _handleError(error as CloudException));
    _setLoading(false);
  }

  _showCodeResentHint() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Wrap(alignment: WrapAlignment.center, children: [
        Icon(
          Icons.check,
          color: Theme
              .of(context)
              .primaryColor,
        ),
        const Text('Code resent!')
      ]),
      duration: const Duration(seconds: 5),
    ));
  }

  _handleError(CloudException exception) {
    if (exception.code == 'RESEND_CODE_TIMER') {
      setState(() {
        _errorReason = exception.message;
      });
    } else if (exception.code == 'OTP_INVALID_TOO_MANY_TIMES') {
      setState(() {
        _errorReason = exception.message;
      });
    }
  }

  _setLoading(bool isLoading) {
    context.read<OtpCubit>().setLoading(isLoading);
  }
}
