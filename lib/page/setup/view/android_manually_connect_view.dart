import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/_route.dart';


import '../../components/layouts/basic_header.dart';
import 'info_setup_ssid_view.dart';
import 'package:linksys_moab/route/model/_model.dart';

class AndroidManuallyConnectView extends StatelessWidget {
  AndroidManuallyConnectView({Key? key})
      : super(key: key);

  final Widget img =
      Image.asset("assets/images/android_wifi_manually_connect.png", width: 253, height: 350);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title:
              getAppLocalizations(context).android_manually_connect_view_title,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DescriptionText(
                text: getAppLocalizations(context)
                    .android_manually_connect_view_description),
            const SizedBox(height: 18),
            SimpleTextButton(
                text: getAppLocalizations(context).show_me,
                onPressed: () => _goToShowMePage(context)),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                img
              ],
            )
          ],
        ),
        footer: PrimaryButton(
            text: getAppLocalizations(context).am_connected,
            onPress: (){
              NavigationCubit.of(context).push(AndroidLocationPermissionPrimerPath());
            }),
      ),
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
