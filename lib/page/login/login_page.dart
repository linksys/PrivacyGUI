import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/design_system/colors.dart';
import 'package:moab_poc/design_system/dimensions.dart';
import 'package:moab_poc/design_system/texts.dart';
import 'package:moab_poc/page/login/cubit.dart';

import '../dashboard/view.dart';

class LoginView extends StatelessWidget {
  LoginView({Key? key}) : super(key: key);

  final titleText = const Text(
    'Log in',
    style: primaryPageTitle,
  );

  final subTitleText = const Text(
    'Manage settings at home or away from home',
    style: primaryPageSubTitle,
  );

  final troubleShootingButton = TextButton(
    child: const Text(
      'Having a problem? Tell us about it',
      style: primaryTextButton,
    ),
    onPressed: () => print('Tap TroubleShooting button'),
  );

  final newHereText = const Text(
    'New here?',
    style: primaryContent,
  );

  final createAccountButton = TextButton(
    child: const Text(
      'Create an account',
      style: primaryTextButton,
    ),
    onPressed: () => print('Tap Create Account button'),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            children: [titleText],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
          Row(
            children: [subTitleText],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
          const LoginForm(),
          troubleShootingButton,
          const Spacer(),
          newHereText,
          createAccountButton,
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: MoabColor.lightGrey2,
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoginFormState();
  }
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final pwdController = TextEditingController();

  void showInfo() {
    print('\nEmail: ' +
        emailController.text +
        '\nPassword: ' +
        pwdController.text);
  }

  @override
  void dispose() {
    emailController.dispose();
    pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            labelStyle: primaryFieldTitle,
            hintText: 'Enter email address',
            hintStyle: primaryPlaceholder,
          ),
        ),
        TextField(
          controller: pwdController,
          decoration: const InputDecoration(
            labelText: 'Password',
            labelStyle: primaryFieldTitle,
            hintText: 'Enter password',
            hintStyle: primaryPlaceholder,
          ),
          onSubmitted: (text) => showInfo(),
        ),
        Row(
          children: [
            TextButton(
              child: const Text(
                'Forgot password?',
                style: primaryTextButton,
              ),
              onPressed: () => print('Tap Forgot Password button'),
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.end,
        ),
        ElevatedButton.icon(
          icon: const Icon(
            Icons.lock,
            color: MoabColor.white,
            size: 20,
          ),
          label: const Text('Log in'),
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 16),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: MoabRadius.getS()),
          ),
          onPressed: () async {
            await context.read<LoginCubit>().login(username: '', password: '');
            showInfo();
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DashboardPage()));
            Navigator.pushNamed(context, '/dashboard');
          },
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }
}
