// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_navigation_rail.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/util/debug_mixin.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DashboardShell extends ArgumentsConsumerStatefulView {
  const DashboardShell({
    Key? key,
    required this.child,
    super.args,
  }) : super(key: key);

  final Widget child;

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell>
    with DebugObserver {
  int _selectedIndex = 0;
  final List<DashboardNaviItem> _dashboardNaviItems = [];

  @override
  void initState() {
    super.initState();
    _prepareNavigationItems(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return _contentView();
  }

  Widget _contentView() {
    final pageRoute = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .routes
        .last as LinksysRoute?;

    final showNavi = LinksysRoute.isShowNaviRail(context, pageRoute?.config);

    return Scaffold(
      // appBar: PreferredSize(
      //     preferredSize: Size(0, 80),
      //     child: TopBar(
      //       onMenuClick:
      //           ResponsiveLayout.isMobileLayout(context) ? null : _onItemTapped,
      //     )),
      body: _buildLayout(),
      bottomNavigationBar: MenuHolder(
        builder: (context, controller) {
          return controller.displayType == MenuDisplay.bottom
              ? NavigationBar(
                  selectedIndex: controller.items.indexOf(controller.selected),
                  destinations: _dashboardNaviItems
                      .map((e) => _bottomSheetIconView(e))
                      .toList(),
                  onDestinationSelected: (index) {
                    final selected = controller.items[index];
                    controller.select(selected);
                  },
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                )
              : const SizedBox();
        },
      ),
    );
    // return StyledAppPageView(
    //     backState: StyledBackState.none,
    //     appBarStyle: AppBarStyle.none,
    //     handleNoConnection: true,
    //     handleBanner: true,
    //     padding: const EdgeInsets.only(),
    //     bottomNavigationBar:
    //         ResponsiveLayout.isMobileLayout(context) && showNavi
    //             ? NavigationBar(
    //                 selectedIndex: _selectedIndex,
    //                 destinations: _dashboardNaviItems
    //                     .map((e) => _bottomSheetIconView(e))
    //                     .toList(),
    //                 onDestinationSelected: _onItemTapped,
    //                 indicatorColor: Theme.of(context).colorScheme.primary,
    //                 elevation: 0,
    //               )
    //             : null,
    //     child: _buildLayout());
  }

  Widget _buildLayout() {
    return widget.child;
  }

  Widget _buildDesktop() {
    final pageRoute = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .routes
        .last as LinksysRoute?;

    final showNavi = LinksysRoute.isShowNaviRail(context, pageRoute?.config);
    return widget.child;
  }

  Widget _buildMobile() {
    return widget.child;
  }

  void _onItemTapped(int index) {
    shellNavigatorKey.currentContext!
        .goNamed(_dashboardNaviItems[index].rootPath);
    setState(() {
      _selectedIndex = index;
    });
  }

  _prepareNavigationItems(BuildContext context) {
    //
    if (!mounted) {
      return;
    }
    const items = [
      DashboardNaviItem(
          icon: LinksysIcons.home,
          type: NaviType.home,
          rootPath: RouteNamed.dashboardHome),
      DashboardNaviItem(
          icon: LinksysIcons.menu,
          type: NaviType.menu,
          rootPath: RouteNamed.dashboardMenu),
      DashboardNaviItem(
          icon: LinksysIcons.help,
          type: NaviType.support,
          rootPath: RouteNamed.dashboardSupport),
    ];
    _dashboardNaviItems.addAll(items);
  }

  NavigationDestination _bottomSheetIconView(DashboardNaviItem item) {
    return NavigationDestination(
      icon: Icon(
        item.icon,
        semanticLabel: item.type.resloveLabel(context),
      ),
      selectedIcon: Icon(
        item.icon,
        semanticLabel: 'selected ${item.type.resloveLabel(context)}',
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      label: item.type.resloveLabel(context),
    );
  }

  NavigationRailDestination _createNavigationRailDestination(
      DashboardNaviItem item) {
    return NavigationRailDestination(
      icon: Icon(
        item.icon,
        semanticLabel: item.type.resloveLabel(context),
      ),
      selectedIcon: Icon(
        item.icon,
        semanticLabel: 'selected ${item.type.resloveLabel(context)}',
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      label: AppText.bodySmall(
        item.type.resloveLabel(context),
      ),
    );
  }
}

class DashboardNaviItem {
  const DashboardNaviItem({
    required this.icon,
    required this.type,
    required this.rootPath,
  });

  final IconData icon;
  final NaviType type;
  final String rootPath;
}
