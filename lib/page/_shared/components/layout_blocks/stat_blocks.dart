import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'base_blocks.dart';
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
// SummaryTile - Card-summary tile (leading marker + value + caption)
// =============================================================================

/// A card's summary tile: a leading status marker, a headline value, and the
/// caption naming what the value describes.
///
/// Distinct from its two neighbours in this directory, which are what a reader
/// looking for a tile will find first: [StatTile] is an [AppCard] with the icon
/// *above* a centred value, five-across in the stats panel, and [MetricTile] is a
/// [LayoutBlock] with a small inline icon beside the label and no marker. This
/// one is the wide summary row a dashboard card puts at the top of its content.
///
/// Two cards hand-rolled it before #1275 — `usp_ethernet_ports_card.dart`'s
/// `_SummaryTile` and `usp_connected_devices_card.dart`'s `_StatusCount` — and
/// the shape came out the same both times because the constraint is: the marker's
/// colour and glyph are the only things identifying *which* group the tile
/// describes, so the marker keeps its design size and the text is what yields.
///
/// The arrangement *above* the tile — side by side or stacked, and at what
/// measured width it flips — stays with each card: every threshold is measured
/// from that card's own longest locale, and only two cards have one (see
/// `doc/dashboard/dashboard_density_design.md` §2.10e).
class SummaryTile extends StatelessWidget {
  /// Marker, then the value stacked over its caption — the wide form.
  ///
  /// Both lines are capped at one line and ellipsized: stacked, each owns the
  /// full width left over beside the marker, so a long localized state word has
  /// to yield somewhere, and a clipped `Disconnec…` still reads as a state.
  const SummaryTile.stacked({
    super.key,
    required this.leading,
    required this.value,
    required this.label,
    this.compact = false,
  }) : _textAxis = Axis.vertical;

  /// Marker, value and caption on one line, centred as a unit — the narrow form
  /// for a value short by construction (a count and one word).
  ///
  /// Neither line yields here, and that is the point: a count is meaningless
  /// truncated and a state word ellipsized to two characters names nothing, so
  /// the arrangement above must give this tile the width instead. Nor is
  /// [compact] offered — the two cards that tighten their padding do it to fit a
  /// measured viewport when *stacked*, and an inline tile is one line tall
  /// already.
  const SummaryTile.inline({
    super.key,
    required this.leading,
    required this.value,
    required this.label,
  })  : compact = false,
        _textAxis = Axis.horizontal;

  /// The status marker. Sized by the caller, since the two forms use very
  /// different ones (a 40px tinted disc, a 10px dot) and the tile has no basis
  /// for preferring either.
  final Widget leading;

  /// The headline: a count, or the state word itself.
  final String value;

  /// What the value describes.
  final String label;

  /// Trades 4px of padding per side for vertical budget; see [InfoGrid.compact],
  /// which carries the measurements this shares.
  final bool compact;

  final Axis _textAxis;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBlock(
      padding: compact ? BlockConstants.paddingSm : BlockConstants.paddingMd,
      child: switch (_textAxis) {
        Axis.vertical => Row(
            children: [
              leading,
              AppGap.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleSmall(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppText.bodySmall(
                      label,
                      color: colorScheme.onSurfaceVariant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        Axis.horizontal => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              AppGap.sm(),
              AppText.titleSmall(value),
              AppGap.xs(),
              AppText.bodySmall(label, color: colorScheme.onSurfaceVariant),
            ],
          ),
      },
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
