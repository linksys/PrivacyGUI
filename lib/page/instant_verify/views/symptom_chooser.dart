import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
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
  static int _columns(BuildContext context) =>
      ResponsiveLayout.isMobileLayout(context) ? 2 : 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
            header: true, child: const AppText.titleSmall('What needs help?')),
        const AppGap.small2(),
        // Rows of equal cells rather than a LayoutBuilder: the page frame
        // (StyledAppPageView, scrollable) sizes its content by intrinsic
        // height, which a LayoutBuilder cannot report.
        for (var start = 0; start < symptoms.length; start += _columns(context)) ...[
          if (start > 0) const AppGap.small2(),
          Row(children: [
            for (var i = start; i < start + _columns(context); i++) ...[
              if (i > start) const AppGap.small2(),
              Expanded(
                child: i < symptoms.length
                    ? AppOutlinedButton(symptoms[i].$3,
                        onTap: () => onSelect(symptoms[i].$1),
                        icon: symptoms[i].$2,
                        size: const Size(double.infinity, Spacing.large5))
                    : const SizedBox.shrink(),
              ),
            ],
          ]),
        ],
      ],
    );
  }
}
