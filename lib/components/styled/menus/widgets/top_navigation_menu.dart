import 'package:flutter/material.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:ui_kit_library/ui_kit.dart';

class TopNavigationMenu extends StatefulWidget {
  final List<NaviType> items;
  final void Function(int)? onItemClick;
  final NaviType? selected;
  const TopNavigationMenu({
    super.key,
    required this.items,
    this.onItemClick,
    this.selected,
  });

  @override
  State<TopNavigationMenu> createState() => _TopNavigationMenuState();
}

class _TopNavigationMenuState extends State<TopNavigationMenu> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Prefer inherited dark theme (e.g. USP demo config); fall back to getIt
    final parentTheme = Theme.of(context);
    final darkTheme = parentTheme.brightness == Brightness.dark
        ? parentTheme
        : getIt.get<ThemeData>(instanceName: 'darkThemeData');
    final selectedIndex =
        widget.items.indexOf(widget.selected ?? widget.items.first);

    return Theme(
      data: darkTheme,
      child: AppChipGroup(
        chips: widget.items
            .map((type) => ChipItem(
                  label: type.resloveLabel(context),
                  icon: type.resolveIcon(),
                  enabled: true,
                ))
            .toList(),
        selectedIndices: {selectedIndex},
        selectionMode: ChipSelectionMode.single,
        onSelectionChanged: (selectedIndices) {
          if (selectedIndices.isNotEmpty) {
            widget.onItemClick?.call(selectedIndices.first);
          }
        },
      ),
    );
  }
}
