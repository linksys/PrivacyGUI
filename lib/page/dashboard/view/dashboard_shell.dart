import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/constants/build_config.dart';
import 'package:linksys_app/page/components/customs/debug_overlay_view.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/route/router_provider.dart';

import 'package:linksys_app/util/debug_mixin.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/color_schemes_ext.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';

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
  static final showBottomSheetList = [
    RoutePath.dashboardHome,
    RoutePath.dashboardMenu
  ];
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
    final width = MediaQuery.of(context).size.width;
    // HAS exception here
    if (width > 768 && _selectedIndex == 0) {
      _onItemTapped(1);
    }
    final lastPage = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .last
        .matchedLocation;
    return StyledAppPageView(
      backState: StyledBackState.none,
      appBarStyle: AppBarStyle.none,
      handleNoConnection: true,
      handleBanner: true,
      padding: const AppEdgeInsets.zero(),
      bottomNavigationBar: Offstage(
        offstage: width > 768,
        child: !showBottomSheetList.contains(lastPage)
            ? null
            : BottomNavigationBar(
                useLegacyColorScheme: false,
                backgroundColor: Theme.of(context)
                    .extension<ColorSchemeExt>()
                    ?.surfaceContainer,
                type: BottomNavigationBarType.fixed,
                iconSize: AppTheme.of(context)
                    .icons
                    .sizes
                    .resolve(AppIconSize.regular),
                // selectedFontSize:
                //     AppTheme.of(context).icons.sizes.resolve(AppIconSize.small),
                selectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onSurface,
                  size: AppTheme.of(context)
                      .icons
                      .sizes
                      .resolve(AppIconSize.regular),
                ),
                selectedItemColor:
                    Theme.of(context).colorScheme.primaryContainer,
                unselectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                unselectedItemColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                // unselectedFontSize:
                //     AppTheme.of(context).icons.sizes.resolve(AppIconSize.small),
                showSelectedLabels: false,
                showUnselectedLabels: false,
                currentIndex: _selectedIndex,
                //New
                onTap: _onItemTapped,
                items: List.from(
                    _bottomTabItems.map((e) => _bottomSheetIconView(e)))),
      ),
      child: Stack(
        children: [
          GestureDetector(
              onTap: () {
                if (!kIsWeb && increase()) {
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
    );
  }

  void _onItemTapped(int index) {
    shellNavigatorKey.currentContext!.goNamed(_bottomTabItems[index].rootPath);
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _bottomSheetIconView(DashboardBottomItem item) {
    return BottomNavigationBarItem(
      icon: Icon(
        getCharactersIcons(context).getByName(item.iconId),
      ),
      activeIcon: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(100)),
          shape: BoxShape.rectangle,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
