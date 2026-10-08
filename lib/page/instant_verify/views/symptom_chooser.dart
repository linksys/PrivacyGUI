import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:flutter/material.dart';

/// Direct workflow entry points, laid out as actions rather than page tabs.
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

  /// Compact choices (density pass, QA #3): a small question and one row of
  /// three buttons per line, so the result above stays the main content.
  static int columns(double width) => width >= 600
      ? 3
      : width >= 160 * 2 + Spacing.small2
          ? 2
          : 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
            header: true, child: const AppText.titleSmall('What needs help?')),
        const AppGap.small2(),
        LayoutBuilder(builder: (context, constraints) {
          final count = columns(constraints.maxWidth);
          final width =
              (constraints.maxWidth - Spacing.small2 * (count - 1)) / count;
          return Wrap(
            spacing: Spacing.small2,
            runSpacing: Spacing.small2,
            children: [
              for (final (id, icon, label) in symptoms)
                SizedBox(
                  width: width,
                  child: AppOutlinedButton(label,
                      onTap: () => onSelect(id),
                      icon: icon,
                      size: Size(width, Spacing.large5)),
                ),
            ],
          );
        }),
      ],
    );
  }
}
