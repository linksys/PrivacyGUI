import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/button/simple_text_button.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/input_field.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';

// TODO nobody use this
class EnterSetupCodeView extends StatelessWidget {
  const EnterSetupCodeView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: _PageContent(),
    );
  }
}

class _PageContent extends StatefulWidget {
  const _PageContent({
    Key? key,
  }) : super(key: key);

  @override
  _PageContentState createState() => _PageContentState();
}

class _PageContentState extends State<_PageContent> {

  bool isValidCode = false;
  final TextEditingController tfController = TextEditingController();

  void _checkCode(String code) {
    setState(() {
      isValidCode = code.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasicLayout(
      header: const BasicHeader(
        title: 'Okay, enter the setup code located at the bottom of your node',
      ),
      content: Column(
        children: [
          InputField(
            titleText: 'Setup code',
            hintText: 'Enter setup code',
            controller: tfController,
            onChanged: _checkCode,
          ),
        ],
      ),
      footer: Column(
        children: [
          SimpleTextButton(
            text: 'Where do I find this?',
            onPressed: () {
              //TODO: onPressed action
            },
          ),
          const SizedBox(
            height: 90,
          ),
          Visibility(
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            visible: isValidCode,
            child: PrimaryButton(
              text: 'Next',
              onPress: () {},
            ),
          ),
        ],
      ),
    );
  }
}
