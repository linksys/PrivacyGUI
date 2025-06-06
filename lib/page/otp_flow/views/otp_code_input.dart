import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/cloud_communication_method.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../providers/_providers.dart';

class OtpCodeInputView extends ArgumentsConsumerStatefulView {
  const OtpCodeInputView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<OtpCodeInputView> createState() => _OtpCodeInputViewState();
}

class _OtpCodeInputViewState extends ConsumerState<OtpCodeInputView> {
  String _errorCode = '';
  StreamSubscription? _subscription;
  late final TextEditingController _otpController;
  bool _rememberMe = false;
  SessionToken? _sessionToken; // for mfa login
  bool isAdd = false;
  // _startListenOtp() async {
  //   if (Platform.isAndroid) {
  //     _subscription = SmsReceiverPlugin().smsReceiverStream.listen((message) {
  //       logger.d('receive message: $message');
  //       RegExp regex = RegExp(r"(\d{6})");
  //       final code = regex.allMatches(message).first.group(0);
  //       logger.d('receive code: $code');
  //       _otpController.text = code ?? '';
  //     });
  //   }
  // }

  @override
  initState() {
    super.initState();
    _otpController = TextEditingController();
    // _startListenOtp();
    final state = ref.read(otpProvider);
    _onInit(state);
    isAdd = widget.args['function'] == 'add';
  }

  @override
  dispose() {
    super.dispose();
    _subscription?.cancel();
    _otpController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpProvider);
    ref.listen(otpProvider.select((value) => value.step), (previous, next) {
      final backPath = widget.args['backPath'];
      if (next == OtpStep.finish && backPath != null) {
        context.go(widget.args['backPath']);
      }
    });
    return state.isLoading ? const AppFullScreenSpinner() : _contentView(state);
  }

  Widget _contentView(OtpState state) {
    return StyledAppPageView(
      scrollable: true,
      onBackTap: () {
        // ref.read(otpProvider.notifier).processBack();
        context.pop();
      },
      child: (context, constraints) => AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: AppText.titleLarge(
          state.selectedMethod?.method ==
                  CommunicationMethodType.sms.name.toUpperCase()
              ? loc(context)
                  .otpEnterCodeSmsTitle(state.selectedMethod?.target ?? '')
              : loc(context)
                  .otpEnterCodeEmailTitle(state.selectedMethod?.target ?? ''),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large3(),
            AppPinCodeInput(
              key: const Key('otp_input_view_input_field_code'),
              semanticLabel: 'pin code input field',
              onChanged: (String value) {
                setState(() {
                  _errorCode = '';
                });
              },
              // onCompleted: (String? value) => _onNext(value, state.token),
              length: 6,
              controller: _otpController,
            ),
            if (!isAdd)
              AppCheckbox(
                value: _rememberMe,
                text: 'Don\'t challenge on the next 30 days.',
                onChanged: (_) {
                  setState(() {
                    _rememberMe = !_rememberMe;
                  });
                },
              ),
            const AppGap.medium(),
            AppTextButton.noPadding(loc(context).resendCode, onTap: () {
              _setLoading(true);
              _onSend(state.selectedMethod!, state.token)
                  .then((_) => _showCodeResentHint())
                  .onError((error, stackTrace) {
                logger.e('Error OTP input: $error', stackTrace: stackTrace);
              });
              _setLoading(false);
            }),
            if (_errorCode.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: AppText.headlineMedium(
                  errorCodeHelper(context, _errorCode) ?? '',
                ),
              ),
            const Spacer(),
            AppFilledButton.fillWidth(
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
    logger.d('YOUR OTP Code is $value');
    await ref
        .read(otpProvider.notifier)
        .mfaVerify(code: code, token: token)
        .onError((error, stackTrace) => _handleError(error, stackTrace))
        .whenComplete(() {
      _setLoading(false);
    });
    _setLoading(false);
  }

  _showCodeResentHint() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Wrap(alignment: WrapAlignment.center, children: [
        Icon(
          LinksysIcons.check,
          color: Theme.of(context).primaryColor,
        ),
        Text(loc(context).otpCodeResent)
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
    ref.read(otpProvider.notifier).setLoading(isLoading);
  }

  Future<void> _onSend(CommunicationMethod method, String token) async {
    await ref
        .read(otpProvider.notifier)
        .mfaChallenge(method: method, token: token);
  }

  void _onInit(OtpState state) async {
    // // setting2sv, setting means create account????
    // if (state.function == OtpFunction.setting ||
    //     state.function == OtpFunction.setting2sv) {
    //   await context.read<AuthBloc>().createAccountPreparationUpdateMethod(
    //       method: state.selectedMethod!, token: state.token);
    // }
    // // Require otp code
    // // authBloc.add(RequireOtpCode(communicationMethod: state.selectedMethod!));
    // // TODO if is create account, do create account preparation first

    // TODO WHY need delay here????
    await Future.delayed(Duration(seconds: 1));
    ref
        .read(otpProvider.notifier)
        .mfaChallenge(method: state.selectedMethod!, token: state.token);
  }
}
