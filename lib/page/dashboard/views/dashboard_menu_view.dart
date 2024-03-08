import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/topology/providers/topology_provider.dart';
import 'package:linksys_app/providers/auth/auth_provider.dart';
import 'package:linksys_app/providers/root/root_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_widgets/widgets/buttons/button.dart';
import 'package:linksys_widgets/widgets/card/menu_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

import 'package:linksys_widgets/widgets/panel/custom_animated_box.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';
import 'package:linksys_widgets/widgets/text/app_text.dart';
import 'package:material_symbols_icons/symbols.dart';

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
        PageMenuItem(
            label: 'Restart Network',
            icon: Symbols.restart_alt,
            onTap: () {
              _restartNetwork();
            }),
        PageMenuItem(label: 'Setup a new Product', icon: Symbols.add)
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
        crossAxisCount: ResponsiveLayout.isOverBreakpoint4(context)
            ? 3
            : ResponsiveLayout.isOverBreakpoint2(context)
                ? 2
                : 1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 10,
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
    return AppMenuCard(
      iconData: item.iconData,
      title: item.title,
      description: item.description,
      onTap: item.onTap,
    );
  }

  List<AppSectionItemData> createMenuItems() {
    final isCloudLogin =
        ref.watch(authProvider).value?.loginType == LoginType.remote;
    return [
      AppSectionItemData(
          title: loc(context).wifi,
          description: 'This is a description for this tile',
          iconData: Symbols.signal_wifi_4_bar,
          onTap: () {
            _navigateTo(RouteNamed.settingsWifi);
          }),
      AppSectionItemData(
          title: loc(context).menuRouterAndNodes,
          description: 'This is a description for this tile',
          iconData: Symbols.router,
          onTap: () {
            _navigateTo(RouteNamed.settingsNodes);
          }),
      AppSectionItemData(
          title: loc(context).safeBrowsing,
          description: 'This is a description for this tile',
          iconData: Symbols.encrypted,
          onTap: () {
            _navigateTo(RouteNamed.safeBrowsing);
          }),
      AppSectionItemData(
          title: loc(context).familyTime,
          description: 'This is a description for this tile',
          iconData: Symbols.family_restroom,
          onTap: () {}),
      AppSectionItemData(
          title: loc(context).speedTest,
          description: 'This is a description for this tile',
          iconData: Symbols.network_check,
          onTap: () {
            _navigateTo(RouteNamed.speedTestSelection);
          }),
      AppSectionItemData(
          title: loc(context).advancedSettings,
          description: 'This is a description for this tile',
          iconData: Symbols.settings,
          onTap: () {
            _navigateTo(RouteNamed.dashboardSettings);
          }),
      if (isCloudLogin)
        AppSectionItemData(
            title: loc(context).account,
            description: 'This is a description for this tile',
            iconData: Symbols.person_rounded,
            onTap: () {
              _navigateTo(RouteNamed.accountInfo);
            }),
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

  void _restartNetwork() {
    showAdaptiveDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog.adaptive(
        title: AppText.labelLarge(loc(context).alertExclamation),
        content: AppText.bodyMedium(loc(context).menuRestartNetworkMessage),
        actions: [
          AppFilledButton(
            loc(context).ok,
            onTap: () {
              ref
                  .read(rootProvider.notifier)
                  .showSpinner(tag: 'reboot', force: true);

              context.pop();
              ref.read(topologyProvider.notifier).reboot().then((value) {
                ref.read(rootProvider.notifier).hideSpinner(tag: 'reboot');
              });
            },
          ),
          AppFilledButton(
            loc(context).cancel,
            onTap: () {
              context.pop();
            },
          )
        ],
      ),
    );
  }
}
