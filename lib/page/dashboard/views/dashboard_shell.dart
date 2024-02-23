// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/dashboard/views/dashboard_navigation_rail.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_app/util/debug_mixin.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

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
    _prepareNavigationItems(context);
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
        bottomNavigationBar: ResponsiveLayout.isMobile(context)
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                destinations: _dashboardNaviItems
                    .map((e) => _bottomSheetIconView(e))
                    .toList(),
                onDestinationSelected: _onItemTapped,
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
    const items = [
      DashboardNaviItem(
          iconId: 'homeDefault',
          title: 'Home',
          rootPath: RouteNamed.dashboardHome),
      DashboardNaviItem(
          iconId: 'moreHorizontal',
          title: 'Menu',
          rootPath: RouteNamed.dashboardMenu),
      DashboardNaviItem(
          iconId: 'helpRound',
          title: 'Supports',
          rootPath: RouteNamed.dashboardHome),
    ];
    _dashboardNaviItems.addAll(items);
  }

  NavigationDestination _bottomSheetIconView(DashboardNaviItem item) {
    return NavigationDestination(
      icon: Icon(
        getCharactersIcons(context).getByName(item.iconId),
        color: Theme.of(context).colorScheme.onBackground,
      ),
      label: item.title,
    );
  }

  NavigationRailDestination _createNavigationRailDestination(
      DashboardNaviItem item) {
    return NavigationRailDestination(
      icon: Icon(
        getCharactersIcons(context).getByName(item.iconId),
      ),
      label: AppText.bodySmall(
        item.title,
      ),
    );
  }
}

class DashboardRailDestination {
  final NavigationRailDestination destination;
  final String path;
  DashboardRailDestination({
    required this.destination,
    required this.path,
  });
}

class DashboardNaviItem {
  const DashboardNaviItem({
    required this.iconId,
    required this.title,
    required this.rootPath,
  });

  final String iconId;
  final String title;
  final String rootPath;
}
