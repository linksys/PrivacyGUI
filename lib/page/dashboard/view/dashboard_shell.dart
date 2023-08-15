import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/constants/build_config.dart';
import 'package:linksys_moab/page/components/customs/debug_overlay_view.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/constants.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import 'package:linksys_moab/util/debug_mixin.dart';
import 'package:linksys_moab/core/utils/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/utils/named.dart';
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
                  ref
                      .read(navigationsProvider.notifier)
                      .push(DebugToolsMainPath());
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
              color: AppTheme.of(context).colors.textBoxText,
              size:
                  AppTheme.of(context).icons.sizes.resolve(AppIconSize.regular),
            ),
            selectedItemColor: AppTheme.of(context).colors.textBoxText,
            unselectedIconTheme: IconThemeData(
                color: AppTheme.of(context).colors.textBoxText, opacity: 0.6),
            unselectedItemColor:
                AppTheme.of(context).colors.textBoxText.withOpacity(0.6),
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
        color: AppTheme.of(context).colors.textBoxText,
      ),
      activeIcon: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(
          getCharactersIcons(context).getByName(item.iconId),
          color: AppTheme.of(context).colors.textBoxText,
        ),
      ),
      label: item.title,
      backgroundColor: AppTheme.of(context).colors.bottomBackground,
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
      const DashboardBottomItem(
        iconId: 'devicesDefault',
        title: 'Devices',
        type: DashboardBottomItemType.devices,
        rootPath: RouteNamed.dashboardDevices,
      ),
      const DashboardBottomItem(
        iconId: 'optionsDefault',
        title: 'Settings',
        type: DashboardBottomItemType.settings,
        rootPath: RouteNamed.dashboardSettings,
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
