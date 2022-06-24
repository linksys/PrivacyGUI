import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/util/validator.dart';

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
      builder: (context, state) => _isLoading ? const FullScreenSpinner(text: 'processing...') : _contentView(state),
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
            children: [
              InputField(
                titleText: 'Email',
                hintText: 'Email',
                controller: _accountController,
                onChanged: _checkFilledInfo,
                inputType: TextInputType.emailAddress,
              ),
              Row(
                children: [
                  SimpleTextButton(
                      text: 'Forgot email',
                      onPressed: () => NavigationCubit.of(context).push(AuthForgotEmailPath())),
                ],
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
                    await context.read<AuthBloc>().testUsername(
                        _accountController.text).then((value) => _checkOtpMethod(value));
                    setState(() {
                      _isLoading = false;
                    });
                  }
                      : null,
                ),
              ),
              SimpleTextButton(
                  text: 'Log in with router password',
                  onPressed: () => NavigationCubit.of(context).push(AuthLocalLoginPath())),
              const Spacer(),
            ],
          ),
        ));
  }

  _checkFilledInfo(_) {
    setState(() {
      _isValidEmail = _emailValidator.validate(_accountController.text);
    });
  }

  _checkOtpMethod(List<OtpInfo> list) {
    logger.d('OTP Methods: ${list.length}, $list');
    NavigationCubit.of(context).push(AuthChooseOtpPath()..args = {'otpMethod': list});
  }
}
