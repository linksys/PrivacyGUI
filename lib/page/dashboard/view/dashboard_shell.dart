import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/constants/build_config.dart';
import 'package:linksys_app/page/components/customs/debug_overlay_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';

import 'package:linksys_app/util/debug_mixin.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

enum DashboardBottomItemType { more, home, devices, settings }

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
  int _selectedIndex = 1;
  final List<DashboardBottomItem> _bottomTabItems = [];

  @override
  void initState() {
    super.initState();
    _prepareBottomTabItems(context);
  }

  @override
  Widget build(BuildContext context) {
    return _contentView();
  }

  Widget _contentView() {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
              onTap: () {
                if (increase()) {
                  logger.d('Triggered!');
                  context.pushNamed(RouteNamed.debug);
                }
              },
              child: widget.child),
          !showDebugPanel
              ? const Center()
              : Positioned(
                  left: Utils.getScreenWidth(context) -
                      Utils.getScreenWidth(context) / 2,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: Utils.getTopSafeAreaPadding(context)),
                      child: const OverlayInfoView(),
                    ),
                  ),
                ),
          // : Container(),
        ],
      ),
      bottomNavigationBar: Offstage(
        offstage: false,
        child: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            iconSize:
                AppTheme.of(context).icons.sizes.resolve(AppIconSize.regular),
            // selectedFontSize:
            //     AppTheme.of(context).icons.sizes.resolve(AppIconSize.small),
            selectedIconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.onSurface,
              size:
                  AppTheme.of(context).icons.sizes.resolve(AppIconSize.regular),
            ),
            selectedItemColor: Theme.of(context).colorScheme.onSurface,
            unselectedIconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            unselectedItemColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            // unselectedFontSize:
            //     AppTheme.of(context).icons.sizes.resolve(AppIconSize.small),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            currentIndex: _selectedIndex,
            //New
            onTap: _onItemTapped,
            items:
                List.from(_bottomTabItems.map((e) => _bottomSheetIconView(e)))),
      ),
    );
  }

  void _onItemTapped(int index) {
    context.goNamed(_bottomTabItems[index].rootPath);
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _bottomSheetIconView(DashboardBottomItem item) {
    return BottomNavigationBarItem(
      icon: Icon(
        getCharactersIcons(context).getByName(item.iconId),
      ),
      activeIcon: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(
          getCharactersIcons(context).getByName(item.iconId),
        ),
      ),
      label: item.title,
    );
  }

  _prepareBottomTabItems(BuildContext context) {
    //
    if (!mounted) {
      return;
    }
    _bottomTabItems.addAll(navigationBottomItems());
  }
}

navigationBottomItems() => [
      const DashboardBottomItem(
        iconId: 'moreHorizontal',
        title: 'more',
        type: DashboardBottomItemType.more,
        rootPath: RouteNamed.dashboardMenu,
      ),
      const DashboardBottomItem(
        iconId: 'homeDefault',
        title: 'Home',
        type: DashboardBottomItemType.home,
        rootPath: RouteNamed.dashboardHome,
      ),
    ];

class DashboardBottomItem {
  const DashboardBottomItem({
    required this.iconId,
    required this.title,
    required this.type,
    required this.rootPath,
  });

  final String iconId;
  final String title;
  final DashboardBottomItemType type;
  final String rootPath;
}
