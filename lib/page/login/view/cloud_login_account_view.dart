import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/error_code_handler.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class CloudLoginAccountView extends ArgumentsConsumerStatefulView {
  const CloudLoginAccountView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  LoginCloudAccountState createState() => LoginCloudAccountState();
}

class LoginCloudAccountState extends ConsumerState<CloudLoginAccountView> {
  bool _enableBiometrics = false;
  String _errorCode = '';

  final _emailValidator = EmailValidator();
  final TextEditingController _accountController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return state.when(
        skipError: true,
        data: (state) => _contentView(state),
        error: (_, __) => const Center(
              child: AppText.bodyLarge('Something wrong here'),
            ),
        loading: () => AppFullScreenSpinner(
            text: getAppLocalizations(context).processing));

    // return BlocConsumer<AuthBloc, AuthState>(
    //     listenWhen: (previous, current) {
    //       if (previous is AuthOnCloudLoginState &&
    //           current is AuthOnCloudLoginState) {
    //         return (previous.accountInfo.authenticationType ==
    //                 AuthenticationType.none) &&
    //             (current.accountInfo.authenticationType !=
    //                 AuthenticationType.none);
    //       } else {
    //         return false;
    //       }
    //     },
    //     listener: (context, state) async {
    //       if (state is AuthOnCloudLoginState) {
    //         // final accInfo = await context
    //         //     .read<AuthBloc>()
    //         //     .getMaskedCommunicationMethods(state.accountInfo.username);

    //         if (state.accountInfo.authenticationType ==
    //             AuthenticationType.password) {
    //           logger.d('Go Password');
    //           ref
    //               .read(navigationsProvider.notifier)
    //               .push(AuthCloudLoginWithPasswordPath()
    //                 ..args = {
    //                   // 'commMethods': accInfo.communicationMethods,
    //                   // 'token': state.vToken,
    //                   ...widget.args
    //                 }
    //                 ..next = widget.next);
    //         } else if (state.accountInfo.authenticationType ==
    //             AuthenticationType.passwordless) {
    //           logger.d('Go Password-less');
    //           ref
    //               .read(navigationsProvider.notifier)
    //               .push(AuthCloudLoginOtpPath()
    //                 ..args = {
    //                   'username': state.accountInfo.username,
    //                   // 'commMethods': accInfo.communicationMethods,
    //                   'token': state.vToken,
    //                   ...widget.args
    //                 }
    //                 ..next = widget.next);
    //         }
    //       } else {
    //         logger.d('ERROR: Wrong state type on LoginCloudAccountView');
    //       }
    //     },
    //     builder: (context, state) => _isLoading
    //         ? AppFullScreenSpinner(
    //             text: getAppLocalizations(context).processing)
    //         : _contentView(state));
  }

  Widget _contentView(AuthState state) {
    return StyledAppPageView(
        scrollable: true,
        child: AppBasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          header: AppText.titleLarge(
            getAppLocalizations(context).cloud_account_login_title,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.regular(),
              AppTextField(
                key: const Key('login_view_input_field_email'),
                headerText: getAppLocalizations(context).email,
                hintText: getAppLocalizations(context).email,
                controller: _accountController,
                onChanged: _checkFilledInfo,
                inputType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                errorText: generalErrorCodeHandler(context, _errorCode),
                ctaText: getAppLocalizations(context).forgot_question,
              ),
              if (_errorCode == "RESOURCE_NOT_FOUND")
                AppPadding(
                  padding: const AppEdgeInsets.symmetric(
                      vertical: AppGapSize.semiSmall),
                  child: AppTertiaryButton(
                      key: const Key(
                          'login_view_button_email_with_another_linksys_app'),
                      getAppLocalizations(context)
                          .cloud_account_login_email_with_linksys_app,
                      onTap: () {}),
                ),
              const Spacer(),
              AppPrimaryButton(
                getAppLocalizations(context).login,
                key: const Key('login_view_button_continue'),
                onTap:
                    _accountController.text.isNotEmpty ? _prepareLogin : null,
              ),
              AppSecondaryButton(
                  getAppLocalizations(context)
                      .cloud_account_login_with_router_password,
                  key: const Key('login_view_button_login_router_password'),
                  onTap: () {
                // Go Router
              }),
            ],
          ),
        ));
  }

  _checkFilledInfo(_) {
    setState(() {
      _errorCode = '';
    });
  }

  _prepareLogin() async {
    logger.d('prepare login');
    final isValid = _emailValidator.validate(_accountController.text);
    setState(() {
      if (!isValid) {
        _errorCode = errorEmptyEmail;
        logger.d('invalid input account');
      }
    });
    if (_errorCode.isEmpty) {
      logger.d('Go Password');
      context.goNamed(
        RouteNamed.cloudLoginPassword,
        extra: {'username': _accountController.text},
      );
    }
  }
}
