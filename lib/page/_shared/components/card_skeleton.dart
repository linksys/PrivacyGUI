import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Reusable skeleton placeholders for individual dashboard cards.
///
/// Each variant matches the visual structure of a real card type, so the
/// shimmer placeholder occupies the same grid space and transitions smoothly
/// to real content when the domain data provider finishes loading.
///
/// Variants:
/// - [CardSkeleton.stats] — 4 stat tiles in a row (Stats Panel)
/// - [CardSkeleton.info] — hero block + metric tiles + grid (Device Info, Network Status)
/// - [CardSkeleton.list] — title + badge + N list item rows (Devices, DHCP, etc.)
/// - [CardSkeleton.chart] — title + tab bar placeholder + chart area
/// - [CardSkeleton.topology] — title + large visualization placeholder
/// - [CardSkeleton.status] — single-row connection indicator

enum _SkeletonVariant { stats, info, list, chart, topology, status }

class CardSkeleton extends StatelessWidget {
  final _SkeletonVariant _variant;
  final int _rows;

  const CardSkeleton._({required _SkeletonVariant variant, int rows = 3})
      : _variant = variant,
        _rows = rows;

  /// 4 stat tiles in a row — matches [UspStatsPanel].
  const factory CardSkeleton.stats() = _CardSkeletonStats;

  /// Hero block + metric tiles + grid — matches new info cards (Device Info, Network Status).
  const CardSkeleton.info({required int rows})
      : _variant = _SkeletonVariant.info,
        _rows = rows;

  /// Title + badge + N list item rows — matches list cards (Devices, DHCP, etc.).
  const CardSkeleton.list({required int rows})
      : _variant = _SkeletonVariant.list,
        _rows = rows;

  /// Title + tab bar placeholder + chart area — matches multi-tab chart cards.
  const CardSkeleton.chart()
      : _variant = _SkeletonVariant.chart,
        _rows = 0;

  /// Title + large visualization placeholder — matches topology card.
  const CardSkeleton.topology()
      : _variant = _SkeletonVariant.topology,
        _rows = 0;

  /// Single-row connection indicator.
  const CardSkeleton.status()
      : _variant = _SkeletonVariant.status,
        _rows = 0;

  @override
  Widget build(BuildContext context) {
    // The loading state degrades with the card (#1299).
    //
    // Every variant below is a stack of fixed-height blocks sized for the card's
    // own footprint — the shortest is 86px of content in a 3-row box. A picked
    // popup tile is one row, 86px of *box*, and the pick is not a width the grid
    // chose: it holds while the card's data loads, so on a cold boot these
    // rectangles overflow the box the pick created. `CardSkeleton.list(rows: 3)`
    // was 94px over at the narrowest realization.
    //
    // Read from the scope for the same reason [DashboardCardTemplate] reads it
    // there: the density is decided once, above the card, and every card's
    // loading branch goes through this widget, so none of them can miss the
    // behaviour or implement it differently.
    if (CardDensityScope.of(context) == CardDensity.popup) {
      return _buildPopup();
    }

    return switch (_variant) {
      _SkeletonVariant.stats => _buildStats(),
      _SkeletonVariant.info => _buildInfo(),
      _SkeletonVariant.list => _buildList(),
      _SkeletonVariant.chart => _buildChart(),
      _SkeletonVariant.topology => _buildTopology(),
      _SkeletonVariant.status => _buildStatus(),
    };
  }

  // ---------------------------------------------------------------------------
  // Popup form — the icon block and the one line it degrades to
  // ---------------------------------------------------------------------------

