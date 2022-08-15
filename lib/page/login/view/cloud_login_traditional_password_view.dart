import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/util/error_code_handler.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/state.dart';
import '../../../route/navigation_cubit.dart';
import '../../../util/logger.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';
import '../../components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/model.dart';

class CloudLoginPasswordView extends ArgumentsStatefulView {
  const CloudLoginPasswordView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  _LoginTraditionalPasswordViewState createState() =>
      _LoginTraditionalPasswordViewState();
}

class _LoginTraditionalPasswordViewState extends State<CloudLoginPasswordView> {
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorCode = '';
  String _username = '';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          if (previous is AuthOnCloudLoginState &&
              current is AuthOnCloudLoginState) {
            return previous.accountInfo.loginType !=
                current.accountInfo.loginType;
          }
          return false;
        },
        listener: (context, state) {
          if (state is AuthOnCloudLoginState) {
            if (state.accountInfo.loginType == LoginType.passwordless) {
              NavigationCubit.of(context).push(AuthCloudLoginOtpPath()
                ..args = {'username': _username, ...widget.args}
                ..next = widget.next);
            }
          } else {
            logger.d('ERROR: Wrong state type on LoginTraditionalPasswordView');
          }
        },
        builder: (context, state) => _isLoading
            ? FullScreenSpinner(text: getAppLocalizations(context).processing)
            : _contentView(state));
  }

  Widget _contentView(AuthState state) {
    _username = (state as AuthOnCloudLoginState).accountInfo.username;
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
            SimpleTextButton(
                text: getAppLocalizations(context).forgot_password,
                onPressed: () {
                  NavigationCubit.of(context)
                      .push(AuthCloudForgotPasswordPath());
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
                          .onError((error, stackTrace) =>
                              _handleError(error, stackTrace));
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

  _handleError(Object? e, StackTrace trace) {
    if (e is ErrorResponse) {
      setState(() {
        _errorCode = e.code;
      });
    } else {
      // Unknown error or error parsing
      logger.d('Unknown error: $e');
    }
  }
}
