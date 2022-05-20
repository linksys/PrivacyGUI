import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';

import '../components/base_components/button/primary_button.dart';
import '../components/base_components/button/simple_text_button.dart';
import '../components/base_components/input_fields/input_field.dart';
import '../components/layouts/basic_header.dart';
import '../components/layouts/basic_layout.dart';

class LoginCloudAccountView extends StatefulWidget {
  const LoginCloudAccountView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

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
          header: const BasicHeader(
            title: 'Log in or create your Linksys account',
          ),
          content: Column(
            children: [
              InputField(
                titleText: 'Mobile number or email',
                hintText: 'Mobile number or email',
                controller: _accountController,
                onChanged: _checkFilledInfo,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: DescriptionText(
                    text:
                        'We\'ll send you a confirmation code. Standard message and data rates apply.'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: PrimaryButton(
                  text: 'Continue',
                  onPress: widget.onNext,
                ),
              ),
              SimpleTextButton(
                  text: 'Skip and use router password only', onPressed: () {}),
              const Spacer(),
            ],
          ),
        ));
  }
}
