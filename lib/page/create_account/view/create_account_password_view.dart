import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

// TODO nobody use this
class CreateAccountPasswordView extends StatelessWidget {
  const CreateAccountPasswordView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: PageContent(
        onNext: onNext,
      )
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

  bool isValidPassword = false;
  final TextEditingController passwordController = TextEditingController();

  void _checkPassword(String text) {
    setState(() {
      isValidPassword = text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasicLayout(
      header: const BasicHeader(
        title: 'Create a password',
        description: 'You’ll use this password to log in to the app',
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: InputField(
          titleText: 'Enter password',
          controller: passwordController,
          onChanged: _checkPassword,
        ),
      ),
      footer: Visibility(
        visible: isValidPassword,
        child: PrimaryButton(
          text: 'Next',
          onPress: widget.onNext,
        ),
      ),
      alignment: CrossAxisAlignment.start,
    );
  }
}