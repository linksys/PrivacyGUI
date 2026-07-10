import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> createContainer({
    Map<String, Object> initialValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final container = ProviderContainer();
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
}
