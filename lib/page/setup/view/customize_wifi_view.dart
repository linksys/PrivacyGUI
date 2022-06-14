import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class CustomizeWifiView extends StatelessWidget {
  const CustomizeWifiView({
    Key? key,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  static const routeName = '/customize_wifi';
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

  bool isValidWifiInfo = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _checkFilledInfo(_) {
    setState(() {
      isValidWifiInfo = nameController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasicLayout(
      header: const BasicHeader(
        title: 'Customize WiFi name and password',
        description: 'Make it memorable. This is what devices will use to connect to your WiFi network.',
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 36, bottom: 24),
            child: InputField(
              titleText: 'WiFi name',
              controller: nameController,
              onChanged: _checkFilledInfo,
            ),
          ),
          InputField(
            titleText: 'Password',
            controller: passwordController,
            onChanged: _checkFilledInfo,
          ),
        ],
      ),
      footer: Visibility(
        visible: isValidWifiInfo,
        replacement: SecondaryButton(
          text: 'I’ll do it later',
          onPress: widget.onSkip,
        ),
        child: PrimaryButton(
          text: 'Next',
          onPress: widget.onNext,
        ),
      ),
    );
  }
}