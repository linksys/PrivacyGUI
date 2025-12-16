import 'package:flutter/material.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

class BottomNavigationMenu extends StatefulWidget {
  final List<NaviType> items;
  final void Function(int)? onItemClick;
  final NaviType? selected;
  const BottomNavigationMenu({
    super.key,
    required this.items,
    this.onItemClick,
    this.selected,
  });

  @override
  State<BottomNavigationMenu> createState() => _BottomNavigationMenuState();
}

class _BottomNavigationMenuState extends State<BottomNavigationMenu> {
  static const menuItemsMap = {
    NaviType.home: DashboardNaviItem(
        icon: AppFontIcons.home,
        type: NaviType.home,
        rootPath: RouteNamed.dashboardHome),
    NaviType.menu: DashboardNaviItem(
        icon: AppFontIcons.menu,
        type: NaviType.menu,
        rootPath: RouteNamed.dashboardMenu),
    NaviType.support: DashboardNaviItem(
        icon: AppFontIcons.help,
        type: NaviType.support,
        rootPath: RouteNamed.dashboardSupport),
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = widget.items
        .map((e) => menuItemsMap[e])
        .nonNulls
        .map((e) => _createNavItem(e))
        .toList();

    // Force dark theme for AppNavigationBar
    final darkTheme = getIt.get<ThemeData>(instanceName: 'darkThemeData');
    return Theme(
      data: darkTheme,
      child: AppNavigationBar(
        currentIndex: widget.items.indexOf(widget.selected ?? NaviType.home),
        items: navItems,
        onTap: (index) => widget.onItemClick?.call(index),
      ),
    );
  }

  AppNavigationItem _createNavItem(DashboardNaviItem item) {
    return AppNavigationItem(
      icon: Icon(item.icon),
      label: item.type.resloveLabel(context),
    );
  }
}
