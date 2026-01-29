/// Height Calculation Strategy
///
/// Defines how the height of Dashboard components is calculated.
/// Uses a sealed class to ensure type-safe pattern matching.
sealed class HeightStrategy {
  const HeightStrategy();

  /// Let the component determine its own height (intrinsic sizing)
  const factory HeightStrategy.intrinsic() = IntrinsicHeightStrategy;

  /// Height = Single column width * multiplier
  ///
  /// Example: multiplier=2.0 means height is 2 times the column width
  const factory HeightStrategy.columnBased(double multiplier) =
      ColumnBasedHeightStrategy;

  /// Specialized for Bento Grid: Force specify the "Row Span" of the grid
  ///
  /// Logically equivalent to [ColumnBasedHeightStrategy], but semantically clearer.
  /// Example: rows=2 means the component occupies 2 units of height.
  const factory HeightStrategy.strict(double rows) = ColumnBasedHeightStrategy;

  /// Fixed Aspect Ratio
  ///
  /// [ratio] = width / height, e.g., 16/9 = 1.78
  const factory HeightStrategy.aspectRatio(double ratio) =
      AspectRatioHeightStrategy;
}

/// Let component determine height
class IntrinsicHeightStrategy extends HeightStrategy {
  const IntrinsicHeightStrategy();

  @override
  bool operator ==(Object other) => other is IntrinsicHeightStrategy;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Height based on column width multiplier
class ColumnBasedHeightStrategy extends HeightStrategy {
  /// Column width multiplier, height = singleColumnWidth * multiplier
  final double multiplier;

  const ColumnBasedHeightStrategy(this.multiplier);

  @override
  bool operator ==(Object other) =>
      other is ColumnBasedHeightStrategy && other.multiplier == multiplier;

  @override
  int get hashCode => multiplier.hashCode;
}

/// Fixed Aspect Ratio
class AspectRatioHeightStrategy extends HeightStrategy {
  /// Aspect ratio (width / height)
  final double ratio;

  const AspectRatioHeightStrategy(this.ratio);

  @override
  bool operator ==(Object other) =>
      other is AspectRatioHeightStrategy && other.ratio == ratio;

  @override
  int get hashCode => ratio.hashCode;
}
