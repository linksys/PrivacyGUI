import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Reusable skeleton placeholders for individual dashboard cards.
///
/// Each variant matches the visual structure of a real card type, so the
/// shimmer placeholder occupies the same grid space and transitions smoothly
/// to real content when the domain data provider finishes loading.
///
/// Variants:
/// - [CardSkeleton.stats] — 4 stat tiles in a row (Stats Panel)
/// - [CardSkeleton.info] — title + N label-value rows (Device Info, LAN, etc.)
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

  /// Title + N label-value rows — matches info cards (Device Info, LAN, etc.).
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
  // Info card — title + configurable number of label-value rows
  // ---------------------------------------------------------------------------

  // Vary value widths so it looks natural
  static const _valueWidths = [180.0, 140.0, 200.0, 120.0, 160.0];

  Widget _buildInfo() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton.text(width: 120, height: 20),
            AppGap.xl(),
            for (int i = 0; i < _rows; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    AppSkeleton.text(width: 100),
                    AppGap.xl(),
                    AppSkeleton.text(
                      width: _valueWidths[i % _valueWidths.length],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // List card — title + action buttons + configurable item rows
  // ---------------------------------------------------------------------------

  Widget _buildList() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title + action button placeholders
            Row(
              children: [
                AppSkeleton.text(width: 140, height: 20),
                AppGap.md(),
                AppSkeleton.capsule(width: 28, height: 20),
                const Spacer(),
                AppSkeleton(
                    width: 28,
                    height: 28,
                    borderRadius: BorderRadius.circular(6)),
              ],
            ),
            AppGap.xl(),
            for (int i = 0; i < _rows; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    AppSkeleton.capsule(width: 36, height: 20),
                    AppGap.md(),
                    Expanded(
                        child: AppSkeleton.text(width: double.infinity)),
                    AppGap.md(),
                    AppSkeleton.text(width: 80),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chart card — title + tab bar + chart area
  // ---------------------------------------------------------------------------

  Widget _buildChart() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            AppSkeleton.text(width: 140, height: 20),
            AppGap.lg(),
            // Tab bar placeholder
            Row(
              children: [
                AppSkeleton.capsule(width: 60, height: 28),
                AppGap.sm(),
                AppSkeleton.capsule(width: 60, height: 28),
                AppGap.sm(),
                AppSkeleton.capsule(width: 60, height: 28),
              ],
            ),
            AppGap.lg(),
            // Chart area
            AppSkeleton(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Topology card — title + large placeholder
  // ---------------------------------------------------------------------------

  Widget _buildTopology() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppSkeleton.text(width: 140, height: 20),
                AppGap.md(),
                AppSkeleton.capsule(width: 32, height: 20),
              ],
            ),
            AppGap.xl(),
            AppSkeleton(
              width: double.infinity,
              height: 320,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
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
            AppSkeleton.text(width: 160),
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
