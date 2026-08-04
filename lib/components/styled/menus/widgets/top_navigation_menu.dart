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
  // Bumped on every chip tap to force AppChipGroup to rebuild from scratch and
  // re-read the authoritative `widget.selected`. AppChipGroup owns its
  // selection state internally and optimistically moves the highlight on tap,
  // only re-syncing to its `selectedIndices` prop when that prop changes. When
  // a navigation is cancelled (e.g. the user picks "Go back" in the unsaved
  // changes dialog), `widget.selected` never changes, so without this the
  // highlight would stay stuck on the cancelled destination. Re-keying forces
  // the highlight back to the still-current option. See PrivacyGUI#1158.
  int _syncToken = 0;

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
        key: ValueKey('top-nav-chip-group-$selectedIndex-$_syncToken'),
        chips: widget.items
            .map((type) => ChipItem(
                  label: type.resloveLabel(context),
                  icon: type.resolveIcon(),
                  enabled: true,
                  // Layout-neutral test hook: the primary-nav destinations
                  // render as top chips on desktop and a bottom bar on mobile;
                  // both emit the same `nav-<home|menu|support>` identifier so
                  // E2E targeting is breakpoint-agnostic. See PrivacyGUI#1172.
                  identifier: 'nav-${type.name}',
                ))
            .toList(),
        selectedIndices: {selectedIndex},
        selectionMode: ChipSelectionMode.single,
        onSelectionChanged: (selectedIndices) {
          if (selectedIndices.isNotEmpty) {
            widget.onItemClick?.call(selectedIndices.first);
            // Force AppChipGroup to re-assert `widget.selected` on the next
            // frame. If the navigation is confirmed, the controller updates
            // `selected` and the highlight follows; if it is cancelled, the
            // highlight reverts to the current option instead of staying on
            // the tapped-but-rejected destination.
            //
            // This bump MUST stay here (synchronous, on every tap). It cannot
            // move to didUpdateWidget: a cancelled navigation leaves the
            // MenuController's `selected` unchanged, so this widget never
            // rebuilds and didUpdateWidget never fires — the highlight would
            // stay stuck on the rejected destination (the exact #1158 bug).
            if (mounted) {
              setState(() => _syncToken++);
            }
          }
        },
      ),
    );
  }
}
