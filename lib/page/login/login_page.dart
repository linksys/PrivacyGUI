import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:moab_poc/design_system/colors.dart';
import 'package:moab_poc/design_system/dimensions.dart';
import 'package:moab_poc/design_system/texts.dart';
import 'package:moab_poc/page/dashboard/view.dart';
import 'package:moab_poc/page/login/cubit.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  final titleText = const Text(
    'Log in',
    style: primaryPageTitle,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      child: Scaffold(
        body: SafeArea(
          child: Container(
            child: Column(
              children: [
                Row(
                  children: [titleText],
                  mainAxisAlignment: MainAxisAlignment.start,
                ),
                const LoginForm(),
              ],
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            color: MoabColor.white,
          ),
        ),
      ),
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: MoabColor.white,
      )
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
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
        const SizedBox(
          height: 36,
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
            Navigator.pushNamed(context, DashboardPage.routeName);
          },
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }
}
