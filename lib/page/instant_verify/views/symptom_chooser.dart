import 'package:privacy_gui/page/dashboard/views/dashboard_menu_view.dart'
    show AppMenuCard;
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:flutter/material.dart';

/// Direct workflow entry points, shown as Menu tiles.
class SymptomChooser extends StatelessWidget {
  const SymptomChooser({super.key, required this.onSelect});
  final ValueChanged<int> onSelect;

  static const symptoms = <(int, IconData, String, String)>[
    (1, LinksysIcons.signalWifiOff, "Internet isn't working",
        "Websites won't load, devices can't get online"),
    (2, LinksysIcons.networkCheck, 'Whole internet is slow',
        'Videos buffer, downloads are sluggish'),
    (5, LinksysIcons.bidirectional, 'Keeps cutting out',
        'Internet drops and comes back on its own'),
    (31, LinksysIcons.devices, 'One device is slow',
        'One phone, laptop or TV is slower than the rest'),
    (3, LinksysIcons.genericDevice, "Device won't connect",
        "A device can't join your WiFi"),
    (4, LinksysIcons.home, "Doesn't reach a room",
        'Weak signal in part of your home'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
            header: true, child: const AppText.titleSmall('What needs help?')),
        const AppGap.small2(),
        SymptomTileGrid(
          children: [
            for (final (id, icon, label, description) in symptoms)
              AppMenuCard(
                  iconData: icon,
                  title: label,
                  description: description,
                  onTap: () => onSelect(id)),
          ],
        ),
      ],
    );
  }
}

/// The Menu page's grid (DashboardMenuView._buildMenuGridView): three
/// AppMenuCards per row on wide layouts, one on mobile, same tile heights
/// and spacing. Built from rows of fixed-height cells, not a GridView, because
/// the page frame (StyledAppPageView, scrollable) sizes its content by
/// intrinsic height, which a nested scrollable cannot report.
class SymptomTileGrid extends StatelessWidget {
  const SymptomTileGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final wide = ResponsiveLayout.isOverMedimumLayout(context);
    final columns = wide ? 3 : 1;
    final height = wide ? 152.0 : 112.0;
    final rowGap = wide ? Spacing.medium : Spacing.small2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var start = 0; start < children.length; start += columns) ...[
          if (start > 0) SizedBox(height: rowGap),
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start)
                    SizedBox(width: ResponsiveLayout.columnPadding(context)),
                  Expanded(
                      child: i < children.length
                          ? children[i]
                          : const SizedBox.shrink()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
