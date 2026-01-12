import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_layout_preferences.dart';
import '../models/display_mode.dart';

const _prefsKey = 'dashboard_layout_preferences';

/// Provider for Dashboard layout preferences
final dashboardPreferencesProvider =
    NotifierProvider<DashboardPreferencesNotifier, DashboardLayoutPreferences>(
  () => DashboardPreferencesNotifier(),
);

/// Notifier for managing Dashboard layout preferences
///
/// Handles loading, saving, and updating user preferences for widget
/// display modes, visibility, column spans, and ordering.
/// Preferences are persisted to SharedPreferences.
class DashboardPreferencesNotifier
    extends Notifier<DashboardLayoutPreferences> {
  @override
  DashboardLayoutPreferences build() {
    _loadFromPrefs();
    return const DashboardLayoutPreferences();
  }

  /// Load preferences from SharedPreferences
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json != null) {
      state = DashboardLayoutPreferences.fromJsonString(json);
    }
  }

  /// Set the display mode for a specific widget
  Future<void> setWidgetMode(String widgetId, DisplayMode mode) async {
    state = state.setMode(widgetId, mode);
    await _saveToPrefs();
  }

  /// Set the visibility for a specific widget
  Future<void> setVisibility(String widgetId, bool visible) async {
    state = state.setVisibility(widgetId, visible);
    await _saveToPrefs();
  }

  /// Set the column span for a specific widget
  Future<void> setColumnSpan(String widgetId, int? columnSpan) async {
    state = state.setColumnSpan(widgetId, columnSpan);
    await _saveToPrefs();
  }

  /// Reorder widgets
  Future<void> reorder(int oldIndex, int newIndex) async {
    state = state.reorder(oldIndex, newIndex);
    await _saveToPrefs();
  }

  /// Reorder custom widgets (atomic widgets only)
  Future<void> reorderCustomWidget(int oldIndex, int newIndex) async {
    state = state.reorderCustomWidget(oldIndex, newIndex);
    await _saveToPrefs();
  }

  /// Toggle custom layout usage
  Future<void> toggleCustomLayout(bool enabled) async {
    state = state.toggleCustomLayout(enabled);
    await _saveToPrefs();
  }

  /// Save preferences to SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, state.toJsonString());
  }

  /// Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    state = const DashboardLayoutPreferences();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
