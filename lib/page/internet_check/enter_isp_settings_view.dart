import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class EnterIspSettingsView extends StatefulWidget {
  const EnterIspSettingsView({Key? key}): super(key: key);

  @override
  State<EnterIspSettingsView> createState() => _EnterIspSettingsViewState();
}

class _EnterIspSettingsViewState extends State<EnterIspSettingsView> {
  final TextEditingController accountController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController vLandIdController = TextEditingController();
  bool hasError = false;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Enter ISP settings provided by your ISP',
        ),
        content: Column(
          children: [
            Offstage(
              offstage: !hasError,
              child: Column(
                children: [
                  Text(
                    'Account name and/or password incorrect. Please check and try again, or contact your ISP for support',
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        color: Colors.red
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  )
                ],
              ),
            ),
            InputField(
              titleText: 'Account name',
              controller: accountController,
              isError: hasError,
              onChanged: (text) {
                setState(() {
                  hasError = false;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: PasswordInputField(
                titleText: getAppLocalizations(context).password,
                controller: passwordController,
                isError: hasError,
                onChanged: (text) {
                  setState(() {
                    hasError = false;
                  });
                },
              ),
            ),
            InputField(
              titleText: 'VLAND(optional)',
              controller: vLandIdController,
            ),
          ],
        ),
        footer: PrimaryButton(
          text: getAppLocalizations(context).next,
          onPress: () {
            //TODO: Go to next page
          },
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}