// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/dashboard/views/dashboard_navigation_rail.dart';
import 'package:linksys_app/route/route_model.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_app/util/debug_mixin.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

enum NaviType {
  home,
  menu,
  support,
  ;

  String resloveLabel(BuildContext context) => switch (this) {
        NaviType.home => loc(context).home,
        NaviType.menu => loc(context).menu,
        NaviType.support => loc(context).support,
      };
}

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

    final showNavi = pageRoute?.config == null
        ? !autoHideNaviRail()
        : pageRoute?.config?.noNaviRail != true;
    return StyledAppPageView(
        backState: StyledBackState.none,
        appBarStyle: AppBarStyle.none,
        handleNoConnection: true,
        handleBanner: true,
        padding: const EdgeInsets.only(),
        bottomNavigationBar:
            ResponsiveLayout.isLayoutBreakpoint(context) && showNavi
                ? NavigationBar(
                    selectedIndex: _selectedIndex,
                    destinations: _dashboardNaviItems
                        .map((e) => _bottomSheetIconView(e))
                        .toList(),
                    onDestinationSelected: _onItemTapped,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                  )
                : null,
        child: _buildLayout());
  }

  Widget _buildLayout() {
    return ResponsiveLayout(desktop: _buildDesktop(), mobile: _buildMobile());
  }

  Widget _buildDesktop() {
    final pageRoute = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .routes
        .last as LinksysRoute?;

    final showNavi = pageRoute?.config == null
        ? !autoHideNaviRail()
        : pageRoute?.config?.noNaviRail != true;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (showNavi)
          DashboardNavigationRail(
            items: _dashboardNaviItems
                .map((e) => _createNavigationRailDestination(e))
                .toList(),
            onItemTapped: _onItemTapped,
            selected: _selectedIndex,
          ),
        const VerticalDivider(
          width: 1,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (increase()) {
                logger.d('Triggered!');
                context.pushNamed(RouteNamed.debug);
              }
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return GestureDetector(
      onTap: () {
        if (increase()) {
          logger.d('Triggered!');
          context.pushNamed(RouteNamed.debug);
        }
      },
      child: widget.child,
    );
  }

  bool autoHideNaviRail() =>
      (GoRouter.of(context)
              .routerDelegate
              .currentConfiguration
              .matches
              .lastOrNull
              ?.matchedLocation
              .split('/')
              .length ??
          0) >
      2;

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
      ),
      selectedIcon: Icon(
        item.icon,
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
      ),
      selectedIcon: Icon(
        item.icon,
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
