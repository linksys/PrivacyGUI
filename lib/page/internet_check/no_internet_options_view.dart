import 'package:flutter/material.dart';
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
        header: const BasicHeader(
          title: 'No internet connection',
        ),
        content: Column(
          children: [
            Offstage(
              offstage: !isSecondFailure,
              child: Column(
                children: [
                  OptionCard(
                    title: 'Contact Linksys support',
                    description: 'We’d love to help you',
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
              title: 'Restart your modem',
              description: 'Some ISPs require a fresh start to connect a new router',
              onPress: () {
                NavigationCubit.of(context).push(UnplugModemPath());
              },
            ),
            const SizedBox(
              height: 64,
            ),
            Text(
              'Or, your ISP settings require something else',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                  color: Theme.of(context).primaryColor
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            OptionCard(
              title: 'PPPoE',
              description: 'Enter the username and password for internet access',
              onPress: () {
                NavigationCubit.of(context).push(EnterIspSettingsPath());
              },
            ),
            const SizedBox(
              height: 16,
            ),
            OptionCard(
              title: 'Static IP Address',
              description: 'Enter your static IP address for internet access',
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