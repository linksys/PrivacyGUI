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
  final List<dynamic>? layoutSnapshot;
  final UspLayoutPreferences? prefsSnapshot;

  const DashboardEditState({
    this.isEditing = false,
    this.layoutSnapshot,
    this.prefsSnapshot,
  });

  DashboardEditState copyWith({
    bool? isEditing,
    List<dynamic>? layoutSnapshot,
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
    await ref.read(uspLayoutPreferencesProvider.notifier).initialized;

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

  /// Exit edit mode and optionally save or revert changes.
  Future<void> exitEditMode({bool save = true}) async {
    final controller = ref.read(uspSliverDashboardControllerProvider);

    if (!save) {
      // Revert to snapshots
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

    controller.setEditMode(false);
    state = const DashboardEditState();
  }

  /// Cancel edit mode (revert changes) - convenience method.
  Future<void> cancelEditMode() => exitEditMode(save: false);
}
