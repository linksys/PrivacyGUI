import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/design/colors.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/route/model/model.dart';

class SetupFinishedView extends ArgumentsStatelessView {

  SetupFinishedView({
    Key? key, super.args
  }) : super(key: key);


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
          title: getAppLocalizations(context).wifi_ready_view_title,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 48,
              ),
              DescriptionText(text: getAppLocalizations(context).wifi_ready_view_connect_to),
              const SizedBox( height: 8),
              infoCard(context, wifiIcon, getAppLocalizations(context).wifi_name, "MyHomeWiFi"),
              const SizedBox( height: 8),
              infoCard(context, lockIcon, getAppLocalizations(context).wifi_password, "ThisIsMyStrongPassword123"),
              const SizedBox( height: 58),
              DescriptionText(text: getAppLocalizations(context).wifi_ready_view_login_info),
              const SizedBox(height: 8),
              infoCard(context, portraitIcon, getAppLocalizations(context).linksys_account, "myemail@email.com"),
            ],
        ),
        footer: PrimaryButton(
          text: getAppLocalizations(context).go_to_dashboard,
          onPress: () => NavigationCubit.of(context).popTo(DashboardMainPath()),
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}

Widget infoCard(BuildContext context, Widget image, String title, String content){
  return Container(
    padding: const EdgeInsets.all(19),
    color: MoabColor.setupFinishCardBackground,
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