import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/validator.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/state.dart';
import '../../../repository/model/dummy_model.dart';
import '../../../route/navigation_cubit.dart';
import '../../components/base_components/input_fields/input_field.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';
import '../../components/customs/password_validity_widget.dart';
import '../../create_account/view/create_account_password_view.dart';

class CloudResetPasswordView extends ArgumentsStatefulView {
  const CloudResetPasswordView({Key? key}) : super(key: key);

  @override
  _CloudForgotPasswordViewState createState() =>
      _CloudForgotPasswordViewState();
}

class _CloudForgotPasswordViewState extends State<CloudResetPasswordView> {
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
      context,
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
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
        alignment: CrossAxisAlignment.start,
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
                NavigationCubit.of(context).clearAndPush(HomePath());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkExpiredView() {
    return BasePageView.withCloseButton(
      context,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
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
                NavigationCubit.of(context).clearAndPush(HomePath());
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
    } else { // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
  }
}
