import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:flutter/material.dart';

/// Direct workflow entry points, laid out as Menu tiles.
class SymptomChooser extends StatelessWidget {
  const SymptomChooser({super.key, required this.onSelect});
  final ValueChanged<int> onSelect;

  static const symptoms = <(int, IconData, String)>[
    (1, LinksysIcons.signalWifiOff, "Internet isn't working"),
    (2, LinksysIcons.networkCheck, 'Whole internet is slow'),
    (5, LinksysIcons.bidirectional, 'Keeps cutting out'),
    (31, LinksysIcons.devices, 'One device is slow'),
    (3, LinksysIcons.genericDevice, "Device won't connect"),
    (4, LinksysIcons.home, "Doesn't reach a room"),
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
            for (final (id, icon, label) in symptoms)
              SymptomTile(
                  iconData: icon, title: label, onTap: () => onSelect(id)),
          ],
        ),
      ],
    );
  }
}

/// The Menu grid (dashboard_menu_view.dart): three tiles per row on wide
/// layouts, one on mobile, with the Menu's spacing. Tiles here have no
/// description, so the row height fits the icon and title only.
class SymptomTileGrid extends StatelessWidget {
  const SymptomTileGrid(
      {super.key, required this.children, this.titleLines = 1});
  final List<Widget> children;

  /// Lines each tile title may take; sets the row height.
  final int titleLines;

  @override
  Widget build(BuildContext context) {
    final wide = ResponsiveLayout.isOverMedimumLayout(context);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 1,
        mainAxisSpacing: wide ? Spacing.medium : Spacing.small2,
        crossAxisSpacing: ResponsiveLayout.columnPadding(context),
        // Card padding, the 24px icon, the title gap and 20px title lines,
        // plus a little room for font metrics.
        mainAxisExtent: Spacing.medium * 2 +
            24 +
            Spacing.small2 +
            20 * titleLines +
            Spacing.small1,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// One problem choice, built like the dashboard's AppMenuCard (icon above a
/// title) without its description, status and beta label.
class SymptomTile extends StatelessWidget {
  const SymptomTile({
    super.key,
    required this.iconData,
    required this.title,
    this.onTap,
    this.titleLines = 1,
  });

  final IconData iconData;
  final String title;
  final VoidCallback? onTap;
  final int titleLines;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      explicitChildNodes: false,
      identifier: 'instant-test-${title.kebab()}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            FittedBox(
              fit: BoxFit.fill,
              child: Icon(iconData, size: 24),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: Spacing.small2),
            child: AppText.titleSmall(
              title,
              maxLines: titleLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
