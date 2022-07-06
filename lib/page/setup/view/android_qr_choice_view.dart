import 'package:flutter/material.dart';
import 'package:moab_poc/channel/wifi_connect_channel.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/route/route.dart';

import '../../components/layouts/basic_layout.dart';
import 'package:moab_poc/route/model/model.dart';

class AndroidQRChoiceView extends StatelessWidget {
  AndroidQRChoiceView({Key? key}) : super(key: key);

  final Widget img = Image.asset('assets/images/android_scan_qrcode.png');

  Future<void> _connectToWIFI(BuildContext context) async {
    await NativeConnectWiFiChannel().connectToWiFi(ssid: "", password: "");
    Future.delayed(const Duration(seconds: 2), (){
      NavigationCubit.of(context).push(AndroidLocationPermissionPrimerPath());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
            title: AppLocalizations.of(context)!.android_qr_choice_view_title),
        content: Center(child: img),
        footer: Column(
          children: [
            PrimaryButton(
                text: AppLocalizations.of(context)!
                    .android_qr_choice_view_primary_button_text,
                onPress: () => _connectToWIFI(context)),
            const SizedBox(height: 11),
            SecondaryButton(
                text: AppLocalizations.of(context)!
                    .android_qr_choice_view_secondary_button_text,
                onPress: (){})
          ],
        ),
      ),
    );
  }
}
