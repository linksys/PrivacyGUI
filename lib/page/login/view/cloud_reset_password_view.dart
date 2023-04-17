import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/state.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';

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
  bool _isLoading = false;
  bool _isNewPasswordSet = false;
  bool _isLinkExpired = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => _isLoading
          ? FullScreenSpinner(text: getAppLocalizations(context).processing)
          : _isLinkExpired
              ? _linkExpiredView()
              : (_isNewPasswordSet
                  ? _newPasswordSetView()
                  : _setNewPasswordView()),
    );
  }

  Widget _setNewPasswordView() {
    return BasePageView.withCloseButton(
      context, ref,
      scrollable: true,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).enter_your_new_password,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 37,
            ),
            PasswordInputField.withValidator(
              titleText: getAppLocalizations(context).enter_password,
              controller: _passwordController,
              isError: _errorReason.isNotEmpty,
              errorText: _checkErrorReason(),
              onChanged: (value) {
                setState(() {
                  _errorReason = '';
                });
              },
            ),
            const SizedBox(
              height: 23,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).text_continue,
              onPress: _localValidatePassword(_passwordController.text)
                  ? () async {
                      setState(() {
                        _isLoading = true;
                      });
                      await context
                          .read<AuthBloc>()
                          .resetPassword(_passwordController.text)
                          .then((value) => _handleResult())
                          .onError((error, stackTrace) =>
                              _handleError(error, stackTrace));
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _newPasswordSetView() {
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                ref.read(navigationsProvider.notifier).clearAndPush(HomePath());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkExpiredView() {
    return BasePageView.withCloseButton(
      context, ref,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).error_reset_password_link_expired,
        ),
        content: Column(
          children: [
            const SizedBox(
              height: 67,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).back_to_login,
              onPress: () {
                ref.read(navigationsProvider.notifier).clearAndPush(HomePath());
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
