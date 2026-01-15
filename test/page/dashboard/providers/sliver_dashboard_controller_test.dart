import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

// Import internal dependencies - Assuming path correctness based on file structure
import 'package:privacy_gui/page/dashboard/models/dashboard_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/height_strategy.dart';
import 'package:privacy_gui/page/dashboard/models/widget_grid_constraints.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/providers/sliver_dashboard_controller_provider.dart';

// Mocks
class MockRef extends Mock implements Ref {}
// We don't need to mock DashboardController because it's the state being managed.
// But we might need to mock DashboardHomeState for provider reading.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Fake DashboardHomeState
  final fakeDashboardState =
      DashboardHomeState(lanPortConnections: [], isHorizontalLayout: true);

  group('SliverDashboardController Integration', () {
    late MockRef mockRef;

    setUp(() {
      SharedPreferences.setMockInitialValues({}); // Reset prefs
      mockRef = MockRef();

      // Stub ref.read calls for dashboardHomeProvider
      // Note: StateNotifierProvider.read is deprecated in favor of ref.read(provider)
      // The controller implementation uses: _ref.read(dashboardHomeProvider)
      when(() => mockRef.read(dashboardHomeProvider))
          .thenReturn(fakeDashboardState);

      // Stub ref.read for other internal calls if any?
      // Looking at source: only dashboardHomeProvider is read.
    });

    test('Initializes with default layout when no saved data', () async {
      // Create controller
      final notifier = SliverDashboardControllerNotifier(mockRef);
      // Wait for async init (it's called in constructor but async work happens)
      // _initializeLayout is async but called in constructor without await.
      // We must wait for microtasks.
      await Future.delayed(Duration.zero);

      final state = notifier.debugState; // debugState acts as 'state' in tests

      expect(state.exportLayout(), isNotEmpty);
      // Verify default layout content (e.g. InternetStatus is present)
      final hasInternet = state
          .exportLayout()
          .any((i) => (i as Map)['id'] == 'internet_status_only');
      expect(hasInternet, isTrue);
    });

    test('Initializes with saved layout from SharedPreferences', () async {
      // Pre-populate prefs
      final savedLayout = [
        {
          'id': 'custom_w',
          'x': 0,
          'y': 0,
          'w': 4,
          'h': 2,
          'minW': 1,
          'maxW': 12,
          'minH': 1,
          'maxH': 12
        }
      ];
      SharedPreferences.setMockInitialValues(
          {'sliver_dashboard_layout': jsonEncode(savedLayout)});

      final notifier = SliverDashboardControllerNotifier(mockRef);
      await Future.delayed(Duration.zero);

      final state = notifier.debugState;
      final layout = state.exportLayout();

      expect(layout.length, 1);
      expect((layout.first as Map)['id'], 'custom_w');
    });

    test('addWidget appends item and saves to storage', () async {
      final notifier = SliverDashboardControllerNotifier(mockRef);
      await Future.delayed(Duration.zero);

      final initialCount = notifier.debugState.exportLayout().length;

      // Add a widget that definitely isn't in default layout?
      // Default layout uses almost all widgets.
      // Let's remove one first, then add it back.
      await notifier.removeWidget('internet_status_only');
      final afterRemoveCount = notifier.debugState.exportLayout().length;
      expect(afterRemoveCount, initialCount - 1);

      // Verify remove saved to prefs
      final prefs = await SharedPreferences.getInstance();
      var savedJson = prefs.getString('sliver_dashboard_layout');
      expect(savedJson, isNotNull);
      expect(savedJson, isNot(contains('internet_status_only')));

      // Add back
      await notifier.addWidget('internet_status_only');

      final finalLayout = notifier.debugState.exportLayout();
      expect(finalLayout.length, initialCount);

      // Verify persistence
      savedJson = prefs.getString('sliver_dashboard_layout');
      expect(savedJson, contains('internet_status_only'));
    });

    test('updateItemConstraints modifies constraints and clamps width',
        () async {
      final notifier = SliverDashboardControllerNotifier(mockRef);
      await Future.delayed(Duration.zero);

      // Find internet status (usually w=4)
      // Let's update its mode to Expanded (suppose expanded has minW=8)
      // Need a real spec. 'internet_status_only' normal is min 2, max 12.
      // Let's create a custom constraint override for testing.

      // Override: minW 8. Current W 4. Should clamp to 8.
      await notifier.updateItemConstraints('internet_status_only',
          DisplayMode.normal, // Mode irrelevant if overriding
          overrideConstraints: const WidgetGridConstraints(
              minColumns: 8,
              maxColumns: 12,
              preferredColumns: 8,
              heightStrategy: HeightStrategy.intrinsic()));

      final layout = notifier.debugState.exportLayout();
      final item = layout
          .firstWhere((i) => (i as Map)['id'] == 'internet_status_only') as Map;

      expect(item['minW'], 8);
      expect(item['w'], 8, reason: "Should have clamped width 4 up to minW 8");

      // Check persistence
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('sliver_dashboard_layout');
      expect(savedJson, contains('"w":8')); // Should verify encoded value
    });

    test('resetLayout restores defaults and clears storage', () async {
      // 1. Create and Modify
      final notifier = SliverDashboardControllerNotifier(mockRef);
      await Future.delayed(Duration.zero);
      await notifier.removeWidget('internet_status_only');

      // Verify modified
      expect(
          notifier.debugState
              .exportLayout()
              .any((i) => (i as Map)['id'] == 'internet_status_only'),
          isFalse);

      // 2. Reset
      await notifier.resetLayout();

      // 3. Verify Default Restored
      expect(
          notifier.debugState
              .exportLayout()
              .any((i) => (i as Map)['id'] == 'internet_status_only'),
          isTrue);

      // 4. Verify Storage Cleared
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('sliver_dashboard_layout'), isFalse);
    });
  });
}
