import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/util/validator.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/state.dart';
import '../../../repository/model/dummy_model.dart';
import '../../../route/navigation_cubit.dart';
import '../../components/base_components/input_fields/input_field.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';
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
          ?  FullScreenSpinner(text: getAppLocalizations(context).processing)
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
            InputField(
              titleText: getAppLocalizations(context).enter_password,
              isError: _errorReason.isNotEmpty,
              controller: _passwordController,
              onChanged: (value) {
                setState(() {
                  _errorReason = '';
                });
              },
            ),
            if (_errorReason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  _checkErrorReason(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(color: Colors.red),
                ),
              ),
            const SizedBox(
              height: 23,
            ),
            PasswordValidityWidget(passwordText: _passwordController.text),
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
                              _handleError(error as CloudException));
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
              icon: const Icon(Icons.check, color: Colors.white,),
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

  _handleError(CloudException e) {
    setState(() {
      _errorReason = e.code;
    });
  }
}