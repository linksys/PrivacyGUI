import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/bottom_navigation_menu.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/top_navigation_menu.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/material/theme_data.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

final menuController = Provider((ref) => MenuController());

class MenuHolder extends ConsumerStatefulWidget {
  // final Widget Function(BuildContext, MenuController) builder;
  final MenuDisplay type;
  const MenuHolder({super.key, required this.type});

  @override
  ConsumerState<MenuHolder> createState() => MenuHolderState();
}

class MenuHolderState extends ConsumerState<MenuHolder> {
  late final MenuController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(menuController);
  }

  @override
  Widget build(BuildContext context) {
    final pageRoute = GoRouter.maybeOf(context)
        ?.routerDelegate
        .currentConfiguration
        .routes
        .last as LinksysRoute?;

    final showNavi = LinksysRoute.isShowNaviRail(context, pageRoute?.config);
    Future.doWhile(() => !mounted).then((value) {
      final displayType = shellNavigatorKey.currentContext == null || !showNavi
          ? MenuDisplay.none
          : ResponsiveLayout.isMobileLayout(context)
              ? MenuDisplay.bottom
              : MenuDisplay.top;
      _controller.setDisplayType(displayType);
    });
    return ValueListenableBuilder<NavigationMenus>(
        valueListenable: _controller._menuNotifier,
        builder: (context, value, _) {
          final type = widget.type == _controller.displayType
              ? widget.type
              : MenuDisplay.none;

          return switch (type) {
            MenuDisplay.none => const SizedBox.shrink(),
            MenuDisplay.top => TopNavigationMenu(
                items: _controller.items,
                selected: _controller.selected,
                onItemClick: (index) {
                  _controller.select(_controller.items[index]);
                },
              ),
            MenuDisplay.bottom => BottomNavigationMenu(
                items: _controller.items,
                selected: _controller.selected,
                onItemClick: (index) {
                  _controller.select(_controller.items[index]);
                },
              ),
          };
        });
  }
}

class MenuController {
  final ValueNotifier<NavigationMenus> _menuNotifier = ValueNotifier(
    const NavigationMenus(
      items: NaviType.values,
      selected: NaviType.home,
      type: MenuDisplay.none,
    ),
  );

  List<NaviType> get items => _menuNotifier.value.items;
  NaviType get selected => _menuNotifier.value.selected;
  MenuDisplay get displayType {
    return _menuNotifier.value.type;
  }

  void setTo(NaviType type) {
    _menuNotifier.value = _menuNotifier.value.copyWith(selected: type);
  }

  void select(NaviType type) {
    shellNavigatorKey.currentContext!.goNamed(type.resolvePath());
    _menuNotifier.value = _menuNotifier.value.copyWith(selected: type);
  }

  void setDisplayType(MenuDisplay type) {
    _menuNotifier.value = _menuNotifier.value.copyWith(type: type);
  }

  void setItems(List<NaviType> items) {
    _menuNotifier.value = _menuNotifier.value.copyWith(items: items);
  }
}

class NavigationMenus extends Equatable {
  final List<NaviType> items;
  final NaviType selected;
  final MenuDisplay type;

  const NavigationMenus({
    required this.items,
    required this.selected,
    required this.type,
  });

  NavigationMenus copyWith({
    List<NaviType>? items,
    NaviType? selected,
    MenuDisplay? type,
  }) {
    return NavigationMenus(
      items: items ?? this.items,
      selected: selected ?? this.selected,
      type: type ?? this.type,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [items, selected, type];
}
