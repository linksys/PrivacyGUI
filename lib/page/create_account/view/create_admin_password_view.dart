import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class CreateAdminPasswordView extends StatelessWidget {
  const CreateAdminPasswordView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: _PageContent(
        onNext: onNext,
      ),
      scrollable: true,
    );
  }
}

class _PageContent extends StatefulWidget {
  const _PageContent({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  _PageContentState createState() => _PageContentState();
}

class _PageContentState extends State<_PageContent> {
  bool isValidData = false;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController hintController = TextEditingController();

  void _checkInputData(_) {
    setState(() {
      isValidData =
          passwordController.text.isNotEmpty && hintController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasicLayout(
      header: const BasicHeader(
        title: 'Okay, you’ll need an admin password',
        description:
            'An admin password will allow you to access your router settings',
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 36, bottom: 37),
            child: InputField(
              titleText: 'Password',
              hintText: 'Enter Password',
              controller: passwordController,
              onChanged: _checkInputData,
            ),
          ),
          InputField(
            titleText: 'Password hint (optional)',
            hintText: 'Add a hint',
            controller: hintController,
            onChanged: _checkInputData,
          ),
          const SizedBox(
            height: 100,
          ),
          SimpleTextButton(
              text: 'How do I access my router?',
              onPressed: () {
                //TODO: onPressed action
              })
        ],
      ),
      footer: Visibility(
        visible: isValidData,
        child: PrimaryButton(
          text: 'Next',
          onPress: widget.onNext,
        ),
      ),
      alignment: CrossAxisAlignment.start,
    );
  }
}
