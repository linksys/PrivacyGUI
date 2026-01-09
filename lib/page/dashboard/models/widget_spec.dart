import 'display_mode.dart';
import 'widget_grid_constraints.dart';

/// 元件規格定義
///
/// 每種 DisplayMode 對應不同的 grid 約束。
class WidgetSpec {
  /// 元件唯一識別碼
  final String id;

  /// 顯示名稱（用於設定 UI）
  final String displayName;

  /// 各 DisplayMode 的約束定義
  final Map<DisplayMode, WidgetGridConstraints> constraints;

  const WidgetSpec({
    required this.id,
    required this.displayName,
    required this.constraints,
  });

  /// 取得指定模式的約束，若無則回傳 normal 模式
  WidgetGridConstraints getConstraints(DisplayMode mode) =>
      constraints[mode] ?? constraints[DisplayMode.normal]!;

  @override
  bool operator ==(Object other) =>
      other is WidgetSpec && other.id == id && other.displayName == displayName;

  @override
  int get hashCode => Object.hash(id, displayName);
}
