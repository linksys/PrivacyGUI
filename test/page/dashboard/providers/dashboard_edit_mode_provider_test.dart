import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/_shared/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/selected_card_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:shared_preferences/shared_preferences.dart';
// sliver_dashboard 2.x re-exports `state_beacon`, whose `AsyncValue` collides
// with Riverpod's — along with its three subclasses, which collide only where
// they are used. See the same list on `usp_layout_controller.dart`'s import.
import 'package:sliver_dashboard/sliver_dashboard.dart'
    hide AsyncValue, AsyncData, AsyncError, AsyncLoading;
// The grab that Space starts is not on the exported interface — the item widget
// reaches it through this extension, and an exit while one is open is what the
// #1393 group below is about.
// ignore: implementation_imports
import 'package:sliver_dashboard/src/controller/utility.dart';

Future<void> pumpAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
}

/// The desktop grid out of a persisted layout envelope (#1293 keys it by slot
/// count), so an assertion can name the grid the test acted on.
List<dynamic> _savedDesktopLayout(String raw) =>
    UspLayoutEnvelope.tryDecode(raw)![UspLayoutEnvelope.desktopSlotCount]!;

/// The geometry of [layout], one line per card, id-ordered.
///
/// The size caps are part of it, not decoration: the half of #1396 that crashes
/// is a `minW` scaled past the column count of a grid nobody was looking at
/// (`layout_engine.dart`'s `assert(currentL.minW <= cols)`), and a comparison of
/// `x,y,w,h` alone would call that grid restored.
List<String> _geometry(List<dynamic> layout) => layout
    .map((i) => '${(i as Map)['id']}: ${i['x']},${i['y']},${i['w']},${i['h']} '
        'caps ${i['minW']},${i['maxW']},${i['minH']},${i['maxH']}')
    .toList()
  ..sort();

