import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../components/base_components/button/simple_text_button.dart';
import '../../components/base_components/input_fields/input_field.dart';
import 'info_setup_ssid_view.dart';

class EnterSetupSSIDView extends StatefulWidget {
  const EnterSetupSSIDView(
      {Key? key, required this.onNext})
      : super(key: key);

  final VoidCallback onNext;

  @override
  State<EnterSetupSSIDView> createState() => _EnterSetupSSIDViewState();
}

class _EnterSetupSSIDViewState extends State<EnterSetupSSIDView> {
  bool isValidWifiInfo = false;
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _checkFilledInfo(_) {
    setState(() {
      isValidWifiInfo =
          ssidController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
          header: BasicHeader(
            title: getAppLocalizations(context).enter_setup_ssid_view_title,
          ),
          content: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 36, bottom: 24),
                child: InputField(
                  titleText: getAppLocalizations(context).setup_wifi_name,
                  controller: ssidController,
                  onChanged: _checkFilledInfo,
                ),
              ),
              InputField(
                titleText: getAppLocalizations(context).setup_password,
                controller: passwordController,
                onChanged: _checkFilledInfo,
              ),
              const SizedBox(
                height: 150,
              ),
              SimpleTextButton(text: getAppLocalizations(context).where_do_i_find_this, onPressed: () => _goToShowMePage(context)),
            ],
          ),
          footer: Visibility(
            visible: isValidWifiInfo,
            child: PrimaryButton(
              text: getAppLocalizations(context).next,
              onPress: widget.onNext,
            ),
          )),
    );
  }

  void _goToShowMePage(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return InfoSetupSSIDView();
        });
  }
}
