import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
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
        layoutSnapshot: [
          {'id': 'test'}
        ],
        prefsSnapshot: const UspLayoutPreferences(useCustomLayout: false),
      );

      expect(updated.isEditing, isTrue);
      expect(updated.layoutSnapshot, hasLength(1));
      expect(updated.prefsSnapshot?.useCustomLayout, isFalse);
    });

    test('copyWith with clearSnapshots clears snapshots', () {
      final state = DashboardEditState(
        isEditing: true,
        layoutSnapshot: [
          {'id': 'test'}
        ],
        prefsSnapshot: const UspLayoutPreferences(),
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
      expect(state.layoutSnapshot, isNotEmpty);
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
    // The layout settings panel writes the picks, and that panel only opens from
    // a button that only exists while editing. So exiting edit mode has to treat
    // a pick the same way it treats a drag: kept on commit, undone on cancel.
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
