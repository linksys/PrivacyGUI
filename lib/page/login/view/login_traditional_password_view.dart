import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';

// TODO nobody use this
class LoginTraditionalPasswordView extends StatelessWidget {
  LoginTraditionalPasswordView({
    Key? key,
  }) : super(key: key);

  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Enter password',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputField(
                titleText: 'Password',
                hintText: 'Password',
                controller: passwordController),
            const SizedBox(
              height: 15,
            ),
            SimpleTextButton(text: 'Forgot password', onPressed: () {}),
            const SizedBox(
              height: 38,
            ),
            PrimaryButton(
              text: 'Continue',
              onPress: () {},
            ),
          ],
        ),
      ),
    );
  }
}