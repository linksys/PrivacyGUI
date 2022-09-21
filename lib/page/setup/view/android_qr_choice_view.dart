import 'package:flutter/material.dart';
import 'package:linksys_moab/channel/wifi_connect_channel.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/button/secondary_button.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/_route.dart';


import '../../components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/_model.dart';

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
            title: getAppLocalizations(context).android_qr_choice_view_title),
        content: Center(child: img),
        footer: Column(
          children: [
            PrimaryButton(
                text: getAppLocalizations(context)
                    .android_qr_choice_view_primary_button_text,
                onPress: () => _connectToWIFI(context)),
            const SizedBox(height: 11),
            SecondaryButton(
                text: getAppLocalizations(context)
                    .android_qr_choice_view_secondary_button_text,
                onPress: (){})
          ],
        ),
      ),
    );
  }
}
