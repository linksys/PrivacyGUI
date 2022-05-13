import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class CreateAccountView extends StatelessWidget {
  const CreateAccountView({
    Key? key,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  static const routeName = '/create_account';
  final void Function() onNext;
  final void Function() onSkip;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: PageContent(
        onNext: onNext,
        onSkip: onSkip,
      ),
      scrollable: true,
    );
  }
}

class PageContent extends StatefulWidget {
  const PageContent({
    Key? key,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  final void Function() onNext;
  final void Function() onSkip;

  @override
  _PageContentState createState() => _PageContentState();
}

class _PageContentState extends State<PageContent> {

  bool isValidData = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  void _checkFilledInfo(_) {
    setState(() {
      isValidData = emailController.text.isNotEmpty && mobileController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasicLayout(
      header: const BasicHeader(
        title: 'Add email and phone number to create a Linksys account',
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50, bottom: 27),
            child: InputField(
              titleText: 'Email Address',
              hintText: 'Enter email',
              controller: emailController,
              onChanged: _checkFilledInfo,
            ),
          ),
          InputField(
            titleText: 'Add a phone number (optional)',
            hintText: 'Enter mobile phone',
            controller: mobileController,
            onChanged: _checkFilledInfo,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: SimpleTextButton(
              text: 'Why do I need an account?',
              onPressed: () {
                //TODO: onPressed action
              },
            ),
          ),
          SimpleTextButton(
            text: 'I already have an account',
            onPressed: () {
              //TODO: onPressed action
            },
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      footer: Column(
        children: [
          Visibility(
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            visible: isValidData,
            child: PrimaryButton(
              text: 'Create account',
              onPress: widget.onNext,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          SecondaryButton(
            text: 'Not now',
            onPress: widget.onSkip,
          )
        ],
      ),
    );
  }
}