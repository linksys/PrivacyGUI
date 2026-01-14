import 'dart:math';
import 'height_strategy.dart';

/// Grid constraints based on a 12-column layout
///
/// All column values are designed based on 12 columns,
/// and will automatically scale to the current currentMaxColumns (4/8/12).
class WidgetGridConstraints {
  /// Minimum occupied columns (based on 12-column)
  final int minColumns;

  /// Maximum occupied columns (based on 12-column)
  final int maxColumns;

  /// Preferred/Default occupied columns (based on 12-column)
  final int preferredColumns;

  /// Minimum row height constraints (Optional, default 1)
  final int minHeightRows;

  /// Maximum row height constraints (Optional, default 12)
  final int maxHeightRows;

  /// Height Calculation Strategy
  final HeightStrategy heightStrategy;

  const WidgetGridConstraints({
    required this.minColumns,
    required this.maxColumns,
    required this.preferredColumns,
    required this.heightStrategy,
    this.minHeightRows = 1,
    this.maxHeightRows = 12,
  })  : assert(minColumns >= 1 && minColumns <= 12),
        assert(maxColumns >= minColumns && maxColumns <= 12),
        assert(
            preferredColumns >= minColumns && preferredColumns <= maxColumns),
        assert(maxHeightRows >= minHeightRows);

  /// Scale proportionally to target max columns
  ///
  /// Example: preferredColumns=6 on desktop(12) = 6
  ///          on tablet(8) = 6 * 8 / 12 = 4
  int scaleToMaxColumns(int targetMaxColumns) {
    return (preferredColumns * targetMaxColumns / 12)
        .round()
        .clamp(1, targetMaxColumns);
  }

  /// Scale minColumns to target max columns
  int scaleMinToMaxColumns(int targetMaxColumns) {
    return max(1, (minColumns * targetMaxColumns / 12).round());
  }

  /// Scale maxColumns to target max columns
  int scaleMaxToMaxColumns(int targetMaxColumns) {
    return (maxColumns * targetMaxColumns / 12)
        .round()
        .clamp(1, targetMaxColumns);
  }

  /// Calculate preferred height in grid (in cells)
  ///
  /// Used for StaggeredGrid and sliver_dashboard height settings.
  /// [columns] is the actual occupied columns (used for AspectRatio calculation)
  int getPreferredHeightCells({int? columns}) {
    final cols = columns ?? preferredColumns;
    return switch (heightStrategy) {
      ColumnBasedHeightStrategy(:final multiplier) => multiplier.ceil(),
      AspectRatioHeightStrategy(:final ratio) =>
        (cols / ratio).ceil().clamp(1, 12),
      IntrinsicHeightStrategy() =>
        minHeightRows.clamp(2, 6), // Unified default: 2-6
    };
  }

  /// Get height range (min, max)
  ///
  /// Used for sliver_dashboard LayoutItem constraints
  (double min, double max) getHeightRange() {
    return (minHeightRows.toDouble(), maxHeightRows.toDouble());
  }

  @override
  bool operator ==(Object other) =>
      other is WidgetGridConstraints &&
      other.minColumns == minColumns &&
      other.maxColumns == maxColumns &&
      other.preferredColumns == preferredColumns &&
      other.heightStrategy == heightStrategy;

  @override
  int get hashCode => Object.hash(
        minColumns,
        maxColumns,
        preferredColumns,
        heightStrategy,
      );
}
