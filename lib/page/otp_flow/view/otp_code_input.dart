import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/repository/model/cloud_session_model.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:sms_receiver_plugin/sms_receiver_plugin.dart';

class OtpCodeInputView extends ArgumentsStatefulView {
  const OtpCodeInputView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<OtpCodeInputView> createState() => _OtpCodeInputViewState();
}

class _OtpCodeInputViewState extends State<OtpCodeInputView> {
  String _errorCode = '';
  StreamSubscription? _subscription;
  late final TextEditingController _otpController;
  bool _rememberMe = false;
  SessionToken? _sessionToken; // for mfa login

  _startListenOtp() async {
    if (Platform.isAndroid) {
      _subscription = SmsReceiverPlugin().smsReceiverStream.listen((message) {
        logger.d('receive message: $message');
        RegExp regex = RegExp(r"(\d{6})");
        final code = regex.allMatches(message).first.group(0);
        logger.d('receive code: $code');
        _otpController.text = code ?? '';
      });
    }
  }

  @override
  initState() {
    super.initState();
    _otpController = TextEditingController();
    _startListenOtp();
    final state = context.read<OtpCubit>().state;
    _onInit(state);
  }

  @override
  dispose() {
    super.dispose();
    _subscription?.cancel();
    _otpController.dispose();
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
              final token = _sessionToken;
              if (token == null) {
                return;
              }
              final password = widget.args['password'] ?? '';
              context.read<AuthBloc>().add(CloudLogin(
                    sessionToken: token,
                    password: password,
                  ));
              // NavigationCubit.of(context)
              //     .clearAndPush(next..args.addAll(widget.args));
            }
          }
        },
        builder: (context, state) => state.isLoading
            ? const LinksysFullScreenSpinner()
            : _contentView(state));
  }

  Widget _contentView(OtpState state) {
    return StyledLinksysPageView(
      scrollable: true,
      child: LinksysBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: LinksysText.screenName(
          state.selectedMethod?.method ==
                  CommunicationMethodType.sms.name.toUpperCase()
              ? getAppLocalizations(context)
                  .otp_enter_code_sms_title(state.selectedMethod?.target ?? '')
              : getAppLocalizations(context).otp_enter_code_email_title(
                  state.selectedMethod?.target ?? ''),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LinksysGap.big(),
            AppPinCodeInput(
              key: const Key('otp_input_view_input_field_code'),
              onChanged: (String value) {
                setState(() {
                  _errorCode = '';
                });
              },
              // onCompleted: (String? value) => _onNext(value, state.token),
              length: 6,
              controller: _otpController,
            ),
            AppCheckbox(
              value: _rememberMe,
              text: 'Don\'t challenge on the next 30 days.',
              onChanged: (_) {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
            ),
            const LinksysGap.regular(),
            LinksysTertiaryButton.noPadding(
                getAppLocalizations(context).otp_resend_code, onTap: () {
              _setLoading(true);
              _onSend(state.selectedMethod!, state.token)
                  .then((_) => _showCodeResentHint())
                  .onError((error, stackTrace) {
                logger.e('Error OTP input: $error', stackTrace);
              });
              _setLoading(false);
            }),
            if (_errorCode.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: LinksysText.flavorText(
                  generalErrorCodeHandler(context, _errorCode),
                ),
              ),
            const Spacer(),
            LinksysPrimaryButton(
              'Next',
              onTap: _otpController.text.length >= 6
                  ? () {
                      _onNext(_otpController.text, state.token);
                    }
                  : null,
            )
          ],
        ),
      ),
    );
  }

  _onNext(String? value, String token) async {
    final code = value;
    if (code == null) {
      return;
    }
    _setLoading(true);
    final otpCubit = context.read<OtpCubit>();
    final function = widget.args['function'] ?? OtpFunction.send;

    _sessionToken = await otpCubit
        .authChallengeVerify(code: code, token: token)
        .onError((error, stackTrace) => _handleError(error, stackTrace));
    if (function == OtpFunction.add) {
      await otpCubit
          .authChallengeVerifyAccept(code, token)
          .then((value) async =>
              await context.read<AccountCubit>().fetchAccount())
          .onError((error, stackTrace) => _handleError(error, stackTrace));
    }
    otpCubit.finish();
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
    } else {
      // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
  }

  _setLoading(bool isLoading) {
    context.read<OtpCubit>().setLoading(isLoading);
  }

  Future<void> _onSend(CommunicationMethod method, String token) async {
    await context.read<OtpCubit>().authChallenge(method: method, token: token);
  }

  void _onInit(OtpState state) async {
    final otpCubit = context.read<OtpCubit>();
    // // setting2sv, setting means create account????
    // if (state.function == OtpFunction.setting ||
    //     state.function == OtpFunction.setting2sv) {
    //   await context.read<AuthBloc>().createAccountPreparationUpdateMethod(
    //       method: state.selectedMethod!, token: state.token);
    // }
    // // Require otp code
    // // authBloc.add(RequireOtpCode(communicationMethod: state.selectedMethod!));
    // // TODO if is create account, do create account preparation first
    otpCubit.authChallenge(method: state.selectedMethod!, token: state.token);
  }
}
