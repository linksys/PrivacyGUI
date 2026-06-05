import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/base_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// MetricTile - Displays a metric with icon, label, and value.
///
/// Used in dashboard cards to show key-value metrics with visual indicators.
class MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Block(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.font(icon, size: 14, color: color),
              AppGap.xs(),
              AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
            ],
          ),
          AppGap.xs(),
          AppText.titleSmall(value),
        ],
      ),
    );
  }
}
