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

    return LayoutBlock(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.font(icon, size: 14, color: color),
              AppGap.xs(),
              // Flexible + ellipsis, not a fixed width: this tile is laid out
              // two-across inside a dashboard card, so at the narrowest grid
              // width each one gets ~42px of content box and every localized
              // label is wider than that. Unconstrained it was the single
              // largest overflow site in the baseline — 95 coordinates across
              // device_info, lan_info and network_status (#1227).
              Flexible(
                child: AppText.labelSmall(
                  label,
                  color: colorScheme.onSurfaceVariant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppGap.xs(),
          AppText.titleSmall(value),
        ],
      ),
    );
  }
}
