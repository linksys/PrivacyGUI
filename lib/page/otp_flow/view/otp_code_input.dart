import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/simple_text_button.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sms_receiver_plugin/sms_receiver_plugin.dart';

class OtpCodeInputView extends ArgumentsStatefulView {
  const OtpCodeInputView({Key? key, super.args, super.next}) : super(key: key);

  @override
  _OtpCodeInputViewState createState() => _OtpCodeInputViewState();
}

class _OtpCodeInputViewState extends State<OtpCodeInputView> {
  String _errorCode = '';
  StreamSubscription? _subscription;
  final TextEditingController _otpController = TextEditingController();

  _startListenOtp() async {
    if (Platform.isAndroid) {
      _subscription = SmsReceiverPlugin().smsReceiverStream.listen((message) {
        logger.d('receive message: $message');
        RegExp regex = RegExp(r"(\d{4})");
        final code = regex.allMatches(message).first.group(0);
        logger.d('receive code: $code');
        _otpController.text = code ?? '';
      });
    }
  }

  @override
  initState() {
    super.initState();
    _startListenOtp();
    final state = context.read<OtpCubit>().state;
    _onInit(state);
  }

  @override
  dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpCubit, OtpState>(
        listener: (context, state) {
          if (state.step == OtpStep.finish) {
            final function = widget.args['function'] ?? OtpFunction.send;
            final next = widget.next ?? UnknownPath();
            if (function == OtpFunction.add) {
              NavigationCubit.of(context).popTo(next);
            } else {
              NavigationCubit.of(context)
                  .clearAndPush(next..args.addAll(widget.args));
            }
          }
        },
        builder: (context, state) => _contentView(state));
  }

  Widget _contentView(OtpState state) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: state.selectedMethod?.method ==
                  CommunicationMethodType.sms.name.toUpperCase()
              ? getAppLocalizations(context).otp_enter_code_sms_title(
                  state.selectedMethod?.targetValue ?? '')
              : getAppLocalizations(context).otp_enter_code_email_title(
                  state.selectedMethod?.targetValue ?? ''),
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
                key: const Key('otp_input_view_input_field_code'),
                onChanged: (String value) {
                  setState(() {
                    _errorCode = '';
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
    final _otpCubit = context.read<OtpCubit>();
    final function = widget.args['function'] ?? OtpFunction.send;

    bool isPassed = await _otpCubit
        .authChallengeVerify(code: value!, token: token)
        .then((value) => true)
        .onError((error, stackTrace) => _handleError(error, stackTrace));
    if (!isPassed) {
      _setLoading(false);
      return;
    }
    if (function == OtpFunction.add) {
      await _otpCubit
          .authChallengeVerifyAccept(value, token)
          .then((value) async =>
              await context.read<AccountCubit>().fetchAccount())
          .onError((error, stackTrace) => _handleError(error, stackTrace));
    }
    context.read<OtpCubit>().finish();
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

  bool _handleError(Object? e, StackTrace trace) {
    if (e is ErrorResponse) {
      setState(() {
        _errorCode = e.code;
      });
    } else {
      // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
    return false;
  }

  _setLoading(bool isLoading) {
    context.read<OtpCubit>().setLoading(isLoading);
  }

  Future<void> _onSend(CommunicationMethod method, String token) async {
    await context.read<OtpCubit>().authChallenge(method: method, token: token);
  }

  void _onInit(OtpState state) async {
    final otpCubit = context.read<OtpCubit>();
    // setting2sv, setting means create account????
    if (state.function == OtpFunction.setting ||
        state.function == OtpFunction.setting2sv) {
      await context.read<AuthBloc>().createAccountPreparationUpdateMethod(
          method: state.selectedMethod!, token: state.token);
    }
    // Require otp code
    // authBloc.add(RequireOtpCode(communicationMethod: state.selectedMethod!));
    // TODO if is create account, do create account preparation first
    otpCubit.authChallenge(method: state.selectedMethod!, token: state.token);
  }
}
