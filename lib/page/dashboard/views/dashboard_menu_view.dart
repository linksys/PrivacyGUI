import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/providers/auth/auth_provider.dart';
import 'package:linksys_app/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:linksys_app/page/select_network/providers/select_network_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/panel/custom_animated_box.dart';
import 'package:linksys_widgets/widgets/panel/general_card.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';

class DashboardMenuView extends ConsumerStatefulWidget {
  const DashboardMenuView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardMenuView> createState() => _DashboardMenuViewState();
}

class _DashboardMenuViewState extends ConsumerState<DashboardMenuView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardHomeState = ref.watch(dashboardHomeProvider);
    final hasMultiNetworks =
        ref.watch(selectNetworkProvider).when(data: (state) {
      return state.networks.length > 1;
    }, error: (error, stackTrace) {
      return false;
    }, loading: () {
      return false;
    }); // .networks.length > 1;

    return AppPageView.noNavigationBar(
      // scrollable: true,
      child: SizedBox(
        // width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.extraBig(),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: AppCard(
                      // Get image by master node's model number
                      image: CustomTheme.of(context).images.devices.getByName(
                            routerIconTest(
                              modelNumber: ref
                                      .read(deviceManagerProvider)
                                      .deviceList
                                      .firstOrNull
                                      ?.model
                                      .modelNumber ??
                                  '',
                            ),
                          ),
                      maxWidth: 120,
                      maxHeight: 120,
                      minHeight: 60,
                      minWidth: 60),
                ),
                const AppGap.regular(),
                InkWell(
                  onTap: hasMultiNetworks
                      ? () {
                          ref
                              .read(selectNetworkProvider.notifier)
                              .refreshCloudNetworks();

                          _navigateTo(RouteNamed.selectNetwork);
                        }
                      : null,
                  child: Row(
                    children: [
                      AppText.titleMedium(
                        dashboardHomeState.mainWifiSsid,
                        overflow: TextOverflow.fade,
                      ),
                      if (hasMultiNetworks)
                        AppIcon.regular(
                          icon: getCharactersIcons(context).chevronDown,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const AppGap.big(),
            Expanded(child: _buildDeviceGridView(createMenuItems())),
            // const Spacer(),
            // AppTextButton.noPadding('About Linksys', onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceGridView(List<AppSectionItemData> items) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isMobile(context) ? 2 : 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: (3 / 2),
      ),
      physics: const ScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return CustomAnimatedBox(
            value: false,
            selectable: false,
            onChanged: (value) {},
            child: _buildDeviceGridCell(items[index]));
      },
    );
  }

  Widget _buildDeviceGridCell(AppSectionItemData item) {
    return GestureDetector(
      onTap: item.onTap,
      child: AppCard(
        iconData: item.iconData,
        title: item.title,
        description: item.description,
        alignCenter: false,
      ),
    );
  }

  List<AppSectionItemData> createMenuItems() {
    final isCloudLogin =
        ref.read(authProvider).value?.loginType == LoginType.remote;
    return [
      AppSectionItemData(
          title: 'Settings',
          description: 'This is a description for this tile',
          iconData: getCharactersIcons(context).settingsDefault,
          onTap: () {
            _navigateTo(RouteNamed.dashboardSettings);
          }),
      AppSectionItemData(
          title: 'Safe Browsing',
          description: 'This is a description for this tile',
          iconData: getCharactersIcons(context).shieldDefault,
          onTap: () {
            _navigateTo(RouteNamed.safeBrowsing);
          }),
      AppSectionItemData(
          title: 'Speed Test',
          description: 'This is a description for this tile',
          iconData: getCharactersIcons(context).securityDefault,
          onTap: () {
            _navigateTo(RouteNamed.speedTestSelection);
          }),
      AppSectionItemData(
          title: 'Troubleshooting',
          description: 'This is a description for this tile',
          iconData: getCharactersIcons(context).healthDefault,
          onTap: () {
            _navigateTo(RouteNamed.troubleshooting);
          }),
      AppSectionItemData(
          title: 'DDNS Settings',
          description: 'This is a description for this tile',
          iconData: getCharactersIcons(context).healthDefault,
          onTap: () {
            _navigateTo(RouteNamed.settingsDDNS);
          }),
      AppSectionItemData(
          title: 'Ipv6 Port Service',
          description: 'This is a description for this tile',
          iconData: getCharactersIcons(context).healthDefault,
          onTap: () {
            _navigateTo(RouteNamed.ipv6PortServiceList);
          }),
      AppSectionItemData(
          title: 'Channel Finder',
          description: 'This is a description for this tile',
          iconData: getCharactersIcons(context).healthDefault,
          onTap: () {
            _navigateTo(RouteNamed.channelFinderOptimize);
          }),
      if (isCloudLogin)
        AppSectionItemData(
            title: 'Account',
            description: 'This is a description for this tile',
            iconData: getCharactersIcons(context).administrationDefault,
            onTap: () {
              _navigateTo(RouteNamed.accountInfo);
            }),
      AppSectionItemData(
          title: 'Help',
          description: 'This is a description for this tile',
          iconData: getCharactersIcons(context).helpRound),
      // AppSectionItemData(
      //     title: 'Linksys LinkUp',
      //     iconData: getCharactersIcons(context).bellDefault,
      //     onTap: () {
      //       _navigateTo(RouteNamed.linkup);
      //     }),
    ];
  }

  void _navigateTo(String name) {
    if (kIsWeb) {
      if (shellNavigatorKey.currentContext!.canPop()) {
        shellNavigatorKey.currentContext!.pushReplacementNamed(name);
      } else {
        shellNavigatorKey.currentContext!.pushNamed(name);
      }
    } else {
      shellNavigatorKey.currentContext!.pushNamed(name);
    }
  }
}
