import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/option_card.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class SelectIspSettingsView extends StatelessWidget {
  const SelectIspSettingsView({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).enter_isp_settings,
        ),
        content: Column(
          children: [
            OptionCard(
              title: 'PPPoE',
              description: 'Enter the username and password for internet access',
              onPress: () {
                //TODO: Go to next page
              },
            ),
            const SizedBox(
              height: 18,
            ),
            OptionCard(
              title: 'Static IP Address',
              description: 'Enter your static IP address for internet access',
              onPress: () {
                //TODO: Go to next page
              },
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}