import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'dashboard_widget_specs.dart';
import 'display_mode.dart';
import 'grid_widget_config.dart';

/// User's Dashboard layout preferences.
///
/// Stores widget display modes and grid configurations for custom layouts.
class DashboardLayoutPreferences extends Equatable {
  /// Whether to use custom layout (unified Wrap) or legacy hardcoded layouts
  final bool useCustomLayout;

  /// Widget grid configurations (keyed by widget ID)
  final Map<String, GridWidgetConfig> widgetConfigs;

  const DashboardLayoutPreferences({
    this.useCustomLayout = false,
    this.widgetConfigs = const {},
  });

  // ---------------------------------------------------------------------------
  // Configuration Getters
  // ---------------------------------------------------------------------------

  /// Get config for a widget (creates default if not exists)
  GridWidgetConfig getConfig(String widgetId) {
    return widgetConfigs[widgetId] ?? _defaultConfig(widgetId);
  }

  /// Get display mode for a widget
  DisplayMode getMode(String widgetId) => getConfig(widgetId).displayMode;

  /// Get visibility for a widget
  bool isVisible(String widgetId) => getConfig(widgetId).visible;

  /// Get ordered list of visible widget configs
  List<GridWidgetConfig> get orderedVisibleWidgets {
    final allConfigs =
        DashboardWidgetSpecs.all.map((spec) => getConfig(spec.id)).toList();
    final visible = allConfigs.where((c) => c.visible).toList();
    visible.sort((a, b) => a.order.compareTo(b.order));
    return visible;
  }

  /// Get all widget configs in order (including hidden)
  List<GridWidgetConfig> get allWidgetsOrdered {
    final allConfigs =
        DashboardWidgetSpecs.all.map((spec) => getConfig(spec.id)).toList();
    allConfigs.sort((a, b) => a.order.compareTo(b.order));
    return allConfigs;
  }

  /// Get custom layout widgets in order (atomic widgets only, no VPN)
  ///
  /// Used by the settings panel to show only atomic widgets for Custom Layout.
  /// Get custom layout widgets in order (atomic widgets only, no VPN in settings usually, but here strict to custom list)
  ///
  /// Used by the settings panel to show only atomic widgets for Custom Layout.
  List<GridWidgetConfig> get customWidgetsOrdered {
    // We want all widgets defined in DashboardWidgetSpecs.customWidgets.
    // VPN is typically allowed in custom layout, so we include it.
    // If we need to filter specific ones out (like if VPN is not supported), logic belongs elsewhere or via requirements.
    // However, the original code filtered out VPN explicitly from the ordered list for some reason.
    // If the intention is "editable widgets", then VPN is usually editable.
    // Let's stick to returning configs for all declared customWidgets.
    // Note: The previous logic filtered out `DashboardWidgetSpecs.vpn.id`.
    // Now we have `vpn_custom`. We should check if we need to filter `vpn_custom`.
    // Assuming we want to show all available atomic widgets.

    final atomicSpecs = DashboardWidgetSpecs.customWidgets;

    // Note: The original code had: .where((spec) => spec.id != DashboardWidgetSpecs.vpn.id)
    // This implies VPN wasn't meant to be reorderable/toggleable in the simplified list?
    // Or maybe it was just not part of the "custom atomic" set at that time.
    // For now, let's include everything in customWidgets, as that list is now explicit.

    final allConfigs = atomicSpecs.map((spec) => getConfig(spec.id)).toList();
    allConfigs.sort((a, b) => a.order.compareTo(b.order));
    return allConfigs;
  }

  // ---------------------------------------------------------------------------
  // Configuration Setters
  // ---------------------------------------------------------------------------

  /// Update a widget's configuration
  DashboardLayoutPreferences updateConfig(GridWidgetConfig config) {
    return DashboardLayoutPreferences(
      useCustomLayout: useCustomLayout,
      widgetConfigs: {...widgetConfigs, config.widgetId: config},
    );
  }

  /// Toggle custom layout usage
  DashboardLayoutPreferences toggleCustomLayout(bool enabled) {
    return DashboardLayoutPreferences(
      useCustomLayout: enabled,
      widgetConfigs: widgetConfigs,
    );
  }

  /// Update display mode for a widget
  DashboardLayoutPreferences setMode(String widgetId, DisplayMode mode) {
    final config = getConfig(widgetId);
    return updateConfig(config.copyWith(displayMode: mode));
  }

