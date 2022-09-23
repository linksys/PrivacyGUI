import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/constants/constants.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/util/error_code_handler.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/validator.dart';
import 'package:linksys_moab/route/model/_model.dart';

import '../../../utils.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';

class CloudLoginAccountView extends ArgumentsStatefulView {
  const CloudLoginAccountView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  LoginCloudAccountState createState() => LoginCloudAccountState();
}

class LoginCloudAccountState extends State<CloudLoginAccountView> {
  bool _isLoading = false;
  bool _fromSetup = false;
  bool _enableBiometrics = false;
  String _errorCode = '';

  final _emailValidator = EmailValidator();
  final TextEditingController _accountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fromSetup = widget.next is SaveCloudSettingsPath ? true : false;
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          if (previous is AuthOnCloudLoginState &&
              current is AuthOnCloudLoginState) {
            return (previous.accountInfo.loginType == LoginType.none) &&
                (current.accountInfo.loginType != LoginType.none);
          } else {
            return false;
          }
        },
        listener: (context, state) {
          if (state is AuthOnCloudLoginState) {
            if (state.accountInfo.loginType == LoginType.password) {
              logger.d('Go Password');
              NavigationCubit.of(context).push(AuthCloudLoginWithPasswordPath()
                ..args = widget.args
                ..next = widget.next);
            } else if (state.accountInfo.loginType == LoginType.passwordless) {
              logger.d('Go Password-less');
              NavigationCubit.of(context).push(AuthCloudLoginOtpPath()
                ..args = {
                  'username': state.accountInfo.username,
                  ...widget.args
                }
                ..next = widget.next);
            }
          } else {
            logger.d('ERROR: Wrong state type on LoginCloudAccountView');
          }
        },
        builder: (context, state) => _isLoading
            ? FullScreenSpinner(text: getAppLocalizations(context).processing)
            : _contentView(state));
  }

  Widget _contentView(AuthState state) {
    return BasePageView(
        scrollable: true,
        child: BasicLayout(
          alignment: CrossAxisAlignment.start,
          header: BasicHeader(
            title: getAppLocalizations(context).cloud_account_login_title,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputField(
                titleText: getAppLocalizations(context).email,
                hintText: getAppLocalizations(context).email,
                controller: _accountController,
                onChanged: _checkFilledInfo,
                inputType: TextInputType.emailAddress,
                isError: _errorCode.isNotEmpty,
                errorText: generalErrorCodeHandler(context, _errorCode),
              ),
              if (_errorCode == "RESOURCE_NOT_FOUND")
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SimpleTextButton(
                      text: getAppLocalizations(context)
                          .cloud_account_login_email_with_linksys_app,
                      onPressed: () => NavigationCubit.of(context)
                          .push(AlreadyHaveOldAccountPath())),
                ),
              Offstage(
                offstage: _fromSetup,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SimpleTextButton(
                      text: getAppLocalizations(context).forgot_email,
                      onPressed: () => NavigationCubit.of(context)
                          .push(AuthForgotEmailPath())),
                ),
              ),
              FutureBuilder<bool>(
                future: Utils.canUseBiometrics(),
                initialData: false,
                builder: (context, canUseBiometrics) {
                  return Offstage(
                    offstage: !(canUseBiometrics.data ?? false),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _enableBiometrics = !_enableBiometrics;
                        });
                      },
                      child: CheckboxSelectableItem(
                        title: getAppLocalizations(context).enable_biometrics,
                        isSelected: _enableBiometrics,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: PrimaryButton(
                  text: getAppLocalizations(context).text_continue,
                  onPress:
                      _accountController.text.isNotEmpty ? _prepareLogin : null,
                ),
              ),
              Offstage(
                offstage: _fromSetup,
                child: Center(
                  child: SimpleTextButton(
                      text: getAppLocalizations(context)
                          .cloud_account_login_with_router_password,
                      onPressed: () => NavigationCubit.of(context)
                          .push(AuthLocalLoginPath())),
                ),
              ),
              const Spacer(),
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
    final isValid = _emailValidator.validate(_accountController.text);
    setState(() {
      if (isValid) {
        _isLoading = true;
      } else {
        _errorCode = errorEmptyEmail;
      }
    });
    if (_errorCode.isEmpty) {
      await context
          .read<AuthBloc>()
          .loginPrepare(_accountController.text)
          .onError((error, stackTrace) => _handleError(error, stackTrace));
      context
          .read<AuthBloc>()
          .add(SetEnableBiometrics(enableBiometrics: _enableBiometrics));
    }
    setState(() {
      _isLoading = false;
    });
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
