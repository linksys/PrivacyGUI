import 'dart:math';
import 'height_strategy.dart';

/// 基於 12-column grid 的元件約束
///
/// 所有 column 數值都是基於 12-column 設計，
/// 會自動按比例縮放到目前的 currentMaxColumns（4/8/12）。
class WidgetGridConstraints {
  /// 最小佔用欄數（基於 12-column）
  final int minColumns;

  /// 最大佔用欄數（基於 12-column）
  final int maxColumns;

  /// 理想/預設佔用欄數（基於 12-column）
  final int preferredColumns;

  /// 最小行數限制 (Optional, default 1)
  final int minHeightRows;

  /// 高度計算策略
  final HeightStrategy heightStrategy;

  const WidgetGridConstraints({
    required this.minColumns,
    required this.maxColumns,
    required this.preferredColumns,
    required this.heightStrategy,
    this.minHeightRows = 1,
  })  : assert(minColumns >= 1 && minColumns <= 12),
        assert(maxColumns >= minColumns && maxColumns <= 12),
        assert(
            preferredColumns >= minColumns && preferredColumns <= maxColumns);

  /// 按比例縮放到目標 column 數
  ///
  /// 例：preferredColumns=6 在 desktop(12) = 6
  ///     在 tablet(8) = 6 * 8 / 12 = 4
  int scaleToMaxColumns(int targetMaxColumns) {
    return (preferredColumns * targetMaxColumns / 12)
        .round()
        .clamp(1, targetMaxColumns);
  }

  /// 縮放 minColumns 到目標 column 數
  int scaleMinToMaxColumns(int targetMaxColumns) {
    return max(1, (minColumns * targetMaxColumns / 12).round());
  }

  /// 縮放 maxColumns 到目標 column 數
  int scaleMaxToMaxColumns(int targetMaxColumns) {
    return (maxColumns * targetMaxColumns / 12)
        .round()
        .clamp(1, targetMaxColumns);
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
