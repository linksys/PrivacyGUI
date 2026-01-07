import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'display_mode.dart';

/// 使用者的 Dashboard 佈局偏好
///
/// 儲存各元件的顯示模式設定。
class DashboardLayoutPreferences extends Equatable {
  /// 各元件的顯示模式（keyed by widget ID）
  final Map<String, DisplayMode> widgetModes;

  const DashboardLayoutPreferences({
    this.widgetModes = const {},
  });

  /// 取得元件模式（預設 normal）
  DisplayMode getMode(String widgetId) =>
      widgetModes[widgetId] ?? DisplayMode.normal;

  /// 更新元件模式
  DashboardLayoutPreferences setMode(String widgetId, DisplayMode mode) {
    return DashboardLayoutPreferences(
      widgetModes: {...widgetModes, widgetId: mode},
    );
  }

  /// 重設所有模式為預設
  DashboardLayoutPreferences reset() {
    return const DashboardLayoutPreferences();
  }

  /// JSON 序列化
  Map<String, dynamic> toJson() => {
        'widgetModes': widgetModes.map((k, v) => MapEntry(k, v.name)),
      };

  /// JSON 反序列化
  factory DashboardLayoutPreferences.fromJson(Map<String, dynamic> json) {
    final modesJson = json['widgetModes'] as Map<String, dynamic>?;
    if (modesJson == null) {
      return const DashboardLayoutPreferences();
    }

    final modes = <String, DisplayMode>{};
    for (final entry in modesJson.entries) {
      try {
        modes[entry.key] = DisplayMode.values.byName(entry.value as String);
      } catch (_) {
        // Ignore invalid values
      }
    }
    return DashboardLayoutPreferences(widgetModes: modes);
  }

  /// 從 JSON 字串解析
  factory DashboardLayoutPreferences.fromJsonString(String jsonString) {
    try {
      return DashboardLayoutPreferences.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } catch (_) {
      return const DashboardLayoutPreferences();
    }
  }

  /// 轉換為 JSON 字串
  String toJsonString() => jsonEncode(toJson());

  @override
  List<Object?> get props => [widgetModes];
}
