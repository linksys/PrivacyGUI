import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class EnterSetupCodeView extends StatelessWidget {
  const EnterSetupCodeView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  static const routeName = '/enter_setup_code';
  final void Function() onNext;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: PageContent(
        onNext: onNext,
      ),
    );
  }
}

class PageContent extends StatefulWidget {
  const PageContent({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  _PageContentState createState() => _PageContentState();
}

class _PageContentState extends State<PageContent> {

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
              onPress: widget.onNext,
            ),
          ),
        ],
      ),
    );
  }
}
