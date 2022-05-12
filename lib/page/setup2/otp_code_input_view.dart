import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class OtpCodeInputView extends StatelessWidget {
  OtpCodeInputView({
    Key? key,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  final void Function() onNext;
  final void Function() onSkip;
  final TextEditingController codeController = TextEditingController();

  void _checkOtpCode(String text) {
    if (text.length >= 6) {
      onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Enter the one-time code sent',
          description: 'A one-time code will be sent to you every time you need to log in to the app',
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: InputField(
            titleText: 'Enter code',
            controller: codeController,
            onChanged: _checkOtpCode,
          ),
        ),
        footer: SecondaryButton(
          text: 'Create a password instead',
          onPress: onSkip,
        ),
      ),
    );
  }
}
