import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
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

  /// Whether this surface's layout was chosen for the viewer, set in [build].
  ///
  /// Named to match `UspLayoutController._layoutIsFixed`, because the two are one
  /// decision and grepping the pair is how the next reader finds that out. Same
  /// asymmetry, too: the read side is the `if` in [build], and this is the write
  /// side, which needs a *funnel* rather than a flag at the entry points —
  /// [toggleCustomLayout], [setVisibility], [restoreSnapshot], [selectPreset] and
  /// [markPresetDialogSeen] all reach storage through [_saveToPrefs], and
  /// [resetToDefaults] reaches it directly.
  bool _layoutIsFixed = false;

  /// Completes when the initial load from SharedPreferences is done.
  /// Await this before capturing snapshots to avoid race conditions
  /// where the default state (preset = null) is captured before the
  /// persisted state is loaded.
  Future<void> get initialized => _initCompleter.future;

  /// A surface whose layout is fixed has no preferences to load, so the defaults
  /// stand and [initialized] completes without ever touching the store — see
  /// `SurfaceStrategy.fixedDashboardLayout`, which answers the same question for
  /// the grid itself.
  ///
  /// Not "the remote preset is selected": until #1497 this returned
  /// `UspLayoutPreferences(selectedPreset: UspDashboardPreset.remote)`, which
  /// recorded a pick nobody made. The one thing that reads [selectedPreset] is the
  /// edit-mode-only settings panel, and a surface with a fixed layout has no edit
  /// mode to open it from.
  ///
  /// `watch`, not `read`. Nothing rebuilds in production — `appModeProvider` has no
  /// dependencies and is computed once per container — so the two are equivalent
  /// today and `watch` is the one that stays correct if that changes. It is also
  /// what makes the completer guard below honest: `read` forecloses a second
  /// `build()` on this instance, so a guard against double-completion would be
  /// documenting a situation its own dependency edge prevented.
  @override
  UspLayoutPreferences build() {
    _layoutIsFixed =
        ref.watch(surfaceStrategyProvider).fixedDashboardLayout() != null;
    if (_layoutIsFixed) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      return const UspLayoutPreferences();
    }

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
    if (_layoutIsFixed) return;
    state = const UspLayoutPreferences();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pUspLayoutPreferences);
    await ref.read(uspSliverDashboardControllerProvider.notifier).resetLayout();
  }

  /// The write funnel, and the only place the fixed-surface guard is needed for
  /// the five mutators above — see [_layoutIsFixed].
  ///
  /// Storage in both directions, not in-memory state: a mutator called on a fixed
  /// surface still updates [state], because what the guard is for is the *next*
  /// session in this browser, not this one. Under Remote Assistance every entry
  /// point to all six is behind an edit mode `layoutEditor()` closes, so the
  /// in-memory half has no way to be observed; the stored half would outlive the
  /// session and be read by the next one.
  Future<void> _saveToPrefs() async {
    if (_layoutIsFixed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pUspLayoutPreferences, state.toJsonString());
  }
}
