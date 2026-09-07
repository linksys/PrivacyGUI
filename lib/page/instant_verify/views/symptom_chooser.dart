import 'package:flutter/material.dart';
import 'user_step_heading.dart';

/// Direct workflow entry points, laid out as actions rather than page tabs.
class SymptomChooser extends StatelessWidget {
  const SymptomChooser({super.key, required this.onSelect});
  final ValueChanged<int> onSelect;

  static const symptoms = <(int, IconData, String)>[
    (1, Icons.wifi_off, "Internet isn't working"),
    (2, Icons.speed, 'Whole internet is slow'),
    (5, Icons.sync_problem, 'Keeps cutting out'),
    (31, Icons.devices, 'One device is slow'),
    (3, Icons.device_unknown, "Device won't connect"),
    (4, Icons.meeting_room_outlined, "Doesn't reach a room"),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UserStepHeading('What needs help?'),
        const SizedBox(height: 8),
        const Text("Choose the problem you're having."),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 840
              ? 3
              : constraints.maxWidth >= 340
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (id, icon, label) in symptoms)
                SizedBox(
                  width: width,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 72),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      foregroundColor: theme.colorScheme.onSurface,
                      backgroundColor: theme.colorScheme.surface,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => onSelect(id),
                    child: Row(children: [
                      Icon(icon, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(label,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600))),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right,
                          size: 16, color: theme.colorScheme.onSurfaceVariant),
                    ]),
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}
