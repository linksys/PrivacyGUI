import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/otp_flow/_otp_flow.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_handler.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

class LoginCloudView extends ArgumentsConsumerStatefulView {
  const LoginCloudView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<LoginCloudView> createState() => _LoginCloudViewState();
}

class _LoginCloudViewState extends ConsumerState<LoginCloudView> {
  bool _isLoading = false;
  String _error = '';
  bool? _isValidEmail;
  final _emailValidator = EmailValidator();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      logger.d('Auth provider changed!!!! \n$previous\n$next');
      if (!next.isLoading && next.hasError) {
        _handleError(next.error, next.stackTrace!);
      }
    });
    ref.listen(otpProvider.select((value) => (value.step, value.extras)),
        (previous, next) {
      if (next.$1 == previous?.$1) {
        return;
      }
      if (next.$1 == OtpStep.finish) {
        logger.d('Login password: Otp pass! $next');
        ref.read(authProvider.notifier).cloudLogin(
              username: _usernameController.text,
              password: _passwordController.text,
              sessionToken: SessionToken.fromJson(next.$2),
            );
      }
    });
    return _isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            appBarStyle: AppBarStyle.none,
            padding: EdgeInsets.zero,
            scrollable: true,
            child: AppBasicLayout(
              content: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36.0, vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.headlineSmall(
                            getAppLocalizations(context).login),
                        const AppGap.large2(),
                        SizedBox(
                          width: 289,
                          child: AppTextField(
                            border: const OutlineInputBorder(),
                            controller: _usernameController,
                            hintText: getAppLocalizations(context).username,
                            onChanged: _checkFilledInfo,
                            errorText: _isValidEmail ?? true
                                ? null
                                : 'Invalid Email format',
                            onFocusChanged: (value) {
                              setState(() {
                                _isValidEmail = _emailValidator
                                    .validate(_usernameController.text);
                              });
                            },
                            inputType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                          ),
                        ),
                        const AppGap.medium(),
                        SizedBox(
                          width: 289,
                          child: AppPasswordField(
                            border: const OutlineInputBorder(),
                            controller: _passwordController,
                            hintText: getAppLocalizations(context).password,
                            errorText: generalErrorCodeHandler(context, _error),
                            onSubmitted: (_) {
                              _cloudLogin();
                            },
                            onChanged: (value) {
                              setState(() {
                                _error = '';
                              });
                            },
                          ),
                        ),
                        const AppGap.large2(),
                        AppFilledButton(
                          'Log in',
                          onTap: _isValidEmail ?? true
                              ? () {
                                  _cloudLogin();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              footer: const BottomBar(),
            ),
          );
  }

  _checkFilledInfo(_) {
    setState(() {
      _error = '';
    });
  }

  _handleError(Object? e, StackTrace trace) {
    final error = e as ErrorResponse?;
    if (error == null) {
      // Unknown error or error parsing
      logger.d('Unknown error: $error');
      return;
    }

    if (error.code == errorMfaRequired) {
      final mfaError = ErrorMfaRequired.fromResponse(error);
      logger.d('handle mfa error');
      context.goNamed(
        RouteNamed.otpStart,
        extra: {
          'username': _usernameController.text,
          'token': mfaError.verificationToken,
          'password': _passwordController.text,
        },
      );
    } else {
      setState(() {
        _error = error.code;
      });
    }
  }

  Future<void> _cloudLogin() {
    setState(() {
      _isLoading = true;
    });
    return ref
        .read(authProvider.notifier)
        .cloudLogin(
          username: _usernameController.text,
          password: _passwordController.text,
        )
        .onError((error, stackTrace) {})
        .whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }
}
