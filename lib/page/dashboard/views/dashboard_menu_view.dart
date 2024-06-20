import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/shortcuts/spinners.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/topology/providers/topology_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/card/menu_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

import 'package:privacygui_widgets/widgets/panel/general_section.dart';

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
      title: loc(context).menu,
      menu: PageMenu(title: loc(context).myNetwork, items: [
        PageMenuItem(
            label: loc(context).restartNetwork,
            icon: LinksysIcons.restartAlt,
            onTap: () {
              _restartNetwork();
            }),
        // PageMenuItem(
        //     label: loc(context).menuSetupANewProduct, icon: LinksysIcons.add)
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
        mainAxisSpacing: Spacing.small2,
        crossAxisSpacing: Spacing.small3,
        childAspectRatio: (4 / 3),
        mainAxisExtent: 205,
      ),
      physics: const ScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildDeviceGridCell(items[index]);
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
          description: loc(context).menuWifiDesc,
          iconData: LinksysIcons.wifi,
          onTap: () {
            _navigateTo(RouteNamed.settingsWifi);
          }),
      AppSectionItemData(
          title: loc(context).networkAdmin,
          description: loc(context).menuNetworkAdminDesc,
          iconData: LinksysIcons.accountCircle,
          onTap: () {
            _navigateTo(RouteNamed.settingsNetworkAdmin);
          }),
      AppSectionItemData(
          title: loc(context).menuRouterAndNodes,
          description: loc(context).menuRouterAndNodesDesc,
          iconData: LinksysIcons.router,
          onTap: () {
            _navigateTo(RouteNamed.settingsNodes);
          }),
      AppSectionItemData(
          title: loc(context).speedTest,
          description: loc(context).menuSpeedTestDesc,
          iconData: LinksysIcons.networkCheck,
          onTap: () {
            _navigateTo(RouteNamed.speedTestSelection);
          }),
      AppSectionItemData(
          title: loc(context).safeBrowsing,
          description: loc(context).menuSafeBrowsingDesc,
          iconData: LinksysIcons.encrypted,
          onTap: () {
            _navigateTo(RouteNamed.safeBrowsing);
          }),
      AppSectionItemData(
          title: loc(context).advancedSettings,
          iconData: LinksysIcons.settings,
          onTap: () {
            _navigateTo(RouteNamed.dashboardAdvancedSettings);
          }),
      AppSectionItemData(
          title: 'Settings',
          description: 'This is a description for this tile',
          iconData: LinksysIcons.settings,
          onTap: () {
            _navigateTo(RouteNamed.dashboardSettings);
          }),
      if (isCloudLogin)
        AppSectionItemData(
            title: loc(context).account,
            description: 'This is a description for this tile',
            iconData: LinksysIcons.accountCircle,
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
    if (ResponsiveLayout.isMobileLayout(context)) {
      context.pop();
    }
    showMessageAppDialog(
      context,
      dismissible: true,
      title: loc(context).alertExclamation,
      message: loc(context).menuRestartNetworkMessage,
      actions: [
        AppFilledButton(
          loc(context).ok,
          onTap: () {
            context.pop();

            final spinner = showFullScreenSpinner(
                shellNavigatorKey.currentContext ?? context,
                messages: [
                  '${loc(context).restarting}.',
                  '${loc(context).restarting}..',
                  '${loc(context).restarting}...'
                ]);
            ref.read(pollingProvider.notifier).stopPolling();
            ref
                .read(topologyProvider.notifier)
                .reboot()
                .then((value) {
                  showSuccessSnackBar(context, loc(context).successExclamation);
                })
                .onError((error, stackTrace) => showFailedSnackBar(
                    context, loc(context).unknownErrorCode(error ?? '')))
                .whenComplete(() {
                  ref.read(pollingProvider.notifier).startPolling();
                  spinner.remove();
                });
          },
        ),
        AppOutlinedButton(
          loc(context).cancel,
          onTap: () {
            context.pop();
          },
        )
      ],
    );
  }
}
