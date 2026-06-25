import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../health/health_dimension.dart';
import '../health/health_score.dart';

/// Detail view for a single health dimension.
///
/// Shows:
/// - Dimension name with back button
/// - Status and summary items
/// - Action buttons (navigate, reboot, etc.)
class DimensionDetailView extends StatelessWidget {
  final HealthDimension dimension;
  final HealthScore? score;
  final DimensionSummary summary;
  final Color textColor;
  final VoidCallback onBack;
  final void Function(HealthAction action) onAction;

  const DimensionDetailView({
    super.key,
    required this.dimension,
    required this.score,
    required this.summary,
    required this.textColor,
    required this.onBack,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tier = score?.tier ?? HealthTier.excellent;
    final tierColor = NetworkHealthHelpers.tierColor(tier, cs);
    final tierLabel = tier.resolveLabel(context);
    final actions = dimension.getActions(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back button
        Row(
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(dimension.icon, size: 20, color: tierColor),
            const SizedBox(width: 6),
            Expanded(
              child: AppText.titleMedium(
                dimension.displayName,
                color: textColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Status
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tierColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            AppText.bodyMedium(
              '${summary.status} ($tierLabel)',
              color: textColor,
            ),
          ],
        ),

        // Summary items
        if (summary.items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...summary.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: AppText.bodySmall(
                        item.label,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                    Expanded(
                      child: AppText.bodySmall(
                        item.value,
                        color: textColor,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],

        const SizedBox(height: 16),

        // Action buttons
        if (actions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions
                .map((action) => _ActionButton(
                      action: action,
                      textColor: textColor,
                      onTap: () => onAction(action),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final HealthAction action;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.action,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                size: 16,
                color: cs.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              AppText.labelMedium(
                action.label,
                color: cs.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
