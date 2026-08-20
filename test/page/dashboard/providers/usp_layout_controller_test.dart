import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

/// Wait for async initialization chains (SharedPreferences) to settle.
Future<void> pumpAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
}

/// Helper: creates a minimal valid layout item map for testing.
Map<String, dynamic> _layoutItem(
  String id, {
  int x = 0,
  int y = 0,
  int w = 6,
  int h = 3,
  int minW = 3,
  double maxW = 8.0,
  int minH = 2,
  double maxH = 8.0,
}) {
  return {
    'id': id,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'minW': minW,
    'maxW': maxW,
    'minH': minH,
    'maxH': maxH,
  };
}

/// The desktop grid out of a persisted layout envelope.
///
/// The pref holds one layout per breakpoint keyed by slot count (#1293), so
/// "what got saved" has to name a grid; every test here arranges and asserts on
/// the desktop one. Read straight out of the JSON rather than through
/// [UspLayoutEnvelope.tryDecode] so a decoder bug cannot hide behind these
/// assertions — the envelope's own shape is covered in
/// test/page/dashboard/models/usp_layout_envelope_test.dart.
List<dynamic> _savedDesktopLayout(String raw) {
  final layouts = (jsonDecode(raw) as Map)['layouts'] as Map;
  return layouts['${UspLayoutEnvelope.desktopSlotCount}'] as List;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Creates a ProviderContainer, triggers async init, waits for it to settle.
  Future<ProviderContainer> createInitializedContainer({
    Map<String, Object> initialValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final container = ProviderContainer();
    // Force provider creation (triggers constructor → _initializeLayout)
    container.read(uspSliverDashboardControllerProvider);
    await pumpAsync();
    return container;
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  group('Initialization', () {
    test('no saved layout → creates 18 default items', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      expect(layout.length, 18);
    });

    test('no saved layout → saves default to prefs', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pUspSliverDashboardLayout), isNotNull);
    });

    test('valid saved layout → imports correctly', () async {
      final savedLayout = [
        _layoutItem('stats_panel', x: 0, y: 0, w: 12, h: 1),
        _layoutItem('device_info', x: 0, y: 1, w: 6, h: 3),
      ];
      final container = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: jsonEncode(savedLayout)},
      );
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      expect(layout.length, 2);
    });

    test('valid saved layout → preserves item IDs', () async {
      final savedLayout = [
        _layoutItem('stats_panel', x: 0, y: 0, w: 12, h: 1),
        _layoutItem('device_info', x: 0, y: 1),
        _layoutItem('network_status', x: 6, y: 1),
      ];
      final container = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: jsonEncode(savedLayout)},
      );
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      final ids = layout.map((item) => (item as Map)['id']).toSet();
      expect(
          ids, containsAll(['stats_panel', 'device_info', 'network_status']));
    });

    test('saved layout with unknown ID → accepts as package widget', () async {
      final savedLayout = [
        _layoutItem('unknown_widget_xyz', x: 0, y: 0),
      ];
      final container = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: jsonEncode(savedLayout)},
      );
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      // Unknown IDs are accepted — may be package widgets loading async
      expect(layout.length, 1);
    });

    test('saved layout with unknown ID → preserves in prefs', () async {
      final savedLayout = [
        _layoutItem('unknown_widget_xyz', x: 0, y: 0),
      ];
      final container = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: jsonEncode(savedLayout)},
      );
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspSliverDashboardLayout);
      expect(saved, isNotNull);
      final decoded = _savedDesktopLayout(saved!);
      final ids = decoded.map((item) => (item as Map)['id']).toSet();
      // Unknown IDs preserved — may be package widgets
      expect(ids, contains('unknown_widget_xyz'));
    });

    test('malformed JSON → resets to default', () async {
      final container = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: 'not valid json {{{'},
      );
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      expect(layout.length, 18);
    });

    test('malformed JSON → saves default to prefs', () async {
      final container = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: 'not valid json {{{'},
      );
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspSliverDashboardLayout);
      expect(saved, isNotNull);
      final decoded = _savedDesktopLayout(saved!);
      expect(decoded.length, 18);
    });

    test('saved layout with fewer cards (preset) is valid', () async {
      final savedLayout = [
        _layoutItem('stats_panel', x: 0, y: 0, w: 12, h: 1),
        _layoutItem('device_info', x: 0, y: 1),
      ];
      final container = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: jsonEncode(savedLayout)},
      );
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      // Should NOT reset — fewer cards are valid (preset/customisation)
      expect(layout.length, 2);
    });

    test('saved layout preserves positions', () async {
      final savedLayout = [
        _layoutItem('stats_panel', x: 0, y: 0, w: 12, h: 1),
        _layoutItem('device_info', x: 0, y: 1, w: 6, h: 3),
      ];
      final container = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: jsonEncode(savedLayout)},
      );
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      final statsPanel = layout
          .firstWhere((item) => (item as Map)['id'] == 'stats_panel') as Map;
      expect(statsPanel['w'], 12);
      expect(statsPanel['y'], 0);
    });

    test('constructor creates StateNotifier with non-null state', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      expect(notifier, isA<UspSliverDashboardControllerNotifier>());
      expect(container.read(uspSliverDashboardControllerProvider), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // saveLayout
  // ---------------------------------------------------------------------------
  group('saveLayout', () {
    test('persists JSON to SharedPreferences', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.saveLayout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pUspSliverDashboardLayout), isNotNull);
    });

    test('JSON contains correct fields', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspSliverDashboardLayout);
      expect(saved, isNotNull);

      final decoded = _savedDesktopLayout(saved!);
      final first = decoded.first as Map<String, dynamic>;
      expect(first.containsKey('id'), isTrue);
      expect(first.containsKey('x'), isTrue);
      expect(first.containsKey('y'), isTrue);
      expect(first.containsKey('w'), isTrue);
      expect(first.containsKey('h'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // resetLayout
  // ---------------------------------------------------------------------------
  group('resetLayout', () {
    test('creates new default controller with 18 items', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      // First reduce layout via preset
      await notifier.applyPreset(UspDashboardPreset.essential);
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          6);

      // Reset
      await notifier.resetLayout();
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          18); // speedTest disabled (#857)
    });

    test('removes prefs key', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.resetLayout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pUspSliverDashboardLayout), isNull);
    });

    test('positions match fresh default layout', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.resetLayout();

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      final firstItem = layout.first as Map;
      expect(firstItem['id'], 'stats_panel');
      expect(firstItem['x'], 0);
      expect(firstItem['y'], 0);
      expect(firstItem['w'], 12);
    });
  });

  // ---------------------------------------------------------------------------
  // updateItemSize
  // ---------------------------------------------------------------------------
  group('updateItemSize', () {
    test('updates w and h for existing ID', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.updateItemSize('device_info', 8, 5);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      final item =
          layout.firstWhere((i) => (i as Map)['id'] == 'device_info') as Map;
      expect(item['w'], 8);
      expect(item['h'], 5);
    });

    test('preserves other items', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final beforeCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;

      await notifier.updateItemSize('device_info', 8, 5);

      final afterCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;
      expect(afterCount, beforeCount);
    });

    test('saves after change', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.updateItemSize('device_info', 8, 5);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspSliverDashboardLayout);
      expect(saved, isNotNull);
      final decoded = _savedDesktopLayout(saved!);
      final item =
          decoded.firstWhere((i) => (i as Map)['id'] == 'device_info') as Map;
      expect(item['w'], 8);
      expect(item['h'], 5);
    });

    test('no-op when size unchanged', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      final item =
          layout.firstWhere((i) => (i as Map)['id'] == 'device_info') as Map;
      final originalW = item['w'] as int;
      final originalH = item['h'] as int;

      // Same size → no state change
      final controllerBefore =
          container.read(uspSliverDashboardControllerProvider);
      await notifier.updateItemSize('device_info', originalW, originalH);
      final controllerAfter =
          container.read(uspSliverDashboardControllerProvider);

      // Should be the exact same instance (state was not reassigned)
      expect(identical(controllerBefore, controllerAfter), isTrue);
    });

    test('handles unknown ID gracefully', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final controllerBefore =
          container.read(uspSliverDashboardControllerProvider);

      // Should not throw
      await notifier.updateItemSize('nonexistent_widget', 8, 5);

      final controllerAfter =
          container.read(uspSliverDashboardControllerProvider);
      // No change since ID not found → changed remains false
      expect(identical(controllerBefore, controllerAfter), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Mobile width lock
  //
  // The phone grid is height-and-order only, and the width caps cannot enforce
  // that on their own: the left-hand resize handles move `x`, and the package
  // then trims `w` to whatever is left of the row (#1293).
  //
  // These tests stand in for that gesture by writing the geometry it produces
  // straight to the layout beacon — which is the last thing
  // `DashboardController.onResizeUpdate` does — because the call that reaches it
  // sits behind the package's internal-only extension.
  // ---------------------------------------------------------------------------
  group('mobile width lock', () {
    /// What one column of drag on [id]'s left edge leaves behind on a 4-column
    /// grid. Either way the card ends up a column narrower; dragging inwards
    /// moves it as well, dragging outwards runs into the row's own edge and the
    /// package trims the width there instead.
    void dragLeftEdge(
      DashboardController controller,
      String id, {
      bool inwards = true,
    }) {
      controller.layout.value = [
        for (final item in controller.layout.value)
          if (item.id == id) item.copyWith(x: inwards ? 1 : 0, w: 3) else item,
      ];
    }

    LayoutItem itemById(DashboardController controller, String id) =>
        controller.layout.value.firstWhere((item) => item.id == id);

    test('a left-edge resize on the phone grid is undone', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(UspLayoutEnvelope.mobileSlotCount);
      expect(itemById(controller, 'device_info').x, 0,
          reason: 'the phone grid starts out locked');

      dragLeftEdge(controller, 'device_info');
      await pumpAsync();

      final item = itemById(controller, 'device_info');
      expect(item.x, 0);
      expect(item.w, UspLayoutEnvelope.mobileSlotCount);
    });

    test('a left-edge resize that only narrows is undone as well', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(UspLayoutEnvelope.mobileSlotCount);

      dragLeftEdge(controller, 'device_info', inwards: false);
      await pumpAsync();

      expect(itemById(controller, 'device_info').w,
          UspLayoutEnvelope.mobileSlotCount);
    });

    test('the same resize stands on the desktop grid', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      // Width is the user's to choose everywhere above mobile, so the guard has
      // to keep its hands off this one.
      final controller = container.read(uspSliverDashboardControllerProvider);
      dragLeftEdge(controller, 'device_info');
      await pumpAsync();

      final item = itemById(controller, 'device_info');
      expect(item.x, 1);
      expect(item.w, 3);
    });

    test('a height resize on the phone grid is left alone', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(UspLayoutEnvelope.mobileSlotCount);
      final originalH = itemById(controller, 'device_info').h;

      controller.layout.value = [
        for (final item in controller.layout.value)
          if (item.id == 'device_info')
            item.copyWith(h: originalH + 2)
          else
            item,
      ];
      await pumpAsync();

      // The one dimension a phone still lets the user choose.
      final item = itemById(controller, 'device_info');
      expect(item.h, originalH + 2);
      expect(item.x, 0);
      expect(item.w, UspLayoutEnvelope.mobileSlotCount);
    });

    test('a preset re-arms the lock on the controller it swaps in', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      // The lock is a subscription on one controller's layout, so every swap has
      // to re-arm it or the phone grid quietly becomes editable again.
      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .applyPreset(UspDashboardPreset.essential);

      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(UspLayoutEnvelope.mobileSlotCount);
      dragLeftEdge(controller, 'device_info');
      await pumpAsync();

      expect(itemById(controller, 'device_info').x, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // addWidget
  // ---------------------------------------------------------------------------
  group('addWidget', () {
    test('appends at bottom (y >= maxY)', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);

      // Calculate current maxY
      final beforeLayout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      int maxY = 0;
      for (final item in beforeLayout) {
        final map = item as Map;
        final y = map['y'] as int;
        final h = map['h'] as int;
        if (y + h > maxY) maxY = y + h;
      }

      await notifier.addWidget('topology');

      final afterLayout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      final newItem =
          afterLayout.firstWhere((i) => (i as Map)['id'] == 'topology') as Map;
      // After compaction the y might shift, but should be at or beyond maxY
      expect(newItem['y'], greaterThanOrEqualTo(maxY - 1));
    });

    test('prevents duplicate', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final beforeCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;

      // device_info already exists in default layout
      await notifier.addWidget('device_info');

      final afterCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;
      expect(afterCount, beforeCount);
    });

    test('unknown ID → no-op', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final beforeCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;

      await notifier.addWidget('nonexistent_widget');

      final afterCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;
      expect(afterCount, beforeCount);
    });

    test('saves after add', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);

      // Clear prefs to verify save
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pUspSliverDashboardLayout);

      await notifier.addWidget('topology');

      expect(prefs.getString(pUspSliverDashboardLayout), isNotNull);
    });

    test('new item has valid dimensions from spec', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);

      await notifier.addWidget('topology');

      final layout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      final newItem =
          layout.firstWhere((i) => (i as Map)['id'] == 'topology') as Map;
      expect(newItem['w'], greaterThan(0));
      expect(newItem['h'], greaterThan(0));
    });

    test('new item x >= 0', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);

      await notifier.addWidget('topology');

      final layout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      final newItem =
          layout.firstWhere((i) => (i as Map)['id'] == 'topology') as Map;
      expect(newItem['x'], greaterThanOrEqualTo(0));
    });

    test('add to preset increments count by 1', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          6);

      await notifier.addWidget('topology');

      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          7);
    });
  });

  // ---------------------------------------------------------------------------
  // applyPreset
  // ---------------------------------------------------------------------------
  group('applyPreset', () {
    test('essential → 6 items', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);

      final layout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      expect(layout.length, 6);
    });

    test('monitoring → 8 items', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.monitoring);

      final layout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      expect(layout.length, 8);
    });

    test('professional → 18 items', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.professional);

      final layout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      expect(layout.length, 18);
    });

    test('saves preset layout to prefs', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspSliverDashboardLayout);
      expect(saved, isNotNull);
      final decoded = _savedDesktopLayout(saved!);
      expect(decoded.length, 6);
    });

    test('stats_panel remains first and full-width', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);

      final layout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      final statsPanel =
          layout.firstWhere((i) => (i as Map)['id'] == 'stats_panel') as Map;
      expect(statsPanel['w'], 12);
      expect(statsPanel['x'], 0);
      expect(statsPanel['y'], 0);
    });
  });

  // ---------------------------------------------------------------------------
  // removeWidget
  // ---------------------------------------------------------------------------
  group('removeWidget', () {
    test('removes existing widget', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final beforeCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;

      await notifier.removeWidget('device_info');

      final afterCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;
      expect(afterCount, beforeCount - 1);
    });

    test('saves after removal', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.removeWidget('device_info');

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspSliverDashboardLayout);
      expect(saved, isNotNull);
      final decoded = _savedDesktopLayout(saved!);
      final ids = decoded.map((i) => (i as Map)['id']).toSet();
      expect(ids.contains('device_info'), isFalse);
    });

    test('unknown ID → no-op', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final beforeCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;

      await notifier.removeWidget('nonexistent_widget');

      final afterCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;
      expect(afterCount, beforeCount);
    });

    test('no save when ID not found', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final prefs = await SharedPreferences.getInstance();
      final beforeSave = prefs.getString(pUspSliverDashboardLayout);

      await notifier.removeWidget('nonexistent_widget');

      final afterSave = prefs.getString(pUspSliverDashboardLayout);
      expect(afterSave, equals(beforeSave));
    });
  });

  // ---------------------------------------------------------------------------
  // Integration flows
  // ---------------------------------------------------------------------------
  group('Integration flows', () {
    test('add → remove → same count', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);
      final initialCount = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .length;
      expect(initialCount, 6);

      await notifier.addWidget('topology');
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          7);

      await notifier.removeWidget('topology');
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          6);
    });

    test('applyPreset → add → length + 1', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          6);

      await notifier.addWidget('topology');
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          7);
    });

    test('resetLayout → applyPreset → correct count', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.resetLayout();
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          18); // speedTest disabled (#857)

      await notifier.applyPreset(UspDashboardPreset.monitoring);
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          8);
    });

    test('multiple adds work sequentially', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          6);

      await notifier.addWidget('topology');
      await notifier.addWidget('traffic_analysis');
      expect(
          container
              .read(uspSliverDashboardControllerProvider)
              .exportLayout()
              .length,
          8);
    });

    test('remove non-hideable widget still works at controller level',
        () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      // stats_panel is non-hideable at UI level, but controller allows it
      await notifier.removeWidget('stats_panel');

      final layout =
          container.read(uspSliverDashboardControllerProvider).exportLayout();
      final ids = layout.map((i) => (i as Map)['id']).toSet();
      expect(ids.contains('stats_panel'), isFalse);
    });

    test('provider provides correct type', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      expect(notifier, isA<UspSliverDashboardControllerNotifier>());
    });

    test('state changes update provider value', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      final before = container.read(uspSliverDashboardControllerProvider);

      await notifier.applyPreset(UspDashboardPreset.essential);

      final after = container.read(uspSliverDashboardControllerProvider);
      expect(identical(before, after), isFalse);
    });

    test('dispose does not crash', () async {
      final container = await createInitializedContainer();
      container.dispose();
    });

    test('persistence round-trip: save → read from prefs', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.applyPreset(UspDashboardPreset.essential);

      // Verify the persisted data matches
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(pUspSliverDashboardLayout)!;
      final decoded = _savedDesktopLayout(savedJson);
      expect(decoded.length, 6);
      final ids = decoded.map((i) => (i as Map)['id']).toSet();
      expect(ids.contains('stats_panel'), isTrue);
    });

    test('updateItemSize → save → data preserved in prefs', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      await notifier.updateItemSize('device_info', 8, 5);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pUspSliverDashboardLayout);
      final decoded = _savedDesktopLayout(saved!);
      final item =
          decoded.firstWhere((i) => (i as Map)['id'] == 'device_info') as Map;
      expect(item['w'], 8);
      expect(item['h'], 5);
    });
  });
}
