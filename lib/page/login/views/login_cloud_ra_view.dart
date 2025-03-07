import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/otp_flow/_otp_flow.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class LoginCloudRAView extends ArgumentsConsumerStatefulView {
  const LoginCloudRAView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<LoginCloudRAView> createState() => _LoginCloudRAViewState();
}

class _LoginCloudRAViewState extends ConsumerState<LoginCloudRAView> {
  String _error = '';
  bool? _isValidEmail;
  final _emailValidator = EmailValidator();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();

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
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      scrollable: true,
      child:(context, constraints, scrollController) => AppBasicLayout(
        content: Center(
          child: SizedBox(
            width: 4.col,
            child: AppCard(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 36.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppText.headlineSmall('Remote assistant'),
                    const AppGap.large3(),
                    AppTextField(
                      border: const OutlineInputBorder(),
                      controller: _usernameController,
                      hintText: getAppLocalizations(context).username,
                      onChanged: _checkFilledInfo,
                      errorText:
                          _isValidEmail ?? true ? null : 'Invalid Email format',
                      onFocusChanged: (value) {
                        setState(() {
                          _isValidEmail = _emailValidator
                              .validate(_usernameController.text);
                        });
                      },
                      inputType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                    ),
                    const AppGap.medium(),
                    AppPasswordField(
                      border: const OutlineInputBorder(),
                      controller: _passwordController,
                      hintText: getAppLocalizations(context).password,
                      onChanged: (value) {
                        setState(() {
                          _error = '';
                        });
                      },
                    ),
                    const AppGap.medium(),
                    AppTextField(
                      border: const OutlineInputBorder(),
                      controller: _serialController,
                      hintText: getAppLocalizations(context).serialNumber,
                      errorText: errorCodeHelper(context, _error),
                      onSubmitted: (_) {
                        _cloudLogin();
                      },
                      onChanged: (value) {
                        setState(() {
                          _error = '';
                        });
                      },
                    ),
                    const AppGap.large3(),
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

  Future<void> _cloudLogin() async {
    _error = '';
    await doSomethingWithSpinner(
        context,
        ref
            .read(raSessionProvider.notifier)
            .raLogin(
              username: _usernameController.text,
              password: _passwordController.text,
              serialNumber: _serialController.text,
            )
            .onError((error, stackTrace) {
          logger.e('RA login error: $error', stackTrace: stackTrace);
          _error = error?.toString() ?? '';
        })).then((value) {
      if (_error.isNotEmpty) {
        return;
      }
      context.pushNamed(RouteNamed.cloudRAPin);
    });
  }
}
