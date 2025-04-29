import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

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
        icon: LinksysIcons.home,
        type: NaviType.home,
        rootPath: RouteNamed.dashboardHome),
    NaviType.menu: DashboardNaviItem(
        icon: LinksysIcons.menu,
        type: NaviType.menu,
        rootPath: RouteNamed.dashboardMenu),
    NaviType.support: DashboardNaviItem(
        icon: LinksysIcons.help,
        type: NaviType.support,
        rootPath: RouteNamed.dashboardSupport),
  };
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = getIt.get<ThemeData>(instanceName: 'darkThemeData');
    return Theme(
      data: theme.copyWith(),
      child: NavigationBar(
        selectedIndex: widget.items.indexOf(widget.selected ?? NaviType.home),
        destinations: widget.items.map((e) => menuItemsMap[e]).nonNulls.map((e) => _bottomSheetIconView(e)).toList(),
        onDestinationSelected: widget.onItemClick,
        indicatorColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
    );
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
}
