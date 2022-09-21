import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class UnplugModemView extends StatelessWidget {
  const UnplugModemView({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).unplug_modem_title,
        ),
        content: Image.asset(
          'assets/images/unplug_modem.png',
          alignment: Alignment.topLeft,
        ),
        footer: Column(
          children: [
            SimpleTextButton(
              text: getAppLocalizations(context).unplug_modem_troubleshooting_link,
              onPressed: () {
                NavigationCubit.of(context).push(LearnBatteryModemPath());
              },
            ),
            const SizedBox(
              height: 16,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).next,
              onPress: () {
                NavigationCubit.of(context).push(WaitModemDisconnectPath());
              },
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}