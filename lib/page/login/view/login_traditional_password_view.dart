import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';


class LoginTraditionalPasswordView extends StatelessWidget {
  LoginTraditionalPasswordView(
      {Key? key, required this.onNext, required this.onForgotPassword})
      : super(key: key);

  final void Function() onNext;
  final void Function() onForgotPassword;
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
            SimpleTextButton(
                text: 'Forgot password', onPressed: onForgotPassword),
            const SizedBox(
              height: 38,
            ),
            PrimaryButton(
              text: 'Continue',
              onPress: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
