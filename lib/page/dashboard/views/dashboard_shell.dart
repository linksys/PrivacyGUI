// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/dashboard/views/dashboard_navigation_rail.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_app/util/debug_mixin.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:material_symbols_icons/symbols.dart';

class DashboardShell extends ArgumentsConsumerStatefulView {
  const DashboardShell({
    Key? key,
    required this.child,
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
    Future.doWhile(() => !mounted)
        .then((value) => _prepareNavigationItems(context));
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
    // final lastPage = GoRouter.of(context)
    //     .routerDelegate
    //     .currentConfiguration
    //     .last
    //     .matchedLocation;

    return StyledAppPageView(
        backState: StyledBackState.none,
        appBarStyle: AppBarStyle.none,
        handleNoConnection: true,
        handleBanner: true,
        padding: const EdgeInsets.only(),
        bottomNavigationBar: ResponsiveLayout.isLayoutBreakpoint(context)
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
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
    final items = [
      DashboardNaviItem(
          icon: Symbols.home,
          title: loc(context).home,
          rootPath: RouteNamed.dashboardHome),
      DashboardNaviItem(
          icon: Symbols.menu,
          title: loc(context).menu,
          rootPath: RouteNamed.dashboardMenu),
      DashboardNaviItem(
          icon: Symbols.help_outline,
          title: loc(context).support,
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
      label: item.title,
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
        item.title,
      ),
    );
  }
}

class DashboardNaviItem {
  const DashboardNaviItem({
    required this.icon,
    required this.title,
    required this.rootPath,
  });

  final IconData icon;
  final String title;
  final String rootPath;
}