/// Every persisted grid's [_geometry], keyed by slot count.
///
/// The per-breakpoint shape is what #1396 is about: a single grid's geometry
/// cannot tell a restore apart from a re-derivation, because on the grid the
/// user was looking at the two agree.
Map<int, List<String>> _storedGeometry(String raw) {
  final envelope = UspLayoutEnvelope.tryDecode(raw)!;
  return {
    for (final slots in UspLayoutEnvelope.persistedSlotCounts)
      slots: _geometry(envelope[slots] ?? const []),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> createContainer({
    Map<String, Object> initialValues = const {},
    List<Override> overrides = const [],
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final container = ProviderContainer(overrides: overrides);
    container.read(uspSliverDashboardControllerProvider);
    await container.read(uspLayoutPreferencesProvider.notifier).initialized;
    await pumpAsync();
    return container;
  }

  group('DashboardEditState', () {
    test('default state has isEditing=false and null snapshots', () {
      const state = DashboardEditState();
      expect(state.isEditing, isFalse);
      expect(state.layoutSnapshot, isNull);
      expect(state.prefsSnapshot, isNull);
    });

    test('copyWith updates fields correctly', () {
      const state = DashboardEditState();
      final updated = state.copyWith(
        isEditing: true,
        layoutSnapshot: {
          12: [
            {'id': 'test'}
          ]
        },
        prefsSnapshot: const UspLayoutPreferences(useCustomLayout: false),
      );

      expect(updated.isEditing, isTrue);
      expect(updated.layoutSnapshot, hasLength(1));
      expect(updated.prefsSnapshot?.useCustomLayout, isFalse);
    });

    test('copyWith with clearSnapshots clears snapshots', () {
      const state = DashboardEditState(
        isEditing: true,
        layoutSnapshot: {
          12: [
            {'id': 'test'}
          ]
        },
        prefsSnapshot: UspLayoutPreferences(),
      );
      final cleared = state.copyWith(clearSnapshots: true);

      expect(cleared.layoutSnapshot, isNull);
      expect(cleared.prefsSnapshot, isNull);
    });
  });

  group('DashboardEditModeNotifier', () {
    test('initial state is not editing', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final state = container.read(dashboardEditModeProvider);
      expect(state.isEditing, isFalse);
      expect(state.layoutSnapshot, isNull);
      expect(state.prefsSnapshot, isNull);
    });

    test('enterEditMode sets isEditing=true and captures snapshots', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      await container.read(dashboardEditModeProvider.notifier).enterEditMode();

      final state = container.read(dashboardEditModeProvider);
      expect(state.isEditing, isTrue);
      expect(state.layoutSnapshot, isNotNull);
      // One grid per breakpoint, each non-empty (#1396): a cancel has to put
      // back the two the user is not looking at, and it can only put back what
      // was captured.
      expect(state.layoutSnapshot!.keys,
          containsAll(UspLayoutEnvelope.persistedSlotCounts));
      expect(state.layoutSnapshot!.values, everyElement(isNotEmpty));
      expect(state.prefsSnapshot, isNotNull);
    });

    test('commitEditMode clears state without reverting', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      await container.read(dashboardEditModeProvider.notifier).enterEditMode();
      final snapshotBeforeExit =
          container.read(dashboardEditModeProvider).layoutSnapshot;
      expect(snapshotBeforeExit, isNotNull);

      await container.read(dashboardEditModeProvider.notifier).commitEditMode();

      final state = container.read(dashboardEditModeProvider);
      expect(state.isEditing, isFalse);
      expect(state.layoutSnapshot, isNull);
      expect(state.prefsSnapshot, isNull);
    });

    test('commitEditMode preserves layout changes applied during edit',
        () async {
      // Regression for #1089 (PeterJhong): committing must NOT revert changes
      // that were applied during edit mode (e.g. reset / preset change from the
      // settings panel). Previously the settings path called the revert branch
      // and undid the just-applied change.
      final container = await createContainer();
      addTearDown(container.dispose);

      await container.read(dashboardEditModeProvider.notifier).enterEditMode();

      final controller = container.read(uspSliverDashboardControllerProvider);
      final originalCount = controller.exportLayout().length;
      controller.removeItems(['stats_panel']);
      final afterRemove = controller.exportLayout().length;
      expect(afterRemove, lessThan(originalCount));

      await container.read(dashboardEditModeProvider.notifier).commitEditMode();

      // Change is kept, not reverted back to originalCount.
      final finalCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;
      expect(finalCount, equals(afterRemove));
    });

    test('cancelEditMode reverts layout to snapshot', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      await container.read(dashboardEditModeProvider.notifier).enterEditMode();

      final originalLayout = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;

      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.removeItems(['stats_panel']);
      final afterRemove = controller.exportLayout().length;
      expect(afterRemove, lessThan(originalLayout));

      await container.read(dashboardEditModeProvider.notifier).cancelEditMode();

      final restoredLayout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      expect(restoredLayout.length, equals(originalLayout));

      final state = container.read(dashboardEditModeProvider);
      expect(state.isEditing, isFalse);
      expect(state.layoutSnapshot, isNull);
      expect(state.prefsSnapshot, isNull);
    });

    test(
        're-entrant enterEditMode does not overwrite the original snapshot '
        '(W-1)', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dashboardEditModeProvider.notifier);
      await notifier.enterEditMode();

      final controller = container.read(uspSliverDashboardControllerProvider);
      final originalCount = controller.exportLayout().length;

      // Modify the grid, then re-enter (simulating a double-tap / gesture race).
      controller.removeItems(['stats_panel']);
      expect(controller.exportLayout().length, lessThan(originalCount));

      // Re-entrant call must be a no-op — it must NOT re-capture the modified
      // grid as the new baseline.
      await notifier.enterEditMode();

      // Cancel should restore the TRUE pre-edit baseline, not the mid-edit state.
      await notifier.cancelEditMode();
      final restoredCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;
      expect(restoredCount, equals(originalCount));
    });

    test(
        'cancel during enterEditMode async gap leaves controller not stuck '
        '(W-2)', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dashboardEditModeProvider.notifier);

      // Start entering edit mode but do NOT await — isEditing is claimed
      // synchronously before the internal await.
      final enterFuture = notifier.enterEditMode();
      expect(container.read(dashboardEditModeProvider).isEditing, isTrue);

      // A navigation-away in the async gap cancels edit mode.
      await notifier.cancelEditMode();
      expect(container.read(dashboardEditModeProvider).isEditing, isFalse);

      // enterEditMode resumes after its await; it must observe the cancel and
      // bail out instead of stranding the controller in edit mode.
      await enterFuture;
      expect(container.read(dashboardEditModeProvider).isEditing, isFalse);
    });

    // -------------------------------------------------------------------------
    // #1299 — a card form is edit-mode state too
    // -------------------------------------------------------------------------
    //
    // The toolbar's form picker writes the picks, and that row is only built while
    // editing. So exiting edit mode has to treat a pick the same way it treats a
    // drag: kept on commit, undone on cancel.
    //
    // The failure worth pinning is not "the pick came back" on its own but the
    // *pair* coming back together. Reverting the geometry while keeping the pick
    // leaves a card in its old box with no resize handles; reverting the pick
    // while keeping the geometry leaves a 2x1 tile that is resizable again.
    // Neither is reachable by any sequence of gestures, so each assertion below
    // checks the pick and the box it justifies in the same test.
    //
    // Mutation table — each row is one edit to the real source, run against this
    // file:
    //
    //   | # | mutated                     | mutation                              | killed by |
    //   |---|-----------------------------|---------------------------------------|-----------|
    //   | 1 | dashboard_edit_mode_provider| enterEditMode captures no forms snapshot | 5 |
    //   | 2 | usp_layout_controller       | restoreSnapshot restores the geometry but not the picks | 2 |
    //   | 3 | dashboard_edit_mode_provider| commitEditMode takes the revert path   | 2 |
    //   | 4 | dashboard_edit_mode_provider| _exitEditMode does not clear the selection | 2 — both exits |
    //
    // Row 1 killing 5 is the interesting count: two of them are the pre-existing
    // #1293/#1294 tests, because `_exitEditMode` only restores when *both*
    // snapshots are non-null — so dropping the forms half silently disables the
    // geometry revert as well. Rows 2 and 3 are the two halves that a single
    // "cancel works" test would have conflated: 2 fails only the pick assertions,
    // 3 fails only on commit.

    test('cancel puts back the form the card was in, and its box', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dashboardEditModeProvider.notifier);
      await notifier.enterEditMode();

      final layoutNotifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final before = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .firstWhere((e) => (e as Map)['id'] == 'device_info') as Map;
      final originalW = before['w'] as int;
      expect(originalW, greaterThan(UspWidgetSpecs.popupColumns),
          reason: 'the collapse has to be observable for the restore to be');

      await layoutNotifier.setCardForm('device_info', CardDensity.popup);
      expect(
        container.read(cardFormsProvider).densityFor(12, 'device_info'),
        CardDensity.popup,
      );

      await notifier.cancelEditMode();

      expect(
        container.read(cardFormsProvider).densityFor(12, 'device_info'),
        isNull,
        reason: 'the pick was made during the edit, so cancel drops it',
      );
      final after = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .firstWhere((e) => (e as Map)['id'] == 'device_info') as Map;
      expect(after['w'], originalW);
      expect(after['isResizable'], isNot(isFalse),
          reason: 'a card with no pick has its handles back');
    });

    test('cancel does not drop a pick that was made before the edit', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      // Picked outside edit mode — the snapshot must carry it, so that cancel
      // reverts *to* it rather than clearing everything.
      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .setCardForm('device_info', CardDensity.compact);

      final notifier = container.read(dashboardEditModeProvider.notifier);
      await notifier.enterEditMode();
      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .setCardForm('device_info', CardDensity.popup);
      await notifier.cancelEditMode();

      expect(
        container.read(cardFormsProvider).densityFor(12, 'device_info'),
        CardDensity.compact,
      );
      final item = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .firstWhere((e) => (e as Map)['id'] == 'device_info') as Map;
      expect(item['isResizable'], isNot(isFalse),
          reason: 'compact can still be enlarged, so the handles stay');
      expect(item['minW'], greaterThan(1),
          reason: "the reverted pick's floor is back on the geometry");
    });

    test('commit keeps a pick made during the edit', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dashboardEditModeProvider.notifier);
      await notifier.enterEditMode();
      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .setCardForm('device_info', CardDensity.popup);
      await notifier.commitEditMode();

      expect(
        container.read(cardFormsProvider).densityFor(12, 'device_info'),
        CardDensity.popup,
      );
      final item = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .firstWhere((e) => (e as Map)['id'] == 'device_info') as Map;
      expect(item['w'], UspWidgetSpecs.popupColumns);
      expect(item['isResizable'], isFalse);
    });

    // The selection is edit-mode state too: it is what the form picker aims at, and
    // the package keeps it across `setEditMode(false)`. Both exits are asserted
    // because they take different paths through `_exitEditMode` — only the revert
    // branch touches the snapshots, and the clear sits after it in the `finally`.
    for (final exit in ['commit', 'cancel']) {
      test('$exit leaves no card selected', () async {
        final container = await createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(dashboardEditModeProvider.notifier);
        await notifier.enterEditMode();

        final controller = container.read(uspSliverDashboardControllerProvider);
        controller.toggleSelection('device_info');
        // Beacon subscriptions flush on a microtask, so the mirror lands a turn
        // of the event loop after the selection changes.
        await pumpAsync();
        expect(container.read(selectedCardIdProvider), 'device_info');

        exit == 'commit'
            ? await notifier.commitEditMode()
            : await notifier.cancelEditMode();
        await pumpAsync();

        expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .selectedItemIds
              .value,
          isEmpty,
          reason:
              'Left behind, the next edit session opens with a card already '
              'highlighted and the picker already aimed at it — neither of '
              'which the user asked for.',
        );
        expect(container.read(selectedCardIdProvider), isNull);
      });
    }

    test('multiple enter/commit cycles work correctly', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      for (int i = 0; i < 3; i++) {
        await container
            .read(dashboardEditModeProvider.notifier)
            .enterEditMode();
        expect(container.read(dashboardEditModeProvider).isEditing, isTrue);

        await container
            .read(dashboardEditModeProvider.notifier)
            .commitEditMode();
        expect(container.read(dashboardEditModeProvider).isEditing, isFalse);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // #1393 — leaving edit mode with a keyboard grab still held
  // ---------------------------------------------------------------------------
  //
  // Every edit is stored by whoever made it: since #1393 the grid reports its own
  // drops through the controller's `onLayoutChanged` hook (covered in
  // usp_layout_controller_test.dart), and the toolbar's actions store their result
  // themselves. So exiting edit mode writes nothing — with one case left to
  // decide, and it is the reason this group exists.
  //
  // The a11y reorder is a mode rather than a gesture: Space grabs a card, the
  // arrows move it, Space drops it. Unlike a pointer drag it can therefore still
  // be open when "Done" or "Cancel" is clicked with the mouse, and the layout it
  // is holding is uncompacted — not a layout the load path would reproduce. The
  // exit ends the interaction instead of storing it, which is what Escape does
  // mid-grab.
  group('exit with an interaction still in flight (#1393)', () {
    /// Grabs [cardId] with the keyboard and steps it one column right, the way
    /// Space-then-arrow does, and leaves the grab open.
    void grabAndMove(DashboardController controller, String cardId) {
      controller.clearSelection();
      controller.toggleSelection(cardId);
      controller.internal.onDragStart(cardId);
      controller.moveActiveItemBy(1, 0);
    }

    test('commit abandons the held move and stores nothing', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      final notifier = container.read(dashboardEditModeProvider.notifier);
      await notifier.enterEditMode();

      final controller = container.read(uspSliverDashboardControllerProvider);
      final beforeGrab = _geometry(controller.exportLayout());
      final baseline = prefs.getString(pUspSliverDashboardLayout);
      expect(baseline, isNotNull,
          reason: 'the seed writes a baseline layout on first init');

      grabAndMove(controller, 'device_info');
      expect(_geometry(controller.exportLayout()), isNot(beforeGrab),
          reason: 'the grab is in flight and has moved the card');

      await notifier.commitEditMode();
      await pumpAsync();

      expect(controller.isDragging.value, isFalse,
          reason: 'a grab must not outlive the edit session it was made in');
      expect(_geometry(controller.exportLayout()), beforeGrab,
          reason: 'the card goes back where the grab started, as it would on '
              'Escape — the move was never dropped');
      expect(prefs.getString(pUspSliverDashboardLayout), baseline,
          reason: 'nothing was dropped, so there is nothing to store. Writing '
              'the held layout instead would store an uncompacted grid, and the '
              'cards would settle somewhere else on the next reload.');
    });

    test('cancel reverts to the entry snapshot, not to the moment of the grab',
        () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      final notifier = container.read(dashboardEditModeProvider.notifier);
      await notifier.enterEditMode();

      final controller = container.read(uspSliverDashboardControllerProvider);
      final onEntry = _geometry(controller.exportLayout());

      // A first reorder, dropped: stored as it happens (#1393).
      grabAndMove(controller, 'device_info');
      controller.internal.onDragEnd('device_info');
      await pumpAsync();
      final afterFirstMove = _geometry(controller.exportLayout());
      expect(afterFirstMove, isNot(onEntry),
          reason: 'the dropped move changed the grid');

      // A second reorder, still held when Cancel is clicked.
      grabAndMove(controller, 'device_info');

      await notifier.cancelEditMode();
      await pumpAsync();

      expect(controller.isDragging.value, isFalse,
          reason: 'the grab is ended on the instance it was made on');

      // Re-read: restoring a snapshot can restore a card the session deleted,
      // which is a membership change, and those arrive as a new controller.
      final live = container.read(uspSliverDashboardControllerProvider);
      expect(_geometry(live.exportLayout()), onEntry,
          reason: 'cancel reverts the whole session. Ending the interaction '
              'after the snapshot is imported rather than before it would put '
              'the grid back to the first move instead.');
      expect(
        _geometry(
            _savedDesktopLayout(prefs.getString(pUspSliverDashboardLayout)!)),
        onEntry,
        reason: 'and the revert is stored, so the reload agrees with the grid',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // #1393 — cancelling a delete has to put the card back on every grid
  // ---------------------------------------------------------------------------
  //
  // The trash zone does not go through the notifier: the package's overlay calls
  // `removeItems` on the controller itself and the view only persists the result.
  // So a delete leaves the live layout without the card while the pref is written
  // by the walk that visits every breakpoint — and a cancel then has to put the
  // card back on all of them at the geometry each one had.
  //
  // Left to the package, that walk puts the card back at the width it has on the
  // grid the cancel restored: `placeNewItems` places an item the target grid's
  // cache does not hold without ever narrowing it, so `stats_panel`'s `w: 12`
  // lands in the 8- and 4-column grids as-is. The per-breakpoint comparison at
  // the end of the test is what catches that — against the geometry stored before
  // the session, card by card, since #1396 (AC3). It used to ask only for a width
  // each grid could hold, which a scaled-down card satisfies while still being
  // the wrong card.
  //
  // Under `sliver_dashboard` 0.9.1 the same walk *hung* instead — the wrap branch
  // skipped its own safety counter — so without the fix in `restoreSnapshot` this
  // test used to spin and take the rest of the file's run with it. 2.3.0 fixed
  // the termination and #1395 brought that fix in; the walk is still only safe in
  // the delete direction.
  group('cancel after a delete (#1393)', () {
    bool holds(List<dynamic> layout, String id) =>
        layout.any((item) => (item as Map)['id'] == id);

    test('the deleted card comes back on every breakpoint', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      final notifier = container.read(dashboardEditModeProvider.notifier);
      final onEntry =
          _storedGeometry(prefs.getString(pUspSliverDashboardLayout)!);
      await notifier.enterEditMode();

      // What the trash zone does: the overlay removes the item, the hook stores
      // the result.
      container
          .read(uspSliverDashboardControllerProvider)
          .removeItems(['stats_panel']);
      await pumpAsync();
      expect(
        holds(_savedDesktopLayout(prefs.getString(pUspSliverDashboardLayout)!),
            'stats_panel'),
        isFalse,
        reason: 'the delete reached the pref on its own (#1393)',
      );

      await notifier.cancelEditMode();
      await pumpAsync();

      final live = container.read(uspSliverDashboardControllerProvider);
      expect(holds(live.exportLayout(), 'stats_panel'), isTrue,
          reason: 'the card the session deleted is back on the grid');

      final envelope = UspLayoutEnvelope.tryDecode(
          prefs.getString(pUspSliverDashboardLayout)!)!;
      for (final slots in UspLayoutEnvelope.persistedSlotCounts) {
        final layout = envelope[slots];
        expect(layout, isNotNull, reason: 'every grid is still written out');
        expect(holds(layout!, 'stats_panel'), isTrue,
            reason: 'membership is global, so the revert restores the card on '
                'the $slots-column grid too');
        expect(_geometry(layout), onEntry[slots],
            reason: 'and it comes back at the geometry it had on that grid '
                'before the session — not at a width derived from the grid the '
                'delete happened on (#1396)');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // #1396 — a delete on a narrow grid must not rewrite the wide ones
  // ---------------------------------------------------------------------------
  //
  // `restoreSnapshot` used to be handed only the grid the user was looking at and
  // rebuild the other two by scaling it, so the direction the session was entered
  // from decides what gets rewritten. The group above enters at the desktop
  // breakpoint — with the loose "a width that grid can hold" assertion it let all
  // of it past, which is why AC3 makes that assertion exact; scaling 12 down does
  // land somewhere legal.
  //
  // These two enter from the narrow side, where the same scale runs *upwards* and
  // has no legal ceiling to land under. A phone card is pinned to `x: 0, w: 4` by
  // `lockToFullWidth`, so every card on that grid scales to a full-width desktop
  // card — and `minW: 4` scales to `minW: 12`, which no narrower grid can hold at
  // all.
  //
  // Both tests compare *stored* geometry rather than the live grid, because the
  // grids the ticket is about are the ones nobody is rendering. The pref is where
  // they exist.
  //
  // Mutation table — each row is one edit to the real source, run against this
  // file:
  //
  //   | # | mutated | mutation | killed by |
  //   |---|---------|----------|-----------|
  //   | 1 | usp_layout_controller | `restoreSnapshot` back to the pre-#1396 body: keep the live grid from the snapshot, rebuild the other two with `alignMembership` | 3 — both tests here, and the desktop delete above on its new exact assertion |
  //   | 2 | dashboard_edit_mode_provider | `enterEditMode` captures `controller.exportLayout()` again, i.e. the live grid only, wrapped in a one-entry map | 13 — every test in this file that cancels, plus the `enterEditMode` shape test |
  //   | 3 | usp_layout_controller | `restoreSnapshot` restores the picks *after* the swap instead of before | 2 — `cancel puts back the form the card was in, and its box` and `cancel does not drop a pick that was made before the edit` |
  //
  // Row 2's count is the assert in `restoreSnapshot` doing its job: with asserts
  // on — every test run — a snapshot that does not cover all three breakpoints
  // fails loudly on the first cancel rather than subtly in the two tests here.
  // That is the only guard, and deliberately: in release an incomplete snapshot
  // falls back to deriving the grids it is missing, which is the behaviour this
  // ticket replaced, so a fallback would be a branch no test can reach.
  //
  // Row 1 is worth reading rather than counting. The phone test dies on an
  // *assertion inside the package* — `alignMembership` scales `minW: 4` up to
  // `minW: 12`, which `layout_engine.dart` refuses at 8 columns — so on a phone
  // the defect is a crash, not a bad number. The tablet test dies on the number:
  // `device_info` comes back at `x: 2` (its tablet `x: 1`, scaled) instead of the
  // `x: 0` it has on the desktop grid.
  //
  // Row 1 does *not* kill the tablet test without the earlier session that moves
  // a card — see the comment in that test. That is the whole reason the move is
  // there, and why "same for a delete at the tablet breakpoint" is not simply the
  // phone test with a different number in it.
  //
  // Row 3 is the reason the two lines of `restoreSnapshot` are in the order they
  // are: the grids go in through `_seedBreakpoints`, which normalises each one
  // against the picks, so picks restored second would be applied to a grid already
  // normalised against the session's. Both kills are #1299 tests — this row only
  // records that they cover the ordering too.
  group('cancel after a delete on a narrow grid (#1396)', () {
    /// Enters edit mode on the [slots]-column grid, deletes [cardId] the way the
    /// trash zone does, cancels, and returns the stored geometry before and
    /// after the session.
    Future<({Map<int, List<String>> onEntry, Map<int, List<String>> after})>
        deleteAndCancelAt(
      ProviderContainer container,
      int slots,
      String cardId,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = container.read(dashboardEditModeProvider.notifier);

      // The view drives this off the viewport width. It persists nothing —
      // `setSlotCount` does not fire the layout hook — so the pref still holds
      // what the last real save put there, which is the pre-edit truth.
      container.read(uspSliverDashboardControllerProvider).setSlotCount(slots);
      await pumpAsync();
      final onEntry =
          _storedGeometry(prefs.getString(pUspSliverDashboardLayout)!);
      // A premise, because [_storedGeometry] reads an absent grid as an empty
      // list and two empty lists compare equal: every assertion below would pass
      // on a pref that stored no grids at all.
      expect(onEntry.values, everyElement(isNotEmpty),
          reason: 'the seed stores every breakpoint before the session starts');

      await notifier.enterEditMode();
      container
          .read(uspSliverDashboardControllerProvider)
          .removeItems([cardId]);
      await pumpAsync();

      await notifier.cancelEditMode();
      await pumpAsync();

      return (
        onEntry: onEntry,
        after: _storedGeometry(prefs.getString(pUspSliverDashboardLayout)!),
      );
    }

    test('a delete on the phone grid leaves the other two byte-for-byte',
        () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      // `device_info` is `w: 6` of 12 — a card whose desktop geometry is not
      // already full width, so scaling 4 → 12 is distinguishable from a
      // restore. `stats_panel` is `w: 12` and would hide the defect.
      final geometry = await deleteAndCancelAt(
          container, UspLayoutEnvelope.mobileSlotCount, 'device_info');

      expect(geometry.after[UspLayoutEnvelope.desktopSlotCount],
          geometry.onEntry[UspLayoutEnvelope.desktopSlotCount],
          reason: 'the user never looked at the desktop grid this session, so '
              'cancel owes them the grid they left');
      expect(geometry.after[UspLayoutEnvelope.tabletSlotCount],
          geometry.onEntry[UspLayoutEnvelope.tabletSlotCount],
          reason: 'and the same for the tablet grid');
      expect(geometry.after[UspLayoutEnvelope.mobileSlotCount],
          geometry.onEntry[UspLayoutEnvelope.mobileSlotCount],
          reason: 'the grid the delete happened on reverts too — that half '
              'already worked, and it is what makes the other two a fair '
              'comparison rather than a stale read');
    });

    test('a delete on the tablet grid leaves the desktop one byte-for-byte',
        () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dashboardEditModeProvider.notifier);
      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(UspLayoutEnvelope.tabletSlotCount);
      await pumpAsync();

      // An earlier session, in which the user arranged their tablet grid.
      //
      // Without it this test proves nothing: the seeded tablet grid is derived
      // from the desktop one by the very scale the defect applies, so scaling it
      // back up reproduces the stored desktop layout exactly and the ticket's
      // "usually the same numbers" row passes either way. One dropped move is
      // enough to make the two grids hold coordinates neither can be computed
      // from — which is the state every user who has ever touched a second
      // breakpoint is in.
      await notifier.enterEditMode();
      controller.clearSelection();
      controller.toggleSelection('device_info');
      controller.internal.onDragStart('device_info');
      controller.moveActiveItemBy(1, 0);
      controller.internal.onDragEnd('device_info');
      await notifier.commitEditMode();
      await pumpAsync();

      final geometry = await deleteAndCancelAt(
          container, UspLayoutEnvelope.tabletSlotCount, 'device_info');

      expect(geometry.after[UspLayoutEnvelope.desktopSlotCount],
          geometry.onEntry[UspLayoutEnvelope.desktopSlotCount],
          reason: 'a restore is a restore at every breakpoint, not only at the '
              'ones where scaling happens to disagree');
      expect(geometry.after[UspLayoutEnvelope.mobileSlotCount],
          geometry.onEntry[UspLayoutEnvelope.mobileSlotCount],
          reason: 'and scaling 8 → 4 is the direction that loses the most');
    });
  });

  // ---------------------------------------------------------------------------
  // #1294 — logging out must leave edit mode
  // ---------------------------------------------------------------------------
  group('logout leaves edit mode', () {
    /// A logged-in [AuthNotifier] whose logout can be driven without the USP /
    /// SSE / credential-store machinery the real one needs.
    ///
    /// It reproduces the exact emission sequence of [AuthNotifier.logout]:
    /// `AsyncValue.loading()` first, then `AsyncValue.data(AuthState.empty())`.
    /// That middle `loading` is why a listener cannot compare
    /// `previous.isLoggedIn` with `next.isLoggedIn` — by the time the logged-out
    /// data arrives, `previous` is a value-less loading state.
    ///
    /// Both providers are read before the test acts: in production the dashboard
    /// is on screen (so the edit-mode notifier is alive and listening) and auth
    /// has resolved (so the fake has an element to push state through).
    Future<ProviderContainer> containerWithAuth(_FakeAuthNotifier auth) async {
      final container = await createContainer(
        overrides: [authProvider.overrideWith(() => auth)],
      );
      await container.read(authProvider.future);
      container.read(dashboardEditModeProvider);
      return container;
    }

    test('a logout while editing exits edit mode', () async {
      // The reported bug: log out from the dashboard's own top-bar menu (which
      // does not navigate anywhere), log back in, and the grid is still in edit
      // mode with the trash zone and resize handles showing — because both the
      // edit-mode provider and the controller are root-scoped and survive a
      // logout that never reloads the page.
      final auth = _FakeAuthNotifier();
      final container = await containerWithAuth(auth);
      addTearDown(container.dispose);

      await container.read(dashboardEditModeProvider.notifier).enterEditMode();
      expect(container.read(dashboardEditModeProvider).isEditing, isTrue);

      auth.logOut();
      await pumpAsync();

      final state = container.read(dashboardEditModeProvider);
      expect(state.isEditing, isFalse);
      expect(state.layoutSnapshot, isNull,
          reason: 'A stale snapshot would be reverted into the next session.');
      expect(
          container.read(uspSliverDashboardControllerProvider).isEditing.value,
          isFalse,
          reason: 'The grid itself must also drop out of edit mode — the '
              'handles and trash zone are driven by the controller, not by '
              'this provider.');
    });

    test('the pre-edit layout is restored, matching the tab-switch policy',
        () async {
      // #1037 chose silent discard for leaving the dashboard mid-edit. A logout
      // is a harder exit than a tab switch, so it reverts the same way rather
      // than committing half-finished dragging.
      final auth = _FakeAuthNotifier();
      final container = await containerWithAuth(auth);
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final originalCount = controller.exportLayout().length;
      await container.read(dashboardEditModeProvider.notifier).enterEditMode();
      controller.removeItems(['stats_panel']);
      expect(controller.exportLayout().length, lessThan(originalCount));

      auth.logOut();
      await pumpAsync();

      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          originalCount);
    });

    test('a logout while not editing changes nothing', () async {
      final auth = _FakeAuthNotifier();
      final container = await containerWithAuth(auth);
      addTearDown(container.dispose);

      final before =
          container.read(uspSliverDashboardControllerProvider).exportLayout();

      auth.logOut();
      await pumpAsync();

      expect(container.read(dashboardEditModeProvider).isEditing, isFalse);
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          before.length,
          reason: 'The reset must be idempotent: it fires on every logout, '
              'including the ones that happen with the dashboard closed.');
    });

    test('logging back in does not re-enter edit mode', () async {
      final auth = _FakeAuthNotifier();
      final container = await containerWithAuth(auth);
      addTearDown(container.dispose);

      await container.read(dashboardEditModeProvider.notifier).enterEditMode();
      auth.logOut();
      await pumpAsync();
      auth.logIn();
      await pumpAsync();

      expect(container.read(dashboardEditModeProvider).isEditing, isFalse);
    });
  });
}

/// Drives [authProvider] through login/logout without the real dependencies.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const AuthState(loginType: LoginType.local);

  void logOut() {
    state = const AsyncValue.loading();
    state = AsyncValue.data(AuthState.empty());
  }

  void logIn() {
    state = const AsyncValue.data(AuthState(loginType: LoginType.local));
  }
}
