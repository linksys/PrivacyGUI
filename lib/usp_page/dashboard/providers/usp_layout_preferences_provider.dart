import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usp_layout_preferences.dart';
import 'usp_layout_controller.dart';

const _uspPrefsKey = 'usp_layout_preferences';

/// Provider for USP Dashboard layout preferences.
final uspLayoutPreferencesProvider =
    NotifierProvider<UspLayoutPreferencesNotifier, UspLayoutPreferences>(
  () => UspLayoutPreferencesNotifier(),
);

/// Manages USP Dashboard layout preferences.
///
/// Handles loading, saving, and updating user preferences for widget
/// visibility and custom layout toggle. Persisted to SharedPreferences.
///
/// Key behaviour: toggling custom layout OFF also resets the grid layout
/// to ensure [useCustomLayout = false] always shows the default layout.
class UspLayoutPreferencesNotifier extends Notifier<UspLayoutPreferences> {
  @override
  UspLayoutPreferences build() {
    _loadFromPrefs();
    return const UspLayoutPreferences();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_uspPrefsKey);
    if (json != null) {
      state = UspLayoutPreferences.fromJsonString(json);
    }
  }

  /// Toggle custom layout on/off.
  ///
  /// When toggling OFF, also resets the grid layout to default so that
  /// the locked mode always shows the original Bento grid.
  Future<void> toggleCustomLayout(bool enabled) async {
    state = state.toggleCustomLayout(enabled);
    await _saveToPrefs();

    if (!enabled) {
      await ref.read(uspSliverDashboardControllerProvider.notifier).resetLayout();
    }
  }

  /// Set visibility for a specific widget.
  Future<void> setVisibility(String widgetId, bool visible) async {
    state = state.setVisibility(widgetId, visible);
    await _saveToPrefs();
  }

  /// Restore preferences from a snapshot (used for edit mode cancel).
  Future<void> restoreSnapshot(UspLayoutPreferences snapshot) async {
    state = snapshot;
    await _saveToPrefs();
  }

  /// Reset all preferences to defaults.
  ///
  /// Sets [useCustomLayout] to false, clears widget configs,
  /// and resets the grid layout.
  Future<void> resetToDefaults() async {
    state = const UspLayoutPreferences();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uspPrefsKey);
    await ref.read(uspSliverDashboardControllerProvider.notifier).resetLayout();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uspPrefsKey, state.toJsonString());
  }
}
