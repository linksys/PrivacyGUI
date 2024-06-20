import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqListView extends ArgumentsConsumerStatelessView {
  const FaqListView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StyledAppPageView(
      title: loc(context).faqs,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content: ListView(
          shrinkWrap: true,
          children: [
            _buildExpansionCard(
              title: loc(context).setup,
              children: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextButton(loc(context).faqListCannotAddChildNode,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333430#Q1PlaceNodes');
                  }),
                  AppTextButton(loc(context).noInternetConnectionTitle,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=48464');
                  }),
                ],
              ),
            ),
            const AppGap.small2(),
            _buildExpansionCard(
              title: loc(context).connectivity,
              children: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextButton(loc(context).faqListLoseChildNode, onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333430#Q2NodeConnection');
                  }),
                  AppTextButton(loc(context).faqListLoseDevices, onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333430#Q3DeviceConnection');
                  }),
                  AppTextButton(loc(context).faqListDeviceNoWiFi, onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=316292');
                  }),
                  AppTextButton(loc(context).faqListDeviceNoBestNode,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333430#Q4DeviceNode');
                  }),
                ],
              ),
            ),
            const AppGap.small2(),
            _buildExpansionCard(
              title: loc(context).speed,
              children: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextButton(loc(context).faqListMyInternetSlow, onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333431#q2');
                  }),
                  AppTextButton(loc(context).faqListSpecificDeviceSlow,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333431#q3');
                  }),
                  AppTextButton(loc(context).faqListSlowAfterAddNode,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333431#q4');
                  }),
                ],
              ),
            ),
            const AppGap.small2(),
            _buildExpansionCard(
              title: loc(context).passwordAndAccess,
              children: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextButton(loc(context).faqListLogInByRouterPassword,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333431#q2');
                  }),
                  AppTextButton(loc(context).faqListForgotRouterPassword,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=274484#q4');
                  }),
                  AppTextButton(loc(context).faqListChangeWiFiNamePassword,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=203471');
                  }),
                  AppTextButton(loc(context).faqListAccessByWebBrowser,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=274484#q3');
                  }),
                ],
              ),
            ),
            const AppGap.small2(),
            _buildExpansionCard(
              title: loc(context).hardware,
              children: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextButton(loc(context).faqListWhatLightsMean, onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=217443');
                  }),
                  AppTextButton(loc(context).faqListHowToFactoryReset,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=224178');
                  }),
                  AppTextButton(loc(context).faqListNodeKeepRestarting,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333429#Restarting');
                  }),
                  AppTextButton(loc(context).faqListLightsNotWorking,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333429#LightNotWorking');
                  }),
                  AppTextButton(loc(context).faqListNodeNotTurnOn, onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333429#NotTurningOn');
                  }),
                  AppTextButton(loc(context).faqListEthernetPortNotWorking,
                      onTap: () {
                    _launchUrl(
                        'https://www.linksys.com/us/support-article?articleNum=333429#PortsNotWorking');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppExpansionCard _buildExpansionCard({
    required String title,
    required Widget children,
  }) {
    return AppExpansionCard(
      title: title,
      expandedIcon: LinksysIcons.add,
      collapsedIcon: LinksysIcons.remove,
      children: [
        Row(
          children: [
            children,
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      logger.e('[Support]: Could not launch url: $url');
    }
  }
}
