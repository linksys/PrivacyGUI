import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/simple_text_button.dart';
import 'package:linksys_moab/page/components/customs/otp_flow/otp_cubit.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'otp_state.dart';

class OtpCodeInputView extends StatefulWidget {
  const OtpCodeInputView({Key? key}) : super(key: key);

  @override
  _OtpCodeInputViewState createState() => _OtpCodeInputViewState();
}

class _OtpCodeInputViewState extends State<OtpCodeInputView> {
  String _errorCode = '';

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
    _onInit(state.selectedMethod!);
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
          title: state.selectedMethod?.method == OtpMethod.sms
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
                    _errorCode = '';
                  });
                },
                onCompleted: (String? value) => _onNext(value),
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
                  _onSend(state.selectedMethod!)
                      .then((_) => _showCodeResentHint())
                      .onError((error, stackTrace) {
                    logger.e('Error OTP input: $error', stackTrace);
                  });
                  _setLoading(false);
                }),
            if (_errorCode.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  generalErrorCodeHandler(context, _errorCode),
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

  _onNext(String? value) async {
    _setLoading(true);
    await context
        .read<AuthBloc>()
        .authChallengeVerify(value!)
        .then((value) => context.read<OtpCubit>().finish())
        .onError((error, stackTrace) => _handleError(error, stackTrace));
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

  _handleError(Object? e, StackTrace trace) {
    if (e is ErrorResponse) {
      setState(() {
        _errorCode = e.code;
      });
    } else { // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
  }

  _setLoading(bool isLoading) {
    context.read<OtpCubit>().setLoading(isLoading);
  }

  Future<void> _onSend(OtpInfo method) async {
    await context.read<AuthBloc>().authChallenge(method);
  }

  void _onInit(OtpInfo method) {
    context.read<AuthBloc>().add(RequireOtpCode(otpInfo: method));
  }
}
