import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/event.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/network/http/model/base_response.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/error_code_handler.dart';
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
  String _errorCode = '';

  final _emailValidator = EmailValidator();
  final TextEditingController _accountController = TextEditingController();

  //TODO: Move to another place
  static const notificationAuthChannel = MethodChannel('otp.view/notification.auth');
  static const deviceTokenChannel = MethodChannel('otp.view/device.token');
  static const notificationContentChannel = EventChannel('moab.dev/notification.payload');

  Future<void> _readDeviceToken() async {
    if (Platform.isIOS) {
      final deviceToken = await deviceTokenChannel.invokeMethod('readDeviceToken');
      print('Receive device token=$deviceToken');
    }
  }

  Future<void> _getNotificationAuth() async {
    if (Platform.isIOS) {
      final isGrant = await notificationAuthChannel.invokeMethod('requestNotificationAuthorization');
      print('Receive Notification authorization result: isGrant=$isGrant');
    }
  }

  Future<void> _listenIOSNotification() async {
    if (Platform.isIOS) {
      notificationContentChannel.receiveBroadcastStream().listen((content) {
        print('IOS notification received : $content');
      });
    }
  }

  @override
  void initState() {
    //TODO: Move to another place
    _readDeviceToken();
    _getNotificationAuth();
    _listenIOSNotification();
    super.initState();

    context.read<AuthBloc>().add(OnLogin());
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => _isLoading
          ? FullScreenSpinner(text: getAppLocalizations(context).processing)
          : _contentView(state),
    );
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
                isError: !_isValidEmail && _accountController.text.isNotEmpty ||
                    _errorCode.isNotEmpty,
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SimpleTextButton(
                    text: getAppLocalizations(context).forgot_email,
                    onPressed: () => NavigationCubit.of(context)
                        .push(AuthForgotEmailPath())),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: PrimaryButton(
                  text: getAppLocalizations(context).text_continue,
                  onPress: _isValidEmail
                      ? () async {
                          setState(() {
                            _isLoading = true;
                          });
                          await context
                              .read<AuthBloc>()
                              .loginPrepare(_accountController.text)
                              .then((value) => _handleResult(value))
                              .onError((error, stackTrace) => _handleError(error, stackTrace));
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      : null,
                ),
              ),
              Center(
                child: SimpleTextButton(
                    text: getAppLocalizations(context)
                        .cloud_account_login_with_router_password,
                    onPressed: () =>
                        NavigationCubit.of(context).push(AuthLocalLoginPath())),
              ),
              const Spacer(),
            ],
          ),
        ));
  }

  _checkFilledInfo(_) {
    setState(() {
      _isValidEmail = _emailValidator.validate(_accountController.text);
      _errorCode = 'EMPTY_EMAIL';
    });
  }

  _handleResult(AccountInfo accountInfo) {
    if (accountInfo.loginType == LoginType.password) {
      NavigationCubit.of(context).push(AuthCloudLoginWithPasswordPath());
    } else {
      NavigationCubit.of(context).push(
          AuthCloudLoginOtpPath()..args = {'username': accountInfo.username});
    }
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
