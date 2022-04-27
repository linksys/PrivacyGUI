import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/design_system/colors.dart';
import 'package:moab_poc/design_system/dimensions.dart';
import 'package:moab_poc/design_system/texts.dart';
import 'package:moab_poc/page/login/login.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final ssid = args['ssid'] ?? 'Unknown';

    return AnnotatedRegion(
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints viewportConstraints) {
                return SingleChildScrollView(
                  child: Container(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Flexible(child: Text(
                                  'Log in to ' + ssid,
                                  style: primaryPageTitle,
                                ))
                              ],
                              mainAxisAlignment: MainAxisAlignment.start,
                            ),
                            const LoginForm(),
                          ],
                          crossAxisAlignment: CrossAxisAlignment.center,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    color: MoabColor.white,
                  )
                );
              },
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
            labelText: 'Username',
            labelStyle: primaryFieldTitle,
            hintText: 'Enter username',
            hintStyle: primaryPlaceholder,
          ),
          onChanged: (value) {},
        ),
        TextField(
          controller: pwdController,
          decoration: const InputDecoration(
            labelText: 'Password',
            labelStyle: primaryFieldTitle,
            hintText: 'Enter password',
            hintStyle: primaryPlaceholder,
          ),
          onChanged: (value) {},
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
            await context
                .read<LoginCubit>()
                .login(emailController.text, pwdController.text);
            showInfo();
            // Navigator.pushNamed(context, DashboardPage.routeName);
          },
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }
}
