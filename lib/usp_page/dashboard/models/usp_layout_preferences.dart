import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/grid_widget_config.dart';
import 'usp_widget_specs.dart';

/// USP Dashboard layout preferences.
///
/// - [useCustomLayout] = false: grid locked to default layout, no editing.
/// - [useCustomLayout] = true: user can enter edit mode to customise.
class UspLayoutPreferences extends Equatable {
  final bool useCustomLayout;
  final Map<String, GridWidgetConfig> widgetConfigs;

  const UspLayoutPreferences({
    this.useCustomLayout = true,
    this.widgetConfigs = const {},
  });

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  GridWidgetConfig getConfig(String widgetId) {
    return widgetConfigs[widgetId] ?? _defaultConfig(widgetId);
  }

  DisplayMode getMode(String widgetId) => getConfig(widgetId).displayMode;

  bool isVisible(String widgetId) => getConfig(widgetId).visible;

  List<GridWidgetConfig> get orderedVisibleWidgets {
    final allConfigs =
        UspWidgetSpecs.all.map((spec) => getConfig(spec.id)).toList();
    final visible = allConfigs.where((c) => c.visible).toList();
    visible.sort((a, b) => a.order.compareTo(b.order));
    return visible;
  }

  List<GridWidgetConfig> get allWidgetsOrdered {
    final allConfigs =
        UspWidgetSpecs.all.map((spec) => getConfig(spec.id)).toList();
    allConfigs.sort((a, b) => a.order.compareTo(b.order));
    return allConfigs;
  }

  // ---------------------------------------------------------------------------
  // Setters (immutable)
  // ---------------------------------------------------------------------------

  UspLayoutPreferences updateConfig(GridWidgetConfig config) {
    return UspLayoutPreferences(
      useCustomLayout: useCustomLayout,
      widgetConfigs: {...widgetConfigs, config.widgetId: config},
    );
  }

  UspLayoutPreferences toggleCustomLayout(bool enabled) {
    return UspLayoutPreferences(
      useCustomLayout: enabled,
      widgetConfigs: widgetConfigs,
    );
  }

  UspLayoutPreferences setMode(String widgetId, DisplayMode mode) {
    final config = getConfig(widgetId);
    return updateConfig(config.copyWith(displayMode: mode));
  }

  UspLayoutPreferences setVisibility(String widgetId, bool visible) {
    final config = getConfig(widgetId);
    return updateConfig(config.copyWith(visible: visible));
  }

  // ---------------------------------------------------------------------------
  // Default
  // ---------------------------------------------------------------------------

  static GridWidgetConfig _defaultConfig(String widgetId) {
    final spec = UspWidgetSpecs.getById(widgetId);
    final defaultOrder =
        spec != null ? UspWidgetSpecs.all.indexOf(spec) : 0;
    return GridWidgetConfig(
      widgetId: widgetId,
      order: defaultOrder,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'useCustomLayout': useCustomLayout,
        'widgetConfigs': widgetConfigs.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
      };

  factory UspLayoutPreferences.fromJson(Map<String, dynamic> json) {
    final useCustomLayout = json['useCustomLayout'] as bool? ?? true;
    final configsJson = json['widgetConfigs'] as Map<String, dynamic>?;

    if (configsJson != null) {
      final configs = <String, GridWidgetConfig>{};
      for (final entry in configsJson.entries) {
        try {
          configs[entry.key] = GridWidgetConfig.fromJson(
            entry.value as Map<String, dynamic>,
          );
        } catch (_) {
          // Ignore invalid entries
        }
      }
      return UspLayoutPreferences(
        useCustomLayout: useCustomLayout,
        widgetConfigs: configs,
      );
    }

    return UspLayoutPreferences(useCustomLayout: useCustomLayout);
  }

  factory UspLayoutPreferences.fromJsonString(String jsonString) {
    try {
      return UspLayoutPreferences.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } catch (_) {
      return const UspLayoutPreferences();
    }
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  List<Object?> get props => [useCustomLayout, widgetConfigs];
}
