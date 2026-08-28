import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/_shared/providers/card_forms_provider.dart';
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

/// Whether edit mode is open, and what to put back if it is cancelled.
///
/// Value equality rather than identity (Article XI §11.1), and here it earns its
/// keep twice over. `_exitEditMode` always ends on `const DashboardEditState()`,
/// so a second exit — a route guard and a button press racing, or a logout
/// arriving after a commit — republishes a state identical to the one already
/// held; on identity that is a rebuild of every listener for no change. And
/// [layoutSnapshot] is a map of lists freshly built on every capture, which no
/// two calls could ever share an identity for. [Equatable] compares it deeply.
class DashboardEditState extends Equatable {
  final bool isEditing;

  /// The geometry of every breakpoint when edit mode opened, keyed by slot count.
  ///
  /// All of them, not just the one on screen (#1396): a cancel has to put back
  /// the grids the user never opened, and those cannot be re-derived from the one
  /// they were looking at — scaling a phone grid up to 12 columns invents
  /// coordinates that were never theirs. See
  /// [UspSliverDashboardControllerNotifier.restoreSnapshot].
  final Map<int, List<dynamic>>? layoutSnapshot;
  final UspLayoutPreferences? prefsSnapshot;

  /// The forms cards were picked into when edit mode opened (#1299).
  ///
  /// A third snapshot alongside the geometry and the prefs, because a pick is
  /// editable in edit mode too — the toolbar's form picker writes them — and a
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
    Map<int, List<dynamic>>? layoutSnapshot,
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

  @override
  List<Object?> get props =>
      [isEditing, layoutSnapshot, prefsSnapshot, formsSnapshot];
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

    // Every breakpoint, not the live one (#1396). The walk visits each grid and
    // returns to the one on screen, so the page does not move under the user.
    final layoutSnapshot = ref
        .read(uspSliverDashboardControllerProvider.notifier)
        .exportAllBreakpoints();
    final prefsSnapshot = ref.read(uspLayoutPreferencesProvider);
    final formsSnapshot = ref.read(cardFormsProvider);

    state = DashboardEditState(
      isEditing: true,
      layoutSnapshot: layoutSnapshot,
      prefsSnapshot: prefsSnapshot,
      formsSnapshot: formsSnapshot,
    );

    // Read here rather than held from before the walk above: edit mode is a flag
    // on the instance, and the one rule this file has about instances is that a
    // stale one puts the flag on a controller nobody renders — see the `finally`
    // in [_exitEditMode]. Nothing swaps between these two lines today; not keeping
    // a reference is what makes that a non-question rather than an invariant.
    ref.read(uspSliverDashboardControllerProvider).setEditMode(true);
  }

  /// Exit edit mode, keeping the current layout.
  ///
  /// Writes nothing, and that is the point: every edit is stored by whoever made
  /// it — the grid reports drags, drops, resizes and deletes through the
  /// controller's `onLayoutChanged` hook (#1393), and the toolbar's own actions
  /// store their result themselves. Saving again here would only re-write what is
  /// already in the pref, and on the one path where the two disagree — a keyboard
  /// grab still held — the in-memory layout is the one that should lose.
  Future<void> commitEditMode() => _exitEditMode(revert: false);

  /// Exit edit mode and revert the layout/prefs to the pre-edit snapshots
  /// captured in [enterEditMode].
  Future<void> cancelEditMode() => _exitEditMode(revert: true);

  /// Shared exit path for [commitEditMode] / [cancelEditMode].
  ///
  /// Both paths end an interaction that is still in flight before anything else.
  /// The keyboard (a11y) reorder is a mode rather than a gesture — Space grabs a
  /// card, the arrows move it, Space drops it — so unlike a pointer drag it can
  /// still be open when "Done" or "Cancel" is clicked with the mouse. Left open it
  /// would strand `isDragging` on a controller that is no longer in edit mode, and
  /// leave the grid holding the uncompacted layout the arrows produced.
  /// [DashboardController.cancelInteraction] puts the card back where the grab
  /// started, which is the same thing Escape does mid-grab.
  ///
  /// It has to run before the revert below rather than alongside the cleanup in
  /// the `finally`: the layout it restores is the one from the moment of the grab,
  /// so afterwards it would overwrite the snapshot that was just imported.
  ///
  /// The edit flag and snapshots are always cleared in the `finally` block so
  /// that a failure in [UspSliverDashboardControllerNotifier.restoreSnapshot] /
  /// [UspLayoutPreferencesNotifier.restoreSnapshot] can never leave the
  /// dashboard stuck in edit mode with stale state. The cancellation is inside the
  /// `try` for the same reason — first, but not ahead of the guarantee.
  ///
  /// That block re-reads the controller rather than reusing the one the
  /// interaction was cancelled on: a revert that restores a deleted card swaps the
  /// instance, and clearing edit mode on the instance we started with would take
  /// the handles off a controller nobody is rendering while the live one kept
  /// them.
  Future<void> _exitEditMode({required bool revert}) async {
    try {
      ref.read(uspSliverDashboardControllerProvider).cancelInteraction();

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
      final controller = ref.read(uspSliverDashboardControllerProvider);
      controller.setEditMode(false);
      // A selection is edit-mode state too (#1299). The package keeps it across
      // `setEditMode(false)`, and both things that read it are edit-mode only:
      // the item's selection border, and the toolbar's form picker. Left behind,
      // the next edit session opens with a card already highlighted and the
      // picker already aimed at it, which the user never asked for.
      controller.clearSelection();
      state = const DashboardEditState();
    }
  }
}
