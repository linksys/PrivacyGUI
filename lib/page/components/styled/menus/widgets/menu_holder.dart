import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/bottom_navigation_menu.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/top_navigation_menu.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
  GoRouterDelegate? _routerDelegate;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(menuController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newRouterDelegate = GoRouter.of(context).routerDelegate;
    if (newRouterDelegate != _routerDelegate) {
      _routerDelegate?.removeListener(_updateMenuSelection);
      _routerDelegate = newRouterDelegate;
      _routerDelegate?.addListener(_updateMenuSelection);
      _updateMenuSelection();
    }
  }

  @override
  void dispose() {
    _routerDelegate?.removeListener(_updateMenuSelection);
    super.dispose();
  }

  void _updateMenuSelection() {
    if (_routerDelegate == null) return;
    final extra = _routerDelegate!.currentConfiguration.extra;
    if (extra is NaviType) {
      _controller.setTo(extra);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageRoute = GoRouter.maybeOf(context)
        ?.routerDelegate
        .currentConfiguration
        .routes
        .last as LinksysRoute?;

    const autoHide = false; //LinksysRoute.autoHideNaviRail(context);
    final showNavi = LinksysRoute.isShowNaviRail(context, pageRoute?.config);
    Future.doWhile(() => !mounted).then((value) {
      MenuDisplay displayType;
      if (shellNavigatorKey.currentContext == null || autoHide || !showNavi) {
        displayType = MenuDisplay.none;
      } else {
        if (context.mounted) {
          displayType =
              context.isMobileLayout ? MenuDisplay.bottom : MenuDisplay.top;
        } else {
          displayType = MenuDisplay.none;
        }
      }
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
            MenuDisplay.bottom => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _controller.isVisible ? kBottomNavigationBarHeight : 0,
                child: BottomNavigationMenu(
                  items: _controller.items,
                  selected: _controller.selected,
                  onItemClick: (index) {
                    _controller.select(_controller.items[index]);
                  },
                ),
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

  bool get isVisible => _menuNotifier.value.isVisible;

  void setMenuVisible(bool visible) {
    if (visible == isVisible) return;
    _menuNotifier.value = _menuNotifier.value.copyWith(isVisible: visible);
  }

  void setTo(NaviType type) {
    if (_menuNotifier.value.selected == type) return;
    _menuNotifier.value = _menuNotifier.value.copyWith(selected: type);
  }

  void select(NaviType type) {
    shellNavigatorKey.currentContext!.goNamed(
      type.resolvePath(),
      extra: type,
    );
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
  final bool isVisible;

  const NavigationMenus({
    required this.items,
    required this.selected,
    required this.type,
    this.isVisible = true,
  });

  NavigationMenus copyWith({
    List<NaviType>? items,
    NaviType? selected,
    MenuDisplay? type,
    bool? isVisible,
  }) {
    return NavigationMenus(
      items: items ?? this.items,
      selected: selected ?? this.selected,
      type: type ?? this.type,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [items, selected, type, isVisible];
}
