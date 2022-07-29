import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/network/http/model/base_response.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/util/error_code_handler.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/state.dart';
import '../../../repository/model/dummy_model.dart';
import '../../../route/navigation_cubit.dart';
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
  String _errorCode = '';
  String _username = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => _isLoading
          ? FullScreenSpinner(text: getAppLocalizations(context).processing)
          : _contentView(state),
    );
  }

  Widget _contentView(AuthState state) {
    _username = state.accountInfo.username;
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).enter_password,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PasswordInputField(
              titleText: getAppLocalizations(context).password,
              hintText: getAppLocalizations(context).password,
              isError: _errorCode.isNotEmpty,
              errorText: generalErrorCodeHandler(context, _errorCode),
              controller: passwordController,
              onChanged: (value) {
                setState(() {
                  _errorCode = '';
                });
              },
            ),
            const SizedBox(
              height: 15,
            ),
            SimpleTextButton(text: getAppLocalizations(context).forgot_password, onPressed: () {
              NavigationCubit.of(context).push(AuthCloudForgotPasswordPath());
            }),
            const SizedBox(
              height: 38,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).text_continue,
              onPress: passwordController.text.isEmpty
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      await context
                          .read<AuthBloc>()
                          .loginPassword(passwordController.text)
                          .then((value) => _handleResult(value))
                          .onError((error, stackTrace) => _handleError(error, stackTrace));
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

  _handleResult(AccountInfo accountInfo) async {
    // if (accountInfo.loginType == LoginType.otp)
    NavigationCubit.of(context)
        .push(AuthCloudLoginOtpPath()..args = {'username': _username});
  }

  _handleError(Object? e, StackTrace trace) {
    if (e is ErrorResponse) {
      setState(() {
        _errorCode = e.code;
      });
    } else { // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
  }
}
