import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';


class LoginCloudAccountView extends StatefulWidget {
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
  _LoginCloudAccountState createState() => _LoginCloudAccountState();
}

class _LoginCloudAccountState extends State<LoginCloudAccountView> {
  bool isValidWifiInfo = false;
  final TextEditingController _accountController = TextEditingController();

  void _checkFilledInfo(_) {
    setState(() {
      isValidWifiInfo = _accountController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              ),
              Row(
                children: [
                  SimpleTextButton(
                      text: 'Forgot email', onPressed: widget.onForgotEmail),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: PrimaryButton(
                  text: 'Continue',
                  onPress: widget.onNext,
                ),
              ),
              SimpleTextButton(
                  text: 'Log in with router password',
                  onPressed: widget.onLocalLogin),
              const Spacer(),
            ],
          ),
        ));
  }
}
