import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/option_card.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

class SelectIspSettingsView extends ConsumerWidget {
  const SelectIspSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ref
                    .read(navigationsProvider.notifier)
                    .push(EnterIspSettingsPath());
              },
            ),
            const SizedBox(
              height: 18,
            ),
            OptionCard(
              title: getAppLocalizations(context).static_ip_address,
              description:
                  getAppLocalizations(context).static_ip_card_description,
              onPress: () {
                ref
                    .read(navigationsProvider.notifier)
                    .push(EnterStaticIpPath());
              },
            ),
          ],
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}
