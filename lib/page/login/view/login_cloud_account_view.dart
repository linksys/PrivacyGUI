import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/page/login/view/view.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/util/validator.dart';
import 'package:moab_poc/route/model/model.dart';

import '../../components/base_components/progress_bars/full_screen_spinner.dart';

class LoginCloudAccountView extends StatefulWidget {
  const LoginCloudAccountView({
    Key? key,
  }) : super(key: key);

  @override
  LoginCloudAccountState createState() => LoginCloudAccountState();
}

class LoginCloudAccountState extends State<LoginCloudAccountView> {
  bool _isValidEmail = false;
  bool _isLoading = false;
  String _errorReason = '';

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
    logger.d('DEBUG:: LoginCloudAccountView: build');

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => _isLoading
          ? const FullScreenSpinner(text: 'processing...')
          : _contentView(state),
    );
  }

  Widget _contentView(AuthState state) {
    return BasePageView(
        scrollable: true,
        child: BasicLayout(
          alignment: CrossAxisAlignment.start,
          header: const BasicHeader(
            title: 'Log in to your Linksys account',
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputField(
                titleText: 'Email',
                hintText: 'Email',
                controller: _accountController,
                onChanged: _checkFilledInfo,
                inputType: TextInputType.emailAddress,
                isError: !_isValidEmail && _accountController.text.isNotEmpty || _errorReason.isNotEmpty,
              ),
              if (!_isValidEmail && _accountController.text.isNotEmpty || _errorReason.isNotEmpty)
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
              if (_errorReason == "NOT_FOUND")
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SimpleTextButton(
                      text: 'Did you use this email with another Linksys app?',
                      onPressed: () => NavigationCubit.of(context)
                          .push(AlreadyHaveOldAccountPath())),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SimpleTextButton(
                    text: 'Forgot email',
                    onPressed: () => NavigationCubit.of(context)
                        .push(AuthForgotEmailPath())),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: PrimaryButton(
                  text: 'Continue',
                  onPress: _isValidEmail
                      ? () async {
                          setState(() {
                            _isLoading = true;
                          });
                          await context
                              .read<AuthBloc>()
                              .testUsername(_accountController.text)
                              .then((value) => _handleResult(_accountController.text, value))
                          .onError((error, stackTrace) => _handleError(error as CloudException));
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      : null,
                ),
              ),
              Center(
                child: SimpleTextButton(
                    text: 'Log in with router password',
                    onPressed: () =>
                        NavigationCubit.of(context).push(AuthLocalLoginPath())),
              ),
              const Spacer(),
            ],
          ),
        ));
  }

  String _checkErrorReason() {
    if (_errorReason.isEmpty) {
      return 'Enter a valid email format';
    } else if (_errorReason == 'NOT_FOUND') {
      return 'Email address not found';
    } else {
      return 'Unknown error';
    }
  }

  _checkFilledInfo(_) {
    setState(() {
      _isValidEmail = _emailValidator.validate(_accountController.text);
    });
  }

  _handleResult(String username, AccountInfo accountInfo) {
    if (accountInfo.loginType == LoginType.password) {
      NavigationCubit.of(context).push(AuthCloudLoginWithPasswordPath());
    } else {

      NavigationCubit.of(context)
          .push(AuthCloudLoginOtpPath()
        ..args = {'username': username});
    }
  }

  _handleError(CloudException e) {
    setState(() {
      _errorReason = e.code;
    });
  }
}
