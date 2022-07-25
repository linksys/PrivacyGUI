import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/option_card.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/model/internet_check_path.dart';
import 'package:moab_poc/route/navigation_cubit.dart';

class NoInternetOptionsView extends StatefulWidget {
  const NoInternetOptionsView({Key? key}): super(key: key);

  @override
  State<NoInternetOptionsView> createState() => _NoInternetOptionsViewState();
}

class _NoInternetOptionsViewState extends State<NoInternetOptionsView> {
  bool isSecondFailure = false;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).no_internet_connection_title,
        ),
        content: Column(
          children: [
            Offstage(
              offstage: !isSecondFailure,
              child: Column(
                children: [
                  OptionCard(
                    title: getAppLocalizations(context).contact_linksys_support_card_title,
                    description: getAppLocalizations(context).contact_linksys_support_card_description,
                    onPress: () {
                      NavigationCubit.of(context).push(LinksysSupportRegionPath());
                    },
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                ],
              ),
            ),
            OptionCard(
              title: getAppLocalizations(context).restart_modem_card_title,
              description: getAppLocalizations(context).restart_modem_card_description,
              onPress: () {
                NavigationCubit.of(context).push(UnplugModemPath());
              },
            ),
            const SizedBox(
              height: 64,
            ),
            Text(
              getAppLocalizations(context).no_internet_alternative,
              style: Theme.of(context).textTheme.headline3?.copyWith(
                  color: Theme.of(context).primaryColor
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            OptionCard(
              title: getAppLocalizations(context).pppoe,
              description: getAppLocalizations(context).pppoe_card_description,
              onPress: () {
                NavigationCubit.of(context).push(EnterIspSettingsPath());
              },
            ),
            const SizedBox(
              height: 16,
            ),
            OptionCard(
              title: getAppLocalizations(context).static_ip_address,
              description: getAppLocalizations(context).static_ip_card_description,
              onPress: () {
                NavigationCubit.of(context).push(EnterStaticIpPath());
              },
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}