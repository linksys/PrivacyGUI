import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class ManualEnterSSIDView extends StatelessWidget {
  const ManualEnterSSIDView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: PageContent(
        onNext: onNext,
      ),
      scrollable: true,
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
  bool isValidWifiInfo = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _checkFilledInfo(_) {
    setState(() {
      isValidWifiInfo =
          nameController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasicLayout(
      header: const BasicHeader(
        title: 'Okay, enter the setup WiFi and password located at the bottom of your parent node',
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 36, bottom: 24),
            child: InputField(
              titleText: 'Setup WiFi name',
              hintText: 'Enter WiFi name',
              controller: nameController,
              onChanged: _checkFilledInfo,
            ),
          ),
          InputField(
            titleText: 'Setup Password',
            hintText: 'Enter password',
            controller: passwordController,
            onChanged: _checkFilledInfo,
          ),
          const Spacer(),
          // TODO: Add on press method
          SimpleTextButton(text: 'Where do I find this?', onPressed: () {}),
          const Spacer(),
        ],
      ),
      footer: Visibility(
        visible: isValidWifiInfo,
        child: PrimaryButton(
          text: 'Next',
          onPress: widget.onNext,
        ),
      ),
    );
  }
}
