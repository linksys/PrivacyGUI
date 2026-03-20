import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usp_dashboard_preset.dart';
import '../models/usp_layout_preferences.dart';
import 'usp_layout_controller.dart';

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
  final Completer<void> _initCompleter = Completer<void>();

  /// Completes when the initial load from SharedPreferences is done.
  /// Await this before capturing snapshots to avoid race conditions
  /// where the default state (preset = null) is captured before the
  /// persisted state is loaded.
  Future<void> get initialized => _initCompleter.future;

  @override
  UspLayoutPreferences build() {
    _loadFromPrefs();
    return const UspLayoutPreferences();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(pUspLayoutPreferences);
      if (json != null) {
        state = UspLayoutPreferences.fromJsonString(json);
      }
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
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
      await ref
          .read(uspSliverDashboardControllerProvider.notifier)
          .resetLayout();
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

  /// Select a dashboard preset and apply its layout.
  Future<void> selectPreset(UspDashboardPreset preset) async {
    state = state.withPreset(preset);
    await _saveToPrefs();
    await ref
        .read(uspSliverDashboardControllerProvider.notifier)
        .applyPreset(preset);
  }

  /// Mark the preset dialog as seen without changing the preset.
  Future<void> markPresetDialogSeen() async {
    state = state.withPresetDialogSeen();
    await _saveToPrefs();
  }

  /// Reset all preferences to defaults.
  ///
  /// Sets [useCustomLayout] to false, clears widget configs,
  /// and resets the grid layout.
  Future<void> resetToDefaults() async {
    state = const UspLayoutPreferences();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pUspLayoutPreferences);
    await ref.read(uspSliverDashboardControllerProvider.notifier).resetLayout();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pUspLayoutPreferences, state.toJsonString());
  }
}
