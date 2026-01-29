import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/display_mode.dart';
import '../models/height_strategy.dart';
import '../models/widget_spec.dart';

/// Layout Resolver
///
/// Calculates actual column counts and sizes based on component constraints
/// and current screen state. Only reads UI Kit public API, no modifications.
class GridLayoutResolver {
  final BuildContext context;

  const GridLayoutResolver(this.context);

  /// Current maximum columns (4/8/12)
  int get currentMaxColumns => context.currentMaxColumns;

  /// Calculate columns for a widget
  ///
  /// [spec] Widget specification
  /// [mode] Display mode
  /// [availableColumns] Available columns (for nested layouts, defaults to currentMaxColumns)
  /// [overrideColumns] User-specified column override from preferences (null = use spec default)
  int resolveColumns(
    WidgetSpec spec,
    DisplayMode mode, {
    int? availableColumns,
    int? overrideColumns,
  }) {
    final constraints = spec.getConstraints(mode);
    final maxCols = availableColumns ?? currentMaxColumns;

    // If user has overridden columns, scale that value instead of spec default
    if (overrideColumns != null) {
      // Scale the override from 12-column system to current max
      final scaledOverride = (overrideColumns * maxCols / 12).round();
      // Clamp to valid range
      return scaledOverride.clamp(1, maxCols);
    }

    // Use spec default - scale proportionally
    final scaled = constraints.scaleToMaxColumns(maxCols);

    // Ensure within constraints
    final scaledMin = constraints.scaleMinToMaxColumns(maxCols);
    final scaledMax = constraints.scaleMaxToMaxColumns(maxCols);

    return scaled.clamp(scaledMin, scaledMax);
  }

  /// Calculate width for a widget
  double resolveWidth(
    WidgetSpec spec,
    DisplayMode mode, {
    int? availableColumns,
    int? overrideColumns,
  }) {
    final columns = resolveColumns(
      spec,
      mode,
      availableColumns: availableColumns,
      overrideColumns: overrideColumns,
    );
    return context.colWidth(columns);
  }

  /// Calculate height for a widget
  ///
  /// Returns null for intrinsic sizing
  double? resolveHeight(
    WidgetSpec spec,
    DisplayMode mode, {
    int? availableColumns,
    int? overrideColumns,
  }) {
    final constraints = spec.getConstraints(mode);
    final singleColWidth = context.colWidth(1);
    final width = resolveWidth(
      spec,
      mode,
      availableColumns: availableColumns,
      overrideColumns: overrideColumns,
    );

    return switch (constraints.heightStrategy) {
      IntrinsicHeightStrategy() => null,
      ColumnBasedHeightStrategy(multiplier: final m) => singleColWidth * m,
      AspectRatioHeightStrategy(ratio: final r) => width / r,
    };
  }

  /// Calculate grid main axis cell count (height in grid units)
  ///
  /// Returns null for intrinsic sizing (use StaggeredGridTile.fit)
  num? resolveGridMainAxisCellCount(
    WidgetSpec spec,
    DisplayMode mode, {
    int? availableColumns,
    int? overrideColumns,
  }) {
    final constraints = spec.getConstraints(mode);
    final columns = resolveColumns(
      spec,
      mode,
      availableColumns: availableColumns,
      overrideColumns: overrideColumns,
    );

    return switch (constraints.heightStrategy) {
      IntrinsicHeightStrategy() => null,
      // In column-based strategy, the multiplier is essentially the row count
      // relative to a single column width.
      ColumnBasedHeightStrategy(multiplier: final m) => m,
      // ratio = width / height
      // height = width / ratio
      // heightUnits = columnUnits / ratio
      AspectRatioHeightStrategy(ratio: final r) => columns / r,
    };
  }

  /// Build constrained SizedBox wrapper
  ///
  /// Height is null when using intrinsic sizing
  Widget wrapWithConstraints(
    Widget child, {
    required WidgetSpec spec,
    required DisplayMode mode,
    int? availableColumns,
    int? overrideColumns,
  }) {
    final width = resolveWidth(
      spec,
      mode,
      availableColumns: availableColumns,
      overrideColumns: overrideColumns,
    );
    final height = resolveHeight(
      spec,
      mode,
      availableColumns: availableColumns,
      overrideColumns: overrideColumns,
    );

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}
