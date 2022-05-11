import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class EnterSetupCodeView extends StatelessWidget {
  EnterSetupCodeView({Key? key}) : super(key: key);

  static const routeName = '/enter_setup_code';

  final TextEditingController tfController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Okay, enter the setup code located at the bottom of your node',
        ),
        content: Column(
          children: [
            InputField(
              titleText: 'Setup code',
              hintText: 'Enter setup code',
              controller: tfController,
            ),
          ],
        ),
        footer: Padding(
          padding: const EdgeInsets.only(bottom: 180),
          child: SimpleTextButton(
            text: 'Where do I find this?',
            onPressed: () {
              //TODO: onPressed action
            },
          ),
        ),
        alignment: CrossAxisAlignment.center,
      ),
    );
  }
}

