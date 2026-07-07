import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../health/health_dimension.dart';
import '../health/health_score.dart';

/// Tooltip content showing dimension summary.
class DimensionTooltipContent extends StatelessWidget {
  final HealthDimension dimension;
  final HealthScore? score;
  final DimensionSummary? summary;

  const DimensionTooltipContent({
    super.key,
    required this.dimension,
    this.score,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSummary = summary ??
        const DimensionSummary(status: 'Unknown', hint: 'Tap for actions');
    final tier = score?.tier ?? HealthTier.excellent;
    final tierLabel = tier.resolveLabel(context);
    final cs = Theme.of(context).colorScheme;
    final tierColor = NetworkHealthHelpers.tierColor(tier, cs);

    // Theme-aware text colors for tooltip
    final textColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;
    final hintColor = cs.outline;

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(dimension.icon, size: 16, color: tierColor),
              const SizedBox(width: 6),
              AppText.labelLarge(
                dimension.displayName,
                color: textColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText.bodySmall(
            '${effectiveSummary.status} ($tierLabel)',
            color: subtitleColor,
          ),
          if (effectiveSummary.items.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...effectiveSummary.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.labelSmall(
                        '${item.label}: ',
                        color: subtitleColor,
                      ),
                      Flexible(
                        child: AppText.labelSmall(
                          item.value,
                          color: textColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 4),
          AppText.labelSmall(
            effectiveSummary.hint ?? 'Tap for actions',
            color: hintColor,
          ),
        ],
      ),
    );
  }
}
