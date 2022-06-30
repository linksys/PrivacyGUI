import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SetupFinishedView extends StatelessWidget {
  SetupFinishedView({
    Key? key,
    required this.wifiSsid,
    required this.wifiPassword,
    required this.onNext,
  }) : super(key: key);

  final String wifiSsid;
  final String wifiPassword;
  final void Function() onNext;

  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  final Widget wifiIcon = Image.asset('assets/images/wifi_logo_grey.png');
  final Widget lockIcon = Image.asset('assets/images/lock_icon.png');
  final Widget portraitIcon = Image.asset('assets/images/portrait_icon.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: AppLocalizations.of(context)!.wifi_ready_view_title,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 48,
              ),
              DescriptionText(text: AppLocalizations.of(context)!.wifi_ready_view_connect_to),
              const SizedBox( height: 8),
              infoCard(context, wifiIcon, AppLocalizations.of(context)!.wifi_name, "MyHomeWiFi"),
              const SizedBox( height: 8),
              infoCard(context, lockIcon, AppLocalizations.of(context)!.wifi_password, "ThisIsMyStrongPassword123"),
              const SizedBox( height: 58),
              DescriptionText(text: AppLocalizations.of(context)!.wifi_ready_view_login_info),
              const SizedBox(height: 8),
              infoCard(context, portraitIcon, AppLocalizations.of(context)!.linksys_account, "myemail@email.com"),
            ],
        ),
        footer: PrimaryButton(
          text: AppLocalizations.of(context)!.go_to_dashboard,
          onPress: onNext,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}

Widget infoCard(BuildContext context, Widget image, String title, String content){
  return Container(
    padding: const EdgeInsets.all(19),
    color: Theme.of(context).colorScheme.secondary,
    child: Row(
      children: [
        image,
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headline4?.copyWith(color: Colors.white)),
            DescriptionText(text: content)
          ],
        )
      ],
    ),
  );
}