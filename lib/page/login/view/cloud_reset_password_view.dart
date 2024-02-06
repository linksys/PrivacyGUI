import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/cloud/model/error_response.dart';
import 'package:linksys_app/page/components/layouts/basic_header.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class CloudResetPasswordView extends ArgumentsConsumerStatefulView {
  const CloudResetPasswordView({Key? key}) : super(key: key);

  @override
  _CloudForgotPasswordViewState createState() =>
      _CloudForgotPasswordViewState();
}

class _CloudForgotPasswordViewState
    extends ConsumerState<CloudResetPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  String _errorReason = '';
  final bool _isLoading = false;
  bool _isNewPasswordSet = false;
  final bool _isLinkExpired = false;

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppText.bodyLarge('TBD'),
    );
  }

  Widget _setNewPasswordView() {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.close,
      child: AppBasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).enter_your_new_password,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.big(),
            AppPasswordField.withValidator(
              headerText: getAppLocalizations(context).enter_password,
              controller: _passwordController,
              errorText: _checkErrorReason(),
              onChanged: (value) {
                setState(() {
                  _errorReason = '';
                });
              },
              validations: [
                Validation(
                  description: 'At least 10 characters',
                  validator: (text) => LengthRule().validate(text),
                ),
                Validation(
                  description: 'Upper and lowercase letters',
                  validator: (text) => HybridCaseRule().validate(text),
                ),
                Validation(
                  description: '1 number',
                  validator: (text) => DigitalCheckRule().validate(text),
                ),
                Validation(
                  description: '1 special character',
                  validator: (text) => SpecialCharCheckRule().validate(text),
                ),
              ],
            ),
            const AppGap.semiBig(),
            AppFilledButton(
              getAppLocalizations(context).text_continue,
              onTap: _localValidatePassword(_passwordController.text)
                  ? () async {
                      // setState(() {
                      //   _isLoading = true;
                      // });
                      // await context
                      //     .read<AuthBloc>()
                      //     .resetPassword(_passwordController.text)
                      //     .then((value) => _handleResult())
                      //     .onError((error, stackTrace) =>
                      //         _handleError(error, stackTrace));
                      // setState(() {
                      //   _isLoading = false;
                      // });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _newPasswordSetView() {
    return AppPageView(
      child: AppBasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).new_password_set,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(
                Icons.check,
                color: Colors.white,
              ),
              onPressed: () {
                context.goNamed(RouteNamed.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkExpiredView() {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.close,
      child: AppBasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).error_reset_password_link_expired,
        ),
        content: Column(
          children: [
            const AppGap.extraBig(),
            AppFilledButton(
              getAppLocalizations(context).back_to_login,
              onTap: () {
                context.goNamed(RouteNamed.home);
              },
            )
          ],
        ),
      ),
    );
  }

  String _checkErrorReason() {
    if (_errorReason == 'OLD_PASSWORD') {
      return getAppLocalizations(context).error_reset_password_use_old_password;
    } else {
      return getAppLocalizations(context).unknown_error;
    }
  }

  bool _localValidatePassword(String password) {
    return ComplexPasswordValidator().validate(password);
  }

  _handleResult() async {
    setState(() {
      _isNewPasswordSet = true;
    });
  }

  _handleError(Object? e, StackTrace trace) {
    if (e is ErrorResponse) {
      setState(() {
        _errorReason = e.code;
      });
    } else {
      // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
  }
}