  /// Update visibility for a widget
  DashboardLayoutPreferences setVisibility(String widgetId, bool visible) {
    final config = getConfig(widgetId);
    return updateConfig(config.copyWith(visible: visible));
  }

  /// Update column span for a widget
  DashboardLayoutPreferences setColumnSpan(String widgetId, int? columnSpan) {
    final config = getConfig(widgetId);
    return updateConfig(config.copyWith(
      columnSpan: columnSpan,
      clearColumnSpan: columnSpan == null,
    ));
  }

  /// Reorder widgets (all widgets)
  DashboardLayoutPreferences reorder(int oldIndex, int newIndex) {
    final ordered = allWidgetsOrdered.toList();
    if (oldIndex < 0 || oldIndex >= ordered.length) return this;
    if (newIndex < 0 || newIndex >= ordered.length) return this;

    final item = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, item);

    final newConfigs = <String, GridWidgetConfig>{};
    for (var i = 0; i < ordered.length; i++) {
      final config = ordered[i];
      newConfigs[config.widgetId] = config.copyWith(order: i);
    }

    return DashboardLayoutPreferences(
      useCustomLayout: useCustomLayout,
      widgetConfigs: newConfigs,
    );
  }

  /// Reorder custom widgets (atomic widgets only)
  DashboardLayoutPreferences reorderCustomWidget(int oldIndex, int newIndex) {
    final ordered = customWidgetsOrdered.toList();
    if (oldIndex < 0 || oldIndex >= ordered.length) return this;
    if (newIndex < 0 || newIndex >= ordered.length) return this;

    final item = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, item);

    // Update order for custom widgets only
    final newConfigs = Map<String, GridWidgetConfig>.from(widgetConfigs);
    for (var i = 0; i < ordered.length; i++) {
      final config = ordered[i];
      newConfigs[config.widgetId] = config.copyWith(order: i);
    }

    return DashboardLayoutPreferences(
      useCustomLayout: useCustomLayout,
      widgetConfigs: newConfigs,
    );
  }

  /// Reset all preferences to defaults
  DashboardLayoutPreferences reset() {
    return const DashboardLayoutPreferences();
  }

  // ---------------------------------------------------------------------------
  // Default Configuration
  // ---------------------------------------------------------------------------

  /// Generate default config for a widget
  static GridWidgetConfig _defaultConfig(String widgetId) {
    final spec = DashboardWidgetSpecs.getById(widgetId);
    final defaultOrder =
        spec != null ? DashboardWidgetSpecs.all.indexOf(spec) : 0;
    return GridWidgetConfig(
      widgetId: widgetId,
      order: defaultOrder,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON Serialization
  // ---------------------------------------------------------------------------

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'useCustomLayout': useCustomLayout,
        'widgetConfigs': widgetConfigs.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
      };

  /// JSON deserialization
  factory DashboardLayoutPreferences.fromJson(Map<String, dynamic> json) {
    final useCustomLayout = json['useCustomLayout'] as bool? ?? false;
    final configsJson = json['widgetConfigs'] as Map<String, dynamic>?;

    // Legacy support: migrate from old widgetModes format
    final legacyModes = json['widgetModes'] as Map<String, dynamic>?;

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
      return DashboardLayoutPreferences(
        useCustomLayout: useCustomLayout,
        widgetConfigs: configs,
      );
    }

    // Migrate from legacy format
    if (legacyModes != null) {
      final configs = <String, GridWidgetConfig>{};
      var order = 0;
      for (final entry in legacyModes.entries) {
        try {
          final mode = DisplayMode.values.byName(entry.value as String);
          configs[entry.key] = GridWidgetConfig(
            widgetId: entry.key,
            order: order++,
            displayMode: mode,
          );
        } catch (_) {
          // Ignore invalid values
        }
      }
      return DashboardLayoutPreferences(widgetConfigs: configs);
    }

    return const DashboardLayoutPreferences();
  }

  /// Parse from JSON string
  factory DashboardLayoutPreferences.fromJsonString(String jsonString) {
    try {
      return DashboardLayoutPreferences.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } catch (_) {
      return const DashboardLayoutPreferences();
    }
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  @override
  List<Object?> get props => [useCustomLayout, widgetConfigs];
}
