import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/otp_flow/_otp_flow.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/components/composed/app_panel_with_value_check.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        ? const AppFullScreenLoader()
        : UiKitPageView(
            appBarStyle: UiKitAppBarStyle.none,
            padding: EdgeInsets.zero,
            scrollable: true,
            pageFooter: const BottomBar(),
            child: (context, constraints) => Center(
              child: SizedBox(
                width: context.colWidth(4),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36.0, vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          AppText.headlineSmall(loc(context).login),
                          AppGap.xxxl(),
                          Focus(
                            onFocusChange: (value) {
                              setState(() {
                                _isValidEmail = _emailValidator
                                    .validate(_usernameController.text);
                              });
                            },
                            child: AppTextFormField(
                              controller: _usernameController,
                              label: loc(context).username,
                              onChanged: _checkFilledInfo,
                            ),
                          ),
                          if (!(_isValidEmail ?? true))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: AppText.bodySmall(
                                'Invalid Email format',
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          AppGap.lg(),
                          AppPasswordInput(
                            controller: _passwordController,
                            hint: loc(context).password,
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
                          AppGap.xxxl(),
                          if (BuildConfig.isEnableEnvPicker &&
                              BuildConfig.forceCommandType !=
                                  ForceCommand.local)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: AppButton.text(
                                label: 'Select Env',
                                onTap: () async {
                                  final _ = await showModalBottomSheet(
                                    enableDrag: false,
                                    context: context,
                                    builder: (context) => _createEnvPicker(),
                                  );
                                  setState(() {});
                                },
                              ),
                            ),
                          AppButton(
                            label: 'Log in',
                            variant: SurfaceVariant.highlight,
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
              )
            );
  }

  Widget _createEnvPicker() {
    bool isLoading = false;
    return StatefulBuilder(builder: (context, setState) {
      return isLoading
          ? AppFullScreenLoader()
          : Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: CloudEnvironment.values.length,
                      itemBuilder: (context, index) => InkWell(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              child: AppPanelWithValueCheck(
                                title: CloudEnvironment.values[index].name,
                                valueText: '',
                                isChecked: cloudEnvTarget ==
                                    CloudEnvironment.values[index],
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                cloudEnvTarget = CloudEnvironment.values[index];
                              });
                            },
                          )),
                  const Spacer(),
                  AppButton(
                    label: 'Save',
                    variant: SurfaceVariant.highlight,
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                      });

                      final pref = await SharedPreferences.getInstance();
                      pref.setString(pCloudEnv, cloudEnvTarget.name);
                      BuildConfig.load();
                      setState(() {
                        isLoading = false;
                      });
                      if (context.mounted) {
                        Navigator.pop(context, cloudEnvTarget);
                      }
                    },
                  ),
                  AppGap.lg(),
                ],
              ),
            );
    });
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
