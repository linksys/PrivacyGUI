import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/providers/auth/auth_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/card/menu_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

import 'package:linksys_widgets/widgets/panel/custom_animated_box.dart';
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
    return StyledAppPageView(
      // scrollable: true,
      backState: StyledBackState.none,
      title: 'Menu',
      menu: PageMenu(title: 'My Network', items: [
        PageMenuItem(label: 'Restart', icon: Icons.refresh),
        PageMenuItem(label: 'Setup a new Product', icon: Icons.add)
      ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildMenuGridView(createMenuItems())),
          // const Spacer(),
          // AppTextButton.noPadding('About Linksys', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildMenuGridView(List<AppSectionItemData> items) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isOverBreakpoint4(context) ? 3 : 2,
        mainAxisSpacing: 0,
        crossAxisSpacing: 16,
        childAspectRatio: (3 / 2),
        mainAxisExtent: 120,
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
      child: AppMenuCard(
        iconData: item.iconData,
        title: item.title,
        description: item.description,
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
