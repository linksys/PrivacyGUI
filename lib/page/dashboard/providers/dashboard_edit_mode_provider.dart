import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';

/// Manages dashboard edit mode state and layout snapshots for revert on cancel.
///
/// This provider centralizes edit mode state so it can be accessed from route
/// guards (onExit) to handle navigation away during edit mode.
final dashboardEditModeProvider =
    NotifierProvider<DashboardEditModeNotifier, DashboardEditState>(
  DashboardEditModeNotifier.new,
);

class DashboardEditState {
  final bool isEditing;
  final List<Map<String, dynamic>>? layoutSnapshot;
  final UspLayoutPreferences? prefsSnapshot;

  const DashboardEditState({
    this.isEditing = false,
    this.layoutSnapshot,
    this.prefsSnapshot,
  });

  DashboardEditState copyWith({
    bool? isEditing,
    List<Map<String, dynamic>>? layoutSnapshot,
    UspLayoutPreferences? prefsSnapshot,
    bool clearSnapshots = false,
  }) {
    return DashboardEditState(
      isEditing: isEditing ?? this.isEditing,
      layoutSnapshot:
          clearSnapshots ? null : (layoutSnapshot ?? this.layoutSnapshot),
      prefsSnapshot:
          clearSnapshots ? null : (prefsSnapshot ?? this.prefsSnapshot),
    );
  }
}

class DashboardEditModeNotifier extends Notifier<DashboardEditState> {
  @override
  DashboardEditState build() => const DashboardEditState();

  /// Enter edit mode and capture snapshots for potential revert.
  Future<void> enterEditMode() async {
    // Re-entrant guard: a double-tap or gesture race must not re-capture the
    // already-modified grid as the "original" snapshot.
    if (state.isEditing) return;

    // Claim the edit slot BEFORE the await so a route guard (onExit) firing in
    // the async gap always observes isEditing=true and reverts correctly.
    state = const DashboardEditState(isEditing: true);

    await ref.read(uspLayoutPreferencesProvider.notifier).initialized;

    // If we were cancelled during the await (e.g. navigation away), bail out
    // instead of resuming and stranding the controller in edit mode.
    if (!state.isEditing) return;

    final controller = ref.read(uspSliverDashboardControllerProvider);
    final layoutSnapshot = controller.exportLayout();
    final prefsSnapshot = ref.read(uspLayoutPreferencesProvider);

    state = DashboardEditState(
      isEditing: true,
      layoutSnapshot: layoutSnapshot,
      prefsSnapshot: prefsSnapshot,
    );

    controller.setEditMode(true);
  }

  /// Exit edit mode, keeping the current layout (changes are already persisted
  /// on each drag/resize, so committing is just clearing the edit flag).
  Future<void> commitEditMode() => _exitEditMode(revert: false);

  /// Exit edit mode and revert the layout/prefs to the pre-edit snapshots
  /// captured in [enterEditMode].
  Future<void> cancelEditMode() => _exitEditMode(revert: true);

  /// Shared exit path for [commitEditMode] / [cancelEditMode].
  ///
  /// The edit flag and snapshots are always cleared in the `finally` block so
  /// that a failure in [DashboardController.saveLayout] /
  /// [UspLayoutPreferencesNotifier.restoreSnapshot] can never leave the
  /// dashboard stuck in edit mode with stale state.
  Future<void> _exitEditMode({required bool revert}) async {
    final controller = ref.read(uspSliverDashboardControllerProvider);

    try {
      if (revert) {
        if (state.layoutSnapshot != null) {
          controller.importLayout(state.layoutSnapshot!);
          await ref
              .read(uspSliverDashboardControllerProvider.notifier)
              .saveLayout();
        }
        if (state.prefsSnapshot != null) {
          await ref
              .read(uspLayoutPreferencesProvider.notifier)
              .restoreSnapshot(state.prefsSnapshot!);
        }
      }
    } finally {
      controller.setEditMode(false);
      state = const DashboardEditState();
    }
  }
}
