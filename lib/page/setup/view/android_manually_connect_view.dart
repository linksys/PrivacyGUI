import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../components/layouts/basic_header.dart';
import 'info_setup_ssid_view.dart';

class AndroidManuallyConnectView extends StatelessWidget {
  AndroidManuallyConnectView({Key? key, required this.onConnected})
      : super(key: key);

  final VoidCallback onConnected;
  final Widget img =
      Image.asset("assets/images/android_wifi_manually_connect.png", width: 253, height: 350);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title:
              AppLocalizations.of(context)!.android_manually_connect_view_title,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DescriptionText(
                text: AppLocalizations.of(context)!
                    .android_manually_connect_view_description),
            const SizedBox(height: 18),
            SimpleTextButton(
                text: AppLocalizations.of(context)!.show_me,
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
            text: AppLocalizations.of(context)!.am_connected,
            onPress: onConnected),
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
