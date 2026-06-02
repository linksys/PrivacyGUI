import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

// =============================================================================
// StatTile - Summary statistic tile (icon + value + label)
// =============================================================================

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
          AppIcon.font(icon, size: 24, color: colorScheme.onSurface),
          AppGap.sm(),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText.titleSmall(value, color: colorScheme.onSurface),
              if (trend != null) ...[
                AppGap.xxs(),
                _TrendIndicator(trend: trend!),
              ],
            ],
          ),
          AppGap.xs(),
          AppText.bodySmall(
            label,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
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
        Icon(icon, size: 16, color: color),
        if (trend.label != null) AppText.labelSmall(trend.label!, color: color),
      ],
    );
  }
}

// =============================================================================
// SectionDivider - Divider with optional title
// =============================================================================

class SectionDivider extends StatelessWidget {
  final String? title;
  final Widget? trailing;

  const SectionDivider({
    super.key,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    if (title == null && trailing == null) {
      return const Divider();
    }

    return Column(
      children: [
        const Divider(),
        AppGap.md(),
        Row(
          children: [
            if (title != null) AppText.titleMedium(title!),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// EmptyState - Empty state placeholder
// =============================================================================

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
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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

// =============================================================================
// CountBadge - Numeric badge for counts
// =============================================================================

class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const CountBadge({
    super.key,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = color ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: AppText.labelSmall(
        '$count',
        color: badgeColor,
      ),
    );
  }
}
