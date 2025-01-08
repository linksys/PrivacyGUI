import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/views/components/remote_assistance_widget.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:privacy_gui/core/utils/extension.dart';

class FaqListView extends ArgumentsConsumerStatefulView {
  const FaqListView({super.key});

  @override
  ConsumerState<FaqListView> createState() => _FaqListViewState();
}

class _FaqListViewState extends ConsumerState<FaqListView> {
  @override
  void initState() {
    super.initState();
    ref.read(menuController).setTo(NaviType.support);
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).faqs,
      backState: StyledBackState.none,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      menuWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodySmall(loc(context).faqLookingFor),
          const AppGap.medium(),
          AppTextButton.noPadding(
            loc(context).faqVisitLinksysSupport,
            identifier: 'now-faq-link-${'faqVisitLinksysSupport'.kebab()}',
            onTap: () {
              gotoOfficialWebUrl(linkSupport,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
          // const AppGap.large2(),
          // RemoteAssistanceWidget(
          //   child: Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: AppText.labelMedium(
          //       'Remote Assistance (PoC)',
          //       color: Theme.of(context).colorScheme.primary,
          //     ),
          //   ),
          // )
        ],
      ),
      menuOnRight: true,
      child: SizedBox(
        width: 9.col,
        child: ListView(
          shrinkWrap: true,
          children: [
            _buildExpansionCard(
              title: loc(context).setup,
              children: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextButton(loc(context).faqListCannotAddChildNode,
                      identifier:
                          'now-faq-${'faqListCannotAddChildNode'.kebab()}',
                      onTap: () {
                    gotoOfficialWebUrl(linkSetupCannotAddChildNode,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).noInternetConnectionTitle,
                      identifier:
                          'now-faq-${'noInternetConnectionTitle'.kebab()}',
                      onTap: () {
                    gotoOfficialWebUrl(linkSetupNoInternetConnection,
                        locale: ref.read(appSettingsProvider).locale);
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
                    gotoOfficialWebUrl(linkConnectivityLoseChildNode,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListLoseDevices, onTap: () {
                    gotoOfficialWebUrl(linkConnectivityLoseChildNode,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListDeviceNoWiFi, onTap: () {
                    gotoOfficialWebUrl(linkConnectivityDeviceNoWiFi,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListDeviceNoBestNode,
                      onTap: () {
                    gotoOfficialWebUrl(linkConnectivityDeviceNoBestNode,
                        locale: ref.read(appSettingsProvider).locale);
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
                    gotoOfficialWebUrl(linkSpeedMyInternetSlow,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListSpecificDeviceSlow,
                      onTap: () {
                    gotoOfficialWebUrl(linkSpeedSpecificDeviceSlow,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListSlowAfterAddNode,
                      onTap: () {
                    gotoOfficialWebUrl(linkSpeedSlowAfterAddNode,
                        locale: ref.read(appSettingsProvider).locale);
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
                    gotoOfficialWebUrl(linkPasswordLoginByRouterPassword,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListForgotRouterPassword,
                      onTap: () {
                    gotoOfficialWebUrl(linkPasswordForgotRouterPassword,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListChangeWiFiNamePassword,
                      onTap: () {
                    gotoOfficialWebUrl(linkPasswordChangeWiFiNamePassword,
                        locale: ref.read(appSettingsProvider).locale);
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
                    gotoOfficialWebUrl(linkHardwareWhatLightMean,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListHowToFactoryReset,
                      onTap: () {
                    gotoOfficialWebUrl(linkHardwareHowToFactoryReset,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListLightsNotWorking,
                      onTap: () {
                    gotoOfficialWebUrl(linkHardwareLightsNotWorking,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListNodeNotTurnOn, onTap: () {
                    gotoOfficialWebUrl(linkHardwareNodeNotTureOn,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListEthernetPortNotWorking,
                      onTap: () {
                    gotoOfficialWebUrl(linkHardwareEthernetPortNotWorking,
                        locale: ref.read(appSettingsProvider).locale);
                  }),
                  AppTextButton(loc(context).faqListCheckIfFirmwareAutoUpdate,
                      onTap: () {
                    gotoOfficialWebUrl(linkCheckIfAutoFirmwareOn,
                        locale: ref.read(appSettingsProvider).locale);
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
      identifier: 'now-faq-${title.kebab()}',
      expandedIcon: LinksysIcons.add,
      collapsedIcon: LinksysIcons.remove,
      children: [
        Row(
          children: [
            children,
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