  /// [CardPopupForm]'s own shape, in grey.
  ///
  /// A centred block over one line, `MainAxisSize.min` and `Flexible` exactly as
  /// that form has them, so the placeholder and the form it resolves into occupy
  /// the same space and the transition does not jump. The variant is ignored —
  /// the popup form is the same on every card, so there is nothing left for the
  /// variants to distinguish.
  ///
  /// The two sizes are approximations of an icon and a value, not promises: a
  /// skeleton is a grey rectangle, and the only thing that has to hold is that it
  /// fits in one grid row.
  Widget _buildPopup() {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSkeleton(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          AppGap.sm(),
          Flexible(child: AppSkeleton.text(width: 64, height: 16)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Info card — hero block + metric tiles + grid (matches new design)
  // ---------------------------------------------------------------------------

  Widget _buildInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SizedBox(
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppSkeleton.text(width: 140, height: 20),
            ),
          ),
          AppGap.md(),
          // Hero block
          AppSkeleton(
            width: double.infinity,
            height: 104,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          AppGap.sm(),
          // Metric tiles row
          Row(
            children: [
              Expanded(
                child: AppSkeleton(
                  width: double.infinity,
                  height: 64,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: AppSkeleton(
                  width: double.infinity,
                  height: 64,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
              ),
            ],
          ),
          AppGap.sm(),
          // Grid row
          Row(
            children: [
              Expanded(
                child: AppSkeleton(
                  width: double.infinity,
                  height: 52,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
              ),
              if (_rows > 1) ...[
                AppGap.sm(),
                Expanded(
                  child: AppSkeleton(
                    width: double.infinity,
                    height: 52,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // List card — title + action buttons + configurable item rows
  // ---------------------------------------------------------------------------

  Widget _buildList() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title + action button placeholders.
          // The title bar is Flexible so the row's fixed parts (gap + capsule +
          // action square = 72px) always fit: at the narrowest grid width the
          // card only offers ~157px of content box, and the 140px title alone
          // pushed this 51px over (#1227). A skeleton is a grey rectangle, so
          // shrinking it costs nothing visually.
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Flexible(child: AppSkeleton.text(width: 140, height: 20)),
                AppGap.md(),
                AppSkeleton.capsule(width: 28, height: 20),
                const Spacer(),
                AppSkeleton(
                    width: 28,
                    height: 28,
                    borderRadius: BorderRadius.circular(6)),
              ],
            ),
          ),
          AppGap.md(),
          // List items
          AppSkeleton(
            width: double.infinity,
            height: _rows * 44.0,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chart card — title + tab bar + chart area
  // ---------------------------------------------------------------------------

  Widget _buildChart() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SizedBox(
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppSkeleton.text(width: 140, height: 20),
            ),
          ),
          AppGap.md(),
          // Tab bar placeholder. Three 60px capsules plus gaps need 196px, more
          // than a narrow card has; Flexible lets them share whatever is there.
          Row(
            children: [
              Flexible(child: AppSkeleton.capsule(width: 60, height: 28)),
              AppGap.sm(),
              Flexible(child: AppSkeleton.capsule(width: 60, height: 28)),
              AppGap.sm(),
              Flexible(child: AppSkeleton.capsule(width: 60, height: 28)),
            ],
          ),
          AppGap.lg(),
          // Chart area
          Expanded(
            child: AppSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Topology card — title + large placeholder
  // ---------------------------------------------------------------------------

  Widget _buildTopology() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                // Same latent overflow as the list header: 188px of fixed width
                // in a row that can be narrower than that.
                Flexible(child: AppSkeleton.text(width: 140, height: 20)),
                AppGap.md(),
                AppSkeleton.capsule(width: 32, height: 20),
              ],
            ),
          ),
          AppGap.md(),
          Expanded(
            child: AppSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Connection status — single-row card
  // ---------------------------------------------------------------------------

  Widget _buildStatus() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AppSkeleton.circular(size: 12),
            AppGap.md(),
            // Same latent overflow as the list header: the 160px title bar is
            // wider than a narrow card's content box on its own.
            Flexible(child: AppSkeleton.text(width: 160)),
            const Spacer(),
            AppSkeleton.text(width: 60),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats — delegated to subclass for const
  // ---------------------------------------------------------------------------

  Widget _buildStats() {
    // Should not be called — stats variant uses _CardSkeletonStats
    return const SizedBox.shrink();
  }
}

/// Stats panel skeleton — 4 stat tiles in a row.
///
/// Separate class because the stats panel has a unique multi-card layout
/// that cannot be expressed as a single AppCard with parameterized rows.
class _CardSkeletonStats extends CardSkeleton {
  const _CardSkeletonStats() : super._(variant: _SkeletonVariant.stats);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.sm),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSkeleton(
                      width: 24,
                      height: 24,
                      borderRadius: BorderRadius.circular(4)),
                  AppGap.sm(),
                  AppSkeleton.text(width: 40, height: 18),
                  AppGap.xs(),
                  AppSkeleton.text(width: 48),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
