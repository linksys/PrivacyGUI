import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/event.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_cubit.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'otp_state.dart';

class OtpCodeInputView extends StatefulWidget {
  const OtpCodeInputView({Key? key}) : super(key: key);

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
      final code = regex.allMatches(message).first.group(0);
      print('receive code: $code');
      _otpController.text = code ?? '';
    }
  }

  @override
  initState() {
    super.initState();
    _startListenOtp();
    final state = context.read<OtpCubit>().state;
    _onSend(state.selectedMethod!, state.token);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
        builder: (context, state) => _contentView(state));
  }

  Widget _contentView(OtpState state) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: state.selectedMethod?.method == OtpMethod.email
              ? getAppLocalizations(context)
                  .otp_enter_code_sms_title(state.selectedMethod?.data ?? '')
              : getAppLocalizations(context)
                  .otp_enter_code_email_title(state.selectedMethod?.data ?? ''),
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
                text: getAppLocalizations(context).otp_resend_code,
                onPressed: () {
                  _setLoading(true);
                  _onSend(state.selectedMethod!, state.token)
                      .then((_) => _showCodeResentHint())
                      .onError((error, stackTrace) {
                    logger.e('Error OTP input: $error', stackTrace);
                  });
                  _setLoading(false);
                }),
            if (_errorReason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  _errorReason,
                  style: Theme.of(context)
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
        .authChallengeVerify(token, value!)
        .then((value) => context.read<OtpCubit>().finish())
        .onError((error, stackTrace) {
      logger.e('error otp: $error', stackTrace);
    });
    _setLoading(false);
  }

  _showCodeResentHint() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Wrap(alignment: WrapAlignment.center, children: [
        Icon(
          Icons.check,
          color: Theme.of(context).primaryColor,
        ),
        Text(getAppLocalizations(context).otp_code_resent)
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

  Future<void> _onSend(OtpInfo method, String token) async {
    await context.read<AuthBloc>().authChallenge(method, token);
  }
}
