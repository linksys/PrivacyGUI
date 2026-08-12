import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'block_constants.dart';

// =============================================================================
// StatTile - Summary statistic tile (icon + value + label)
// =============================================================================

/// Statistic tile for dashboard stats panel.
///
/// Displays an icon, value, and label with optional trend indicator.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final StatTileTrend? trend;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(icon,
              size: BlockConstants.iconLg, color: colorScheme.onSurface),
          AppGap.sm(),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The trend indicator keeps its intrinsic size; the figure yields.
              // A trend arrow with no number beside it is meaningless, whereas
              // an ellipsized figure still reads as "there is a value here".
              Flexible(
                child: AppText.titleSmall(
                  value,
                  color: colorScheme.onSurface,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trend != null) ...[
                AppGap.xxs(),
                _TrendIndicator(trend: trend!),
              ],
            ],
          ),
          AppGap.xs(),
          // Flexible so the enclosing Column cannot exceed the height the grid
          // gives it, and bounded to two lines so a narrow tile wraps instead of
          // growing without limit. The stats panel lays five of these across one
          // card, so at the narrowest grid width each tile is ~17px wide — the
          // label used to wrap to as many lines as it needed and push the Column
          // 98px past its budget (#1227).
          Flexible(
            child: AppText.bodySmall(
              label,
              color: colorScheme.onSurfaceVariant,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BlockConstants.borderRadius),
      child: content,
    );
  }
}

// =============================================================================
// StatTileTrend - Trend indicator for StatTile
// =============================================================================

enum StatTileTrendDirection { up, down, neutral }

class StatTileTrend {
  final StatTileTrendDirection direction;
  final String? label;

  const StatTileTrend({
    required this.direction,
    this.label,
  });

  const StatTileTrend.up([this.label]) : direction = StatTileTrendDirection.up;
  const StatTileTrend.down([this.label])
      : direction = StatTileTrendDirection.down;
  const StatTileTrend.neutral([this.label])
      : direction = StatTileTrendDirection.neutral;
}

class _TrendIndicator extends StatelessWidget {
  final StatTileTrend trend;

  const _TrendIndicator({required this.trend});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>();
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color) = switch (trend.direction) {
      StatTileTrendDirection.up => (
          Icons.arrow_drop_up,
          appColors?.semanticSuccess ?? Colors.green
        ),
      StatTileTrendDirection.down => (Icons.arrow_drop_down, colorScheme.error),
      StatTileTrendDirection.neutral => (
          Icons.remove,
          colorScheme.onSurfaceVariant
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: BlockConstants.iconSm, color: color),
        if (trend.label != null) AppText.labelSmall(trend.label!, color: color),
      ],
    );
  }
}

// =============================================================================
// EmptyState - Empty state placeholder
// =============================================================================

/// Empty state placeholder with icon, message, and optional action.
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIcon.font(
                icon!,
                size: BlockConstants.iconXl,
                color: colorScheme.onSurfaceVariant
                    .withValues(alpha: BlockConstants.disabledAlpha),
              ),
              AppGap.md(),
            ],
            AppText.bodyMedium(
              message,
              color: colorScheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              AppGap.md(),
              AppButton.text(
                label: actionLabel!,
                onTap: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
