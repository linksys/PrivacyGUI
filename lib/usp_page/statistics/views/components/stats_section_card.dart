import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shared wrapper for each chart section in the Statistics page.
///
/// Displays a title row (with optional subtitle and trailing action)
/// above a fixed-height chart area wrapped in an [AppCard].
class StatsSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double chartHeight;
  final Widget child;
  final Widget? trailing;

  const StatsSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.chartHeight,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(title),
                    if (subtitle != null)
                      AppText.bodySmall(
                        subtitle!,
                        color: colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          AppGap.md(),
          SizedBox(
            height: chartHeight,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Shared legend dot — 8×8 colored circle for chart legends.
class StatsLegendDot extends StatelessWidget {
  final Color color;
  const StatsLegendDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
