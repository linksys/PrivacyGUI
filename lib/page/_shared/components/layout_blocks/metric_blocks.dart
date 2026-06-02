import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/status_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

// =============================================================================
// HighlightValue - Single prominent number display
// =============================================================================

class HighlightValue extends StatelessWidget {
  final String value;
  final String label;
  final String? subtitle;
  final Color? valueColor;

  const HighlightValue({
    super.key,
    required this.value,
    required this.label,
    this.subtitle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Block(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          AppText.displaySmall(
            value,
            color: valueColor ?? colorScheme.primary,
          ),
          AppGap.xs(),
          AppText.labelMedium(label, color: colorScheme.onSurfaceVariant),
          if (subtitle != null) ...[
            AppGap.sm(),
            AppText.bodySmall(subtitle!, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// DualMetric - Two metrics side by side with mini gauges
// =============================================================================

class DualMetric extends StatelessWidget {
  final DualMetricItem left;
  final DualMetricItem right;

  const DualMetric({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DualMetricTile(item: left)),
        AppGap.sm(),
        Expanded(child: _DualMetricTile(item: right)),
      ],
    );
  }
}

class DualMetricItem {
  final IconData icon;
  final String value;
  final String label;
  final double? percentage; // 0.0 to 1.0 for gauge

  const DualMetricItem({
    required this.icon,
    required this.value,
    required this.label,
    this.percentage,
  });
}

class _DualMetricTile extends StatelessWidget {
  final DualMetricItem item;

  const _DualMetricTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Block(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (item.percentage != null)
            SizedBox(
              width: 48,
              height: 48,
              child: AppGauge(
                value: (item.percentage! * 100).clamp(0.0, 100.0),
                size: 48,
                centerBuilder: (context, value) => AppIcon.font(
                  item.icon,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            AppIcon.font(item.icon,
                size: 24, color: colorScheme.onSurfaceVariant),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall(item.value),
                AppText.bodySmall(
                  item.label,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
