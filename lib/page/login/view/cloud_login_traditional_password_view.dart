import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/otp/otp.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/cloud/model/cloud_session_model.dart';
import 'package:linksys_app/core/cloud/model/error_response.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/biometrics.dart';
import 'package:linksys_app/util/error_code_handler.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class CloudLoginPasswordView extends ArgumentsConsumerStatefulView {
  const CloudLoginPasswordView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<CloudLoginPasswordView> createState() =>
      _LoginTraditionalPasswordViewState();
}

class _LoginTraditionalPasswordViewState
    extends ConsumerState<CloudLoginPasswordView> {
  final TextEditingController passwordController = TextEditingController();
  String _errorCode = '';
  String _username = '';
  bool _isEnrollBiometrics = false;
  bool _isBiometricsLogin = false;
  // late AuthBloc _authBloc;
  // late OtpCubit _optCubit;

  @override
  initState() {
    super.initState();
    // _authBloc = context.read<AuthBloc>();
    // _optCubit = context.read<OtpCubit>();

    _username = widget.args['username'] ?? '';
    _isBiometricsLogin = widget.args['enrolledBiometrics'] ?? false;
    if (_isBiometricsLogin) {
      BiometricsHelp().loadBiometrics(_username).then((value) {
        passwordController.text = value;
        ref.read(authProvider.notifier).cloudLogin(
            username: _username,
            password: value,
            isBiometricsLogin: _isBiometricsLogin);
      }).onError((error, stackTrace) {
        // final err = error as PlatformException?;
        context.pop();
      });
    }
  }

  @override
  dispose() {
    super.dispose();
    passwordController.dispose();
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
              username: _username,
              password: passwordController.text,
              sessionToken: SessionToken.fromJson(next.$2),
              isEnrolledBiometrics: _isEnrollBiometrics,
              isBiometricsLogin: _isBiometricsLogin,
            );
      }
    });
    final data = ref.watch(authProvider);
    return data.when(
        skipError: true,
        data: _contentView,
        error: (_, __) => const Center(
              child: AppText.bodyLarge('Something wrong here!'),
            ),
        loading: () => AppFullScreenSpinner(
            text: getAppLocalizations(context).processing));
  }

  Widget _contentView(AuthState state) {
    return StyledAppPageView(
      scrollable: true,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: AppText.titleLarge(
          getAppLocalizations(context).enter_password,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.big(),
            AppText.bodyLarge(_username),
            AppPasswordField(
              key: const Key('login_password_view_input_field_password'),
              // headerText: getAppLocalizations(context).password,
              hintText: getAppLocalizations(context).password,
              // isError: _errorCode.isNotEmpty,
              errorText: generalErrorCodeHandler(context, _errorCode),
              controller: passwordController,
              autofillHint: const [AutofillHints.password],
              onChanged: (value) {
                setState(() {
                  _errorCode = '';
                });
              },
            ),
            const AppGap.small(),
            Align(
              alignment: Alignment.bottomRight,
              child: AppTertiaryButton.noPadding(
                getAppLocalizations(context).forgot_password,
                key: const Key('login_password_view_button_forgot_password'),
                onTap: () {
                  context.pushNamed(RouteNamed.cloudForgotPassword);
                },
              ),
            ),
            const AppGap.regular(),
            FutureBuilder(
              future: BiometricsHelp().canAuthenticate(),
              builder: (context, snapshot) =>
                  _checkBiometrics(context, snapshot),
            ),
            const Spacer(),
            AppPrimaryButton.fillWidth(
              getAppLocalizations(context).text_continue,
              key: const Key('login_password_view_button_continue'),
              onTap: passwordController.text.isEmpty
                  ? null
                  : () async {
                      await ref
                          .read(authProvider.notifier)
                          .cloudLogin(
                            username: _username,
                            password: passwordController.text,
                            isEnrolledBiometrics: _isEnrollBiometrics,
                          )
                          .onError((error, stackTrace) {});
                    },
            ),
          ],
        ),
      ),
    );
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
          'username': _username,
          'token': mfaError.verificationToken,
          'password': passwordController.text,
          // 'backPath': GoRouter.of(context).routerDelegate.currentConfiguration.fullPath,
        },
      );
    } else {
      setState(() {
        _errorCode = error.code;
      });
    }
  }

  Widget _checkBiometrics(
      BuildContext context, AsyncSnapshot<CanAuthenticateResponse> snapshot) {
    if (kIsWeb) {
      return const Center();
    }
    if (snapshot.hasError) {
      return const Center();
    } else {
      return snapshot.data == CanAuthenticateResponse.success
          ? AppCheckbox(
              text: 'Enroll biometrics',
              value: _isEnrollBiometrics,
              onChanged: (value) {
                setState(() {
                  _isEnrollBiometrics = !_isEnrollBiometrics;
                });
              },
            )
          : const Center();
    }
  }
}
