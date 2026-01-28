/// 高度計算策略
///
/// 定義 Dashboard 元件的高度計算方式。
/// 使用 sealed class 確保類型安全的模式匹配。
sealed class HeightStrategy {
  const HeightStrategy();

  /// 讓元件自己決定高度（intrinsic sizing）
  const factory HeightStrategy.intrinsic() = IntrinsicHeightStrategy;

  /// 高度 = 單個 column 寬度 × 倍數
  ///
  /// 例：multiplier=2.0 表示高度為 2 個 column 寬度
  const factory HeightStrategy.columnBased(double multiplier) =
      ColumnBasedHeightStrategy;

  /// 固定寬高比
  ///
  /// [ratio] = width / height，例：16/9 = 1.78
  const factory HeightStrategy.aspectRatio(double ratio) =
      AspectRatioHeightStrategy;
}

/// 讓元件自行決定高度
class IntrinsicHeightStrategy extends HeightStrategy {
  const IntrinsicHeightStrategy();

  @override
  bool operator ==(Object other) => other is IntrinsicHeightStrategy;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// 基於欄寬倍數的高度
class ColumnBasedHeightStrategy extends HeightStrategy {
  /// 欄寬倍數，高度 = singleColumnWidth * multiplier
  final double multiplier;

  const ColumnBasedHeightStrategy(this.multiplier);

  @override
  bool operator ==(Object other) =>
      other is ColumnBasedHeightStrategy && other.multiplier == multiplier;

  @override
  int get hashCode => multiplier.hashCode;
}

/// 固定寬高比
class AspectRatioHeightStrategy extends HeightStrategy {
  /// 寬高比 (width / height)
  final double ratio;

  const AspectRatioHeightStrategy(this.ratio);

  @override
  bool operator ==(Object other) =>
      other is AspectRatioHeightStrategy && other.ratio == ratio;

  @override
  int get hashCode => ratio.hashCode;
}
