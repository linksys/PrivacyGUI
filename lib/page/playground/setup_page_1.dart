import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/playground/setup_page_2.dart';

class SetupPage1 extends StatelessWidget {
  const SetupPage1({Key? key}) : super(key: key);

  static const routeName = '/setup_1';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MoabTheme.setupModuleLightModeData,
      child: const SetupContent(),
    );
  }
}

class SetupContent extends StatelessWidget {
  const SetupContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
        ),
        body: Container(
          child: Column(
            children: [
              Text(
                'SETUP1 style=headline1',
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    ?.copyWith(color: Theme.of(context).colorScheme.secondary),
              ),
              Padding(
                child: Text(
                  'style=headline2',
                  style: Theme.of(context).textTheme.headline2?.copyWith(
                      color: Theme.of(context).colorScheme.secondary),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              Padding(
                child: Text(
                  'style=headline3',
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                      color: Theme.of(context).colorScheme.secondary),
                ),
                padding: const EdgeInsets.only(bottom: 20),
              ),
              Text(
                'style=headline3 with Alpha_0.7',
                style: Theme.of(context)
                    .textTheme
                    .headline3
                    ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
              ),
              const Padding(
                child: LoginForm(),
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
              TextButton(
                child: Text(
                  'Where do I find this?',
                  style: Theme.of(context).textTheme.button?.copyWith(
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                ),
                onPressed: () => print('Tap Find button'),
              ),
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.lock,
                  size: 20,
                ),
                label: const Text('Elevated Button'),
                style: ElevatedButton.styleFrom(
                  primary: Theme.of(context).colorScheme.onPrimary,
                  onPrimary: Theme.of(context).colorScheme.primary,
                  textStyle: Theme.of(context).textTheme.button,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () => print('Tap Elevated Button'),
              ),
              Padding(
                child: ElevatedButton(
                  child: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).colorScheme.onSecondary,
                    onPrimary: Theme.of(context).colorScheme.secondary,
                    textStyle: Theme.of(context).textTheme.button,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, SetupPage2.routeName);
                  },
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ],
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24),
        ));
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

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          child: Text(
            'Setup WiFi name',
            style: Theme.of(context)
                .textTheme
                .headline4
                ?.copyWith(color: Theme.of(context).colorScheme.secondary),
          ),
          padding: const EdgeInsets.only(bottom: 8),
        ),
        TextField(
          controller: emailController,
          style: Theme.of(context).textTheme.bodyText1?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
          decoration: InputDecoration(
            hintText: 'Enter WiFi name',
            hintStyle: Theme.of(context)
                .textTheme
                .bodyText1
                ?.copyWith(color: Theme.of(context).colorScheme.surface),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.secondary, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.secondary, width: 1),
            ),
          ),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}
