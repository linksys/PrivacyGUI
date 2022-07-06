import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/state.dart';
import '../../../repository/model/dummy_model.dart';
import '../../../route/navigation_cubit.dart';
import '../../../route/model/path_model.dart';
import '../../../util/logger.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';
import '../../components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';

class LoginTraditionalPasswordView extends ArgumentsStatefulView {
  const LoginTraditionalPasswordView({
    Key? key,
  }) : super(key: key);

  @override
  _LoginTraditionalPasswordViewState createState() =>
      _LoginTraditionalPasswordViewState();
}

class _LoginTraditionalPasswordViewState
    extends State<LoginTraditionalPasswordView> {
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorReason = '';
  String _username = '';

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
    _username = state.accountInfo.username;
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Enter password',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputField(
              titleText: 'Password',
              hintText: 'Password',
              isError: _errorReason.isNotEmpty,
              controller: passwordController,
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
              height: 15,
            ),
            SimpleTextButton(text: 'Forgot password', onPressed: () {
              NavigationCubit.of(context).push(AuthCloudForgotPasswordPath());
            }),
            const SizedBox(
              height: 38,
            ),
            PrimaryButton(
              text: 'Continue',
              onPress: passwordController.text.isEmpty
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      await context
                          .read<AuthBloc>()
                          .login(_username, passwordController.text)
                          .then((value) => _handleResult(value))
                          .onError((error, stackTrace) =>
                              _handleError(error as CloudException));
                      setState(() {
                        _isLoading = false;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  String _checkErrorReason() {
    if (_errorReason == 'INCORRECT_PASSWORD') {
      return 'Incorrect password';
    } else {
      return 'Unknown error';
    }
  }

  _handleResult(List<OtpInfo> otpInfoList) async {
    NavigationCubit.of(context)
        .push(AuthCloudLoginOtpPath()..args = {'username': _username});
  }

  _handleError(CloudException e) {
    setState(() {
      _errorReason = e.code;
    });
  }
}
