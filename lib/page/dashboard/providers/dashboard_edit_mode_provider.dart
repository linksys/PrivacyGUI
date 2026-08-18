import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

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

  /// The forms cards were picked into when edit mode opened (#1299).
  ///
  /// A third snapshot alongside the geometry and the prefs, because a pick is
  /// editable in edit mode too — the layout settings panel writes them — and a
  /// cancel that reverted only the geometry would leave the two disagreeing.
  /// Captured in the same assignment as [layoutSnapshot], so the two are non-null
  /// together.
  final CardForms? formsSnapshot;

  const DashboardEditState({
    this.isEditing = false,
    this.layoutSnapshot,
    this.prefsSnapshot,
    this.formsSnapshot,
  });

  DashboardEditState copyWith({
    bool? isEditing,
    List<Map<String, dynamic>>? layoutSnapshot,
    UspLayoutPreferences? prefsSnapshot,
    CardForms? formsSnapshot,
    bool clearSnapshots = false,
  }) {
    return DashboardEditState(
      isEditing: isEditing ?? this.isEditing,
      layoutSnapshot:
          clearSnapshots ? null : (layoutSnapshot ?? this.layoutSnapshot),
      prefsSnapshot:
          clearSnapshots ? null : (prefsSnapshot ?? this.prefsSnapshot),
      formsSnapshot:
          clearSnapshots ? null : (formsSnapshot ?? this.formsSnapshot),
    );
  }
}

class DashboardEditModeNotifier extends Notifier<DashboardEditState> {
  @override
  DashboardEditState build() {
    // Logging out has to leave edit mode (#1294).
    //
    // Logging out from the dashboard's own top-bar menu does not navigate
    // anywhere and does not reload the page, so the route guard in
    // route_usp_dashboard.dart never fires and this provider — root-scoped, like
    // the layout controller — survives untouched. The next session then opens on
    // a grid still showing resize handles and the trash zone, holding a layout
    // snapshot captured before the logout that a later cancel would revert into.
    //
    // What matters is the logged-in → logged-out edge, not the logged-out state
    // itself: auth also reports "logged out" before anyone has logged in, and
    // reverting on that would undo an edit the user is still making.
    //
    // The edge cannot be read off the callback's `previous`, because
    // AuthNotifier.logout emits AsyncValue.loading() before the logged-out
    // value — by the time that value lands, `previous` is a value-less loading
    // state that says nothing about who was logged in. So the last answer is
    // remembered here instead, and loading/error emissions leave it alone.
    // `fireImmediately` seeds it from whatever auth already knows, which is what
    // makes a logout still register when the dashboard was opened mid-session.
    bool wasLoggedIn = false;
    ref.listen(authProvider, (_, next) {
      final loggedIn = next.valueOrNull?.isLoggedIn;
      if (loggedIn == null) return;

      final loggedOutJustNow = wasLoggedIn && !loggedIn;
      wasLoggedIn = loggedIn;

      // `state` is only readable once build has returned. The seeding call
      // cannot reach this line: it starts from wasLoggedIn = false.
      if (loggedOutJustNow && state.isEditing) {
        cancelEditMode();
      }
    }, fireImmediately: true);

    return const DashboardEditState();
  }

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
    final formsSnapshot = ref.read(cardFormsProvider);

    state = DashboardEditState(
      isEditing: true,
      layoutSnapshot: layoutSnapshot,
      prefsSnapshot: prefsSnapshot,
      formsSnapshot: formsSnapshot,
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
        final layoutSnapshot = state.layoutSnapshot;
        final formsSnapshot = state.formsSnapshot;
        if (layoutSnapshot != null && formsSnapshot != null) {
          // One call: the picks and the geometry they justify have to be put back
          // together — see [UspSliverDashboardControllerNotifier.restoreSnapshot].
          await ref
              .read(uspSliverDashboardControllerProvider.notifier)
              .restoreSnapshot(layoutSnapshot, formsSnapshot);
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
