import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/page/login/bloc.dart';
import 'package:moab_poc/page/login/event.dart';
import 'package:moab_poc/page/login/state.dart';
import 'package:moab_poc/repository/authenticate/impl/fake_auth_repository.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/util/validator.dart';

class LoginCloudAccountView extends StatelessWidget {
  const LoginCloudAccountView({
    Key? key,
    required this.onNext,
    required this.onForgotEmail,
    required this.onLocalLogin,
  }) : super(key: key);

  final void Function() onNext;
  final void Function() onForgotEmail;
  final void Function() onLocalLogin;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
        create: (context) => FakeAuthRepository(),
        child: BlocProvider<LoginBloc>(
            create: (context) =>
                LoginBloc(repo: context.read<FakeAuthRepository>()),
                child: _LoginCloudAccountView(onLocalLogin: onLocalLogin, onForgotEmail: onForgotEmail, onNext: onNext,),
        )
    );
  }
}

class _LoginCloudAccountView extends StatefulWidget {
  const _LoginCloudAccountView({
    Key? key,
    required this.onNext,
    required this.onForgotEmail,
    required this.onLocalLogin,
  }) : super(key: key);

  final void Function() onNext;
  final void Function() onForgotEmail;
  final void Function() onLocalLogin;

  @override
  _LoginCloudAccountState createState() => _LoginCloudAccountState();
}

class _LoginCloudAccountState extends State<_LoginCloudAccountView> {
  bool _isValidEmail = false;
  final _emailValidator = EmailValidator();
  final TextEditingController _accountController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('DEBUG:: LoginCloudAccountView: build');

    // return RepositoryProvider(
    //   create: (context) => FakeAuthRepository(),
    //   child: BlocProvider<LoginBloc>(
    //     create: (context) =>
    //         LoginBloc(repo: context.read<FakeAuthRepository>()),
    //     child: Builder(builder: (context) {
    //       return BlocConsumer<LoginBloc, LoginState>(
    //         listener: (context, state) => _navigation(context, state),
    //         builder: (context, state) => _contentView(),
    //       );
    //     }),
    //   ),
    // );
    context.read<LoginBloc>().add(Initial());
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) => _navigation(context, state),
      builder: (context, state) => _contentView(),
    );
  }

  Widget _contentView() {
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
                      onPressed: () {
                        _addEvent(GoForgotEmail());
                      }),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: PrimaryButton(
                  text: 'Continue',
                  onPress: _isValidEmail
                      ? () {
                    _addEvent(TestUserName(_accountController.text));
                  }
                      : null,
                ),
              ),
              SimpleTextButton(
                  text: 'Log in with router password',
                  onPressed: () {
                    _addEvent(GoLocalLogin());
                  }),
              const Spacer(),
            ],
          ),
        ));
  }

  void _addEvent(LoginEvent event) {
    context.read<LoginBloc>().add(event);
  }

  _navigation(BuildContext context, LoginState state) {
    logger.d('Cloud Account Login:: navigation: ${state.runtimeType}');
    if (state is ForgotEmail) {
      widget.onForgotEmail();
    } else if (state is LocalLogin) {
      widget.onLocalLogin();
    } else if (state is WaitForOTP) {
      //
    } else if (state is ChoosePasswordLessMethod) {
      widget.onNext();
    }
  }

  _checkFilledInfo(_) {
    setState(() {
      _isValidEmail = _emailValidator.validate(_accountController.text);
    });
  }
}
