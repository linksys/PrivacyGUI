import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

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

  void _checkCredentials() {
    if (accountController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        hasError = true;
      });
    } else {
      NavigationCubit.of(context).push(InternetConnectedPath());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).enter_isp_settings_title,
        ),
        content: Column(
          children: [
            Offstage(
              offstage: !hasError,
              child: Column(
                children: [
                  Text(
                    getAppLocalizations(context).enter_isp_settings_error,
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
              titleText: getAppLocalizations(context).account_name,
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
              titleText: getAppLocalizations(context).vlan_id,
              controller: vLandIdController,
            ),
          ],
        ),
        footer: PrimaryButton(
          text: getAppLocalizations(context).next,
          onPress: _checkCredentials,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}