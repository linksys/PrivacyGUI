import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/option_card.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/model/internet_check_path.dart';
import 'package:moab_poc/route/navigation_cubit.dart';

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
              title: getAppLocalizations(context).pppoe,
              description: getAppLocalizations(context).pppoe_card_description,
              onPress: () {
                NavigationCubit.of(context).push(EnterIspSettingsPath());
              },
            ),
            const SizedBox(
              height: 18,
            ),
            OptionCard(
              title: getAppLocalizations(context).static_ip_address,
              description: getAppLocalizations(context).static_ip_card_description,
              onPress: () {
                NavigationCubit.of(context).push(EnterStaticIpPath());
              },
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}