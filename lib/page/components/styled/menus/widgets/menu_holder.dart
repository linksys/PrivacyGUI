import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class MenuHolder extends ConsumerStatefulWidget {
  final Widget Function(BuildContext, MenuController) builder;
  const MenuHolder({super.key, required this.builder});

  @override
  ConsumerState<MenuHolder> createState() => _MenuHolderState();
}

class _MenuHolderState extends ConsumerState<MenuHolder> {
  @override
  void initState() {
    super.initState();
  }

  static final MenuController _controller = MenuController();
  @override
  Widget build(BuildContext context) {
    // ref.listen(authProvider.select((value) => value.value?.loginType),
    //     (previous, next) {
    //   // reset to home once logged out
    //   if (next == null || next == LoginType.none) {
    //     _controller.select(NaviType.home);
    //   }
    // });
    Future.doWhile(() => !mounted).then((value) {
      final displayType = shellNavigatorKey.currentContext == null
          ? MenuDisplay.none
          : ResponsiveLayout.isMobileLayout(context)
              ? MenuDisplay.bottom
              : MenuDisplay.top;
      _controller.setDisplayType(displayType);
    });
    return ValueListenableBuilder<NavigationMenus>(
        valueListenable: _controller._menuNotifier,
        builder: (context, value, _) {
          return widget.builder.call(context, _controller);
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

    // if (_menuNotifier.value.type == MenuDisplay.none) {
    //   return _menuNotifier.value.type;
    // }
    final context = shellNavigatorKey.currentContext;
    if (context == null) {
      return MenuDisplay.none;
    }
    return ResponsiveLayout.isMobileLayout(context)
        ? MenuDisplay.bottom
        : MenuDisplay.top;
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
