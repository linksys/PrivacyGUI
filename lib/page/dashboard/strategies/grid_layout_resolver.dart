import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/display_mode.dart';
import '../models/height_strategy.dart';
import '../models/widget_spec.dart';

/// 佈局解析器
///
/// 負責根據元件約束和目前螢幕狀態，計算實際應使用的欄數和尺寸。
/// 僅讀取 UI Kit 的公開 API，不修改 UI Kit。
class GridLayoutResolver {
  final BuildContext context;

  const GridLayoutResolver(this.context);

  /// 目前的最大欄數（4/8/12）
  int get currentMaxColumns => context.currentMaxColumns;

  /// 計算元件應使用的欄數
  ///
  /// [spec] 元件規格
  /// [mode] 顯示模式
  /// [availableColumns] 可用欄數（用於巢狀佈局，預設為 currentMaxColumns）
  int resolveColumns(
    WidgetSpec spec,
    DisplayMode mode, {
    int? availableColumns,
  }) {
    final constraints = spec.getConstraints(mode);
    final maxCols = availableColumns ?? currentMaxColumns;

    // 按比例縮放
    final scaled = constraints.scaleToMaxColumns(maxCols);

    // 確保在約束範圍內
    final scaledMin = constraints.scaleMinToMaxColumns(maxCols);
    final scaledMax = constraints.scaleMaxToMaxColumns(maxCols);

    return scaled.clamp(scaledMin, scaledMax);
  }

  /// 計算元件寬度
  double resolveWidth(
    WidgetSpec spec,
    DisplayMode mode, {
    int? availableColumns,
  }) {
    final columns =
        resolveColumns(spec, mode, availableColumns: availableColumns);
    return context.colWidth(columns);
  }

  /// 計算元件高度
  ///
  /// 回傳 null 表示使用 intrinsic sizing
  double? resolveHeight(
    WidgetSpec spec,
    DisplayMode mode, {
    int? availableColumns,
  }) {
    final constraints = spec.getConstraints(mode);
    final singleColWidth = context.colWidth(1);
    final width = resolveWidth(spec, mode, availableColumns: availableColumns);

    return switch (constraints.heightStrategy) {
      IntrinsicHeightStrategy() => null,
      ColumnBasedHeightStrategy(multiplier: final m) => singleColWidth * m,
      AspectRatioHeightStrategy(ratio: final r) => width / r,
    };
  }

  /// 建立約束後的 SizedBox 包裝
  ///
  /// 高度為 null 時不設定高度約束
  Widget wrapWithConstraints(
    Widget child, {
    required WidgetSpec spec,
    required DisplayMode mode,
    int? availableColumns,
  }) {
    final width = resolveWidth(spec, mode, availableColumns: availableColumns);
    final height =
        resolveHeight(spec, mode, availableColumns: availableColumns);

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}
