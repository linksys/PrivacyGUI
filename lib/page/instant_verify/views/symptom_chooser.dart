import 'instant_test_layout.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:flutter/material.dart';
import 'user_step_heading.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UserStepHeading('What needs help?', centered: true),
        const SizedBox(height: 8),
        const Text("Choose the problem you're having.",
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final columns = InstantTestLayout.actionColumns(constraints.maxWidth);
          final width =
              (constraints.maxWidth - Spacing.medium * (columns - 1)) / columns;
          return Wrap(
            spacing: Spacing.medium,
            runSpacing: Spacing.medium,
            children: [
              for (final (id, icon, label) in symptoms)
                SizedBox(
                  width: width,
                  child: AppOutlinedButton(label,
                      onTap: () => onSelect(id),
                      icon: icon,
                      size: Size(width, 88)),
                ),
            ],
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}
