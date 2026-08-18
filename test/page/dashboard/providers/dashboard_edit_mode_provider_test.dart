import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
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
