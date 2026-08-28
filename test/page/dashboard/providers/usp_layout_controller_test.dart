import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The counting store below wraps whatever `setMockInitialValues` installed.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
// The drag entry points are not on the exported interface: `DashboardOverlay`
// and the item widget reach them through this extension, and #1393 is about what
// happens when they are called. Driving them directly is what lets the grab /
// move / drop sequence be tested without pumping the whole dashboard — the
// widget layer's own bindings are covered by the package.
// ignore: implementation_imports
import 'package:sliver_dashboard/src/controller/utility.dart';

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

/// One card out of [layout].
Map<String, dynamic> _card(List<dynamic> layout, String id) =>
    (layout.firstWhere((i) => (i as Map)['id'] == id) as Map)
        .cast<String, dynamic>();

/// The coordinates in [layout], one `id: x,y,w,h` line per card, id-ordered.
///
/// Compared instead of the raw maps where a layout goes through the pref and back:
/// a JSON round-trip is free to hand back `8.0` where the live layout held `8` for
/// a bound, and the coordinates are what a reorder or a compaction changes.
List<String> _geometry(List<dynamic> layout) => layout
    .map((i) => '${(i as Map)['id']}: ${i['x']},${i['y']},${i['w']},${i['h']}')
    .toList()
  ..sort();

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

    /// Deliberately not awaited, and that is the whole test (#1395).
    ///
    /// `_initializeLayout` is async — it awaits `SharedPreferences.getInstance()`
    /// before it can seed anything — while the first frame is laid out
    /// synchronously off the controller the constructor published. So there is a
    /// window in which the grid asks the controller for a breakpoint it has no
    /// cache for, and the package answers with `correctBounds`, which clamps `w`
    /// to the column count but leaves `minW` where it was: the desktop layout's
    /// half-width cards arrive in the phone grid declaring `minW: 6` of 4 columns.
    ///
    /// On 0.9.1 that frame was survivable — the tiles were laid out over-wide and
    /// the seed replaced them a frame later. 2.x asserts the invariant instead
    /// (`layout_engine.dart:963`, `'currentL.minW <= cols'`), so in debug the same
    /// window is a thrown `FlutterError` on every narrow-window boot, and the
    /// layout gate's four narrow cells for this page fail: 320 and 480 throw the
    /// assertion, 601 and 905 report the over-wide frame's own overflow.
    ///
    /// Asserted at the seam rather than through the page, because the page can
    /// only observe it as "the gate is red at four widths". `minW` is the value the
    /// package asserts on; `w` is checked with it so a fix that clamped only the
    /// bound the assertion names would not pass.
    test('every breakpoint is seeded before the first frame is laid out',
        () async {
      SharedPreferences.setMockInitialValues(const {});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);

      for (final slots in UspLayoutEnvelope.persistedSlotCounts) {
        controller.setSlotCount(slots);
        final tooWide = controller
            .exportLayout()
            .where((item) =>
                ((item as Map)['minW'] as int) > slots ||
                (item['w'] as int) > slots)
            .map((item) => '${(item as Map)['id']}'
                ' (w: ${item['w']}, minW: ${item['minW']})')
            .toList();
        expect(
          tooWide,
          isEmpty,
          reason: 'the $slots-column grid was asked for before the async seed '
              'finished, and answered with cards wider than it has columns',
        );
      }

      // Left where the grid expects to find it, so a later expectation in this
      // file cannot inherit a phone-sized controller from here.
      controller.setSlotCount(UspLayoutEnvelope.desktopSlotCount);
      await pumpAsync();
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
      // By id, not by position: `exportLayout()` sorts by id ascending (the
      // sliver-index stability change in sliver_dashboard 1.1.0), so the
      // first entry is `connected_devices`.
      final firstItem =
          layout.firstWhere((i) => i['id'] == 'stats_panel') as Map;
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
  // The phone grid is height-and-order only (#1293). It used to be enforced
  // twice: `lockToFullWidth` pinning `x`/`w`/`minW`/`maxW` on every import, plus
  // a subscription on the layout beacon that rewrote whatever a left-hand resize
  // handle had got past the pin — because 0.9.1 clamped the new *width* to the
  // caps but let `x` move freely, and then trimmed `w` to what was left of the
  // row.
  //
  // `sliver_dashboard` 2.6.0 clamps `x` against the same caps
  // (`dashboard_controller_impl.dart:1828-1842`), so the subscription became
  // unreachable and was deleted (#1399). These tests therefore changed shape:
  // they used to simulate the gesture by writing its result to the layout beacon
  // and assert it was undone, which is no longer a thing that happens to any
  // layout, by design. What is asserted here now is that every path into the
  // phone grid hands it a pinned layout; the gesture half — that no drag and no
  // arrow key can produce an unpinned one in the first place — is
  // `test/page/dashboard/views/edit_mode_interactions_test.dart`, which needs a
  // real page and a real pointer.
  // ---------------------------------------------------------------------------
  group('mobile width lock', () {
    const mobile = UspLayoutEnvelope.mobileSlotCount;

    LayoutItem itemById(DashboardController controller, String id) =>
        controller.layout.value.firstWhere((item) => item.id == id);

    /// The four fields the 2.6.0 resize resolver reads, for every card.
    List<List<num>> widthFields(DashboardController controller) => [
          for (final item in controller.layout.value)
            [item.x, item.w, item.minW, item.maxW],
        ];

    test('the phone grid hands over every card already pinned', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(mobile);

      // Every card, not a sample: the pin is what makes the resolver refuse a
      // width change, so one card that arrived without it is one card the user
      // can still narrow. There is no second mechanism left to catch it.
      //
      // `everyElement` is vacuously true on an empty list, so the count comes
      // first — a controller that handed over nothing at all would otherwise
      // read as fully pinned.
      expect(widthFields(controller), isNotEmpty, reason: 'the premise');
      expect(
        widthFields(controller),
        everyElement([0, mobile, mobile, mobile.toDouble()]),
      );
    });

    test('and the desktop grid does not', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      // The control. Width is the user's to choose everywhere above mobile, so
      // a pin applied at every breakpoint would pass the test above while
      // taking the feature away.
      final controller = container.read(uspSliverDashboardControllerProvider);
      final item = itemById(controller, 'device_info');
      expect(item.maxW, greaterThan(item.minW.toDouble()));
    });

    test('a preset applied on the phone grid arrives pinned', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      // This replaces 'a preset re-arms the lock on the controller it swaps in'.
      // The lock used to be a subscription, so a swap that forgot to re-arm it
      // left the phone grid editable; now it travels with the items, and what
      // has to hold instead is that the cards a preset *introduces* go through
      // [_normalize] on the way in.
      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(mobile);
      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .applyPreset(UspDashboardPreset.essential);

      // The preset's own card count, for the same reason as above and one more:
      // it is also the evidence that `applyPreset` landed at all. Without it a
      // preset that silently no-opped would leave the seeded layout in place and
      // the assertion below would still pass.
      final fields =
          widthFields(container.read(uspSliverDashboardControllerProvider));
      expect(fields, hasLength(UspDashboardPreset.essential.cardIds.length),
          reason: 'the premise');
      expect(fields, everyElement([0, mobile, mobile, mobile.toDouble()]));
    });

    test('the height is left unpinned on the phone grid', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(mobile);

      // The one dimension a phone still lets the user choose — and the reason
      // the pin is four named fields rather than "collapse every bound".
      final item = itemById(controller, 'device_info');
      expect(item.maxH, greaterThan(item.minH.toDouble()));
    });

    test('nothing watches the layout to correct it after the fact', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      // The deletion itself, asserted from the outside. Writing the beacon is
      // how the old tests stood in for a left-edge drag; the write is kept here
      // with the expectation inverted, because a *reverted* value would mean the
      // subscription is back — and with it the frame where the user saw a
      // narrowed card, which is what #1399 set out to remove. The guarantee that
      // no gesture can reach this state lives in the view test named above.
      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(mobile);
      controller.layout.value = [
        for (final item in controller.layout.value)
          if (item.id == 'device_info') item.copyWith(x: 1, w: 3) else item,
      ];
      await pumpAsync();

      final item = itemById(controller, 'device_info');
      expect([item.x, item.w], [1, 3]);
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

  // ---------------------------------------------------------------------------
  // #1393 — the grid stores the edits it makes to itself
  // ---------------------------------------------------------------------------
  //
  // Reordering was the one edit that never passed through a method here: the
  // pointer overlay and the a11y keyboard flow both move cards by talking to the
  // controller, and only the toolbar's own actions wrote anything out. A dragged
  // card was back where it started on the next reload. The fix is the controller's
  // `onLayoutChanged` hook, which the package calls once a mutation has settled.
  //
  // What is asserted is the pref rather than the render. The render already moved
  // before this ticket — that is precisely why the bug was invisible to whoever
  // was looking at the grid when they dragged the card.
  group('auto-persist (#1393)', () {
    /// The card the reorder tests move. First in the default layout's 6-column
    /// pairs, so it starts at the left edge with room to step right.
    const card = 'device_info';

    test('every controller this provider publishes reports its edits',
        () async {
      // Five construction sites, and one left unwired is one session's worth of
      // drags going nowhere: the constructor's, the one the stored layout is
      // imported into, a preset, a membership change, and a reset.
      final fresh = await createInitializedContainer();
      addTearDown(fresh.dispose);
      expect(
        fresh.read(uspSliverDashboardControllerProvider).onLayoutChanged,
        isNotNull,
        reason: 'a first run has no stored layout, so nothing replaces the '
            'controller the constructor built',
      );

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(pUspSliverDashboardLayout)!;

      final reloaded = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: stored},
      );
      addTearDown(reloaded.dispose);
      final notifier =
          reloaded.read(uspSliverDashboardControllerProvider.notifier);
      expect(
        reloaded.read(uspSliverDashboardControllerProvider).onLayoutChanged,
        isNotNull,
        reason: 'the instance the stored layout was imported into',
      );

      await notifier.applyPreset(UspDashboardPreset.essential);
      expect(
        reloaded.read(uspSliverDashboardControllerProvider).onLayoutChanged,
        isNotNull,
        reason: 'after a preset',
      );

      await notifier.removeWidget('stats_panel');
      expect(
        reloaded.read(uspSliverDashboardControllerProvider).onLayoutChanged,
        isNotNull,
        reason: 'after a membership change replaces the instance',
      );

      await notifier.resetLayout();
      expect(
        reloaded.read(uspSliverDashboardControllerProvider).onLayoutChanged,
        isNotNull,
        reason: 'after a reset',
      );
    });

    test('a pointer drag is stored when it is dropped', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final prefs = await SharedPreferences.getInstance();
      final baseline = prefs.getString(pUspSliverDashboardLayout);
      expect(baseline, isNotNull, reason: 'the first init seeds a baseline');

      final before = _card(controller.exportLayout(), card);
      final targetX = (before['x'] as int) + 1;

      // The three calls DashboardOverlay makes for a pointer drag: grab, follow
      // the pointer, drop. One cell is 100px with no spacing here, so a content
      // position of (targetX * 100, y * 100) puts the pivot in column targetX.
      controller.internal.onDragStart(card);
      controller.internal.onDragUpdate(
        card,
        Offset(targetX * 100.0, (before['y'] as int) * 100.0),
        slotWidth: 100,
        slotHeight: 100,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
      );
      controller.internal.onDragEnd(card);
      await pumpAsync();

      expect(_card(controller.exportLayout(), card)['x'], targetX,
          reason: 'the drag moved the card one column right');

      final saved = prefs.getString(pUspSliverDashboardLayout);
      expect(saved, isNot(baseline),
          reason: 'a dropped drag reaches SharedPreferences on its own — no '
              '"Done" and no explicit save (#1393)');
      expect(_card(_savedDesktopLayout(saved!), card)['x'], targetX);
    });

    test('a keyboard grab is stored when it is dropped, and reloads unchanged',
        () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final prefs = await SharedPreferences.getInstance();
      final baseline = prefs.getString(pUspSliverDashboardLayout);
      final originalX = _card(controller.exportLayout(), card)['x'] as int;

      // The a11y sequence: Space grabs, an arrow key moves, Space drops.
      controller.clearSelection();
      controller.toggleSelection(card);
      controller.internal.onDragStart(card);
      controller.moveActiveItemBy(1, 0);
      controller.internal.onDragEnd(card);
      await pumpAsync();

      final dropped = controller.exportLayout();
      expect(_card(dropped, card)['x'], originalX + 1,
          reason: 'the arrow key moved the card one column right');

      final saved = prefs.getString(pUspSliverDashboardLayout);
      expect(saved, isNot(baseline),
          reason: 'the keyboard path ends in the same drop as the pointer one, '
              'so it stores the move the same way (#1393)');

      // And the stored layout has to be a fixed point of the load path: the
      // import compacts what it reads, so a layout that shifts on the way back in
      // would leave the cards somewhere other than where the user dropped them.
      final afterReload = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: saved!},
      );
      addTearDown(afterReload.dispose);

      expect(
        _geometry(afterReload
            .read(uspSliverDashboardControllerProvider)
            .exportLayout()),
        _geometry(dropped),
        reason: 'the reloaded grid is the one that was dropped, card for card',
      );
    });

    test('a grab that is still held is not stored', () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final prefs = await SharedPreferences.getInstance();
      final baseline = prefs.getString(pUspSliverDashboardLayout);
      final before = _geometry(controller.exportLayout());

      controller.clearSelection();
      controller.toggleSelection(card);
      controller.internal.onDragStart(card);
      controller.moveActiveItemBy(1, 0);
      await pumpAsync();

      expect(_geometry(controller.exportLayout()), isNot(before),
          reason: 'the grab is genuinely in flight and has moved the card');
      expect(prefs.getString(pUspSliverDashboardLayout), baseline,
          reason: 'the package reports a change when the interaction settles, '
              'not while it is in progress — a layout mid-grab is uncompacted, '
              'so storing it would hand the load path a layout it disagrees '
              'with. What happens to an unfinished grab is decided by the exit '
              'path in dashboard_edit_mode_provider.dart.');
    });

    // -------------------------------------------------------------------------
    // Stored once
    // -------------------------------------------------------------------------
    // The hook made three explicit `saveLayout()` calls in
    // usp_sliver_dashboard_view.dart redundant, and each one was a second walk of
    // all three breakpoints — export, normalise, encode, write — for a pref that
    // already held the answer. These are what licenses deleting them: not "the
    // edit is stored" but "the edit is stored *once*, by the mutation itself".
    group('stored once, by the mutation itself', () {
      /// A container whose writes to the layout key are counted.
      ///
      /// The counter starts after initialization, which legitimately writes once
      /// when there is no stored layout to load.
      Future<(ProviderContainer, _LayoutWriteCounter)>
          countedContainer() async {
        SharedPreferences.setMockInitialValues(const {});
        final counter =
            _LayoutWriteCounter(SharedPreferencesStorePlatform.instance);
        SharedPreferencesStorePlatform.instance = counter;
        addTearDown(() => SharedPreferencesStorePlatform.instance =
            counter.inner as SharedPreferencesStorePlatform);

        final container = ProviderContainer();
        container.read(uspSliverDashboardControllerProvider);
        await pumpAsync();
        counter.writes = 0;
        return (container, counter);
      }

      test('an optimise, so the header bar does not save again', () async {
        final (container, counter) = await countedContainer();
        addTearDown(container.dispose);

        final controller = container.read(uspSliverDashboardControllerProvider);
        // Make the layout worth optimising, so the mutation is real.
        controller.internal.onDragStart(card);
        controller.moveActiveItemBy(0, 3);
        controller.internal.onDragEnd(card);
        await pumpAsync();
        counter.writes = 0;

        controller.optimizeLayout();
        await pumpAsync();

        expect(counter.writes, 1);
        final prefs = await SharedPreferences.getInstance();
        expect(
          _geometry(
              _savedDesktopLayout(prefs.getString(pUspSliverDashboardLayout)!)),
          _geometry(controller.exportLayout()),
          reason: 'and the one write is the optimised grid',
        );
      });

      test('a trash delete, so the overlay callback does not save again',
          () async {
        final (container, counter) = await countedContainer();
        addTearDown(container.dispose);

        // What DashboardOverlay does when a card is dropped on the trash: remove
        // it, then notify. The notification used to save; the removal already
        // has.
        final controller = container.read(uspSliverDashboardControllerProvider);
        controller.removeItems([card]);
        await pumpAsync();

        expect(counter.writes, 1);
        final prefs = await SharedPreferences.getInstance();
        expect(
          _savedDesktopLayout(prefs.getString(pUspSliverDashboardLayout)!)
              .map((i) => (i as Map)['id']),
          isNot(contains(card)),
          reason: 'and the one write is the deletion',
        );
      });

      test(
          'a resize the spec allows, so the resize handler does not save again',
          () async {
        final (container, counter) = await countedContainer();
        addTearDown(container.dispose);

        final controller = container.read(uspSliverDashboardControllerProvider);
        final before = _card(controller.exportLayout(), card);

        // One row taller, which every card's spec allows — the branch of
        // _handleResizeEnd that used to call saveLayout and now returns.
        controller.internal.onResizeStart(card);
        controller.internal.onResizeUpdate(
          card,
          ResizeHandle.bottomRight,
          const Offset(0, 100),
          slotWidth: 100,
          slotHeight: 100,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        );
        controller.internal.onResizeEnd(card);
        await pumpAsync();

        expect(_card(controller.exportLayout(), card)['h'],
            (before['h'] as int) + 1,
            reason: 'the resize happened');
        expect(counter.writes, 1);
      });
    });

    test('a card added straight to the controller is caught, not stored',
        () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      // The walk can only reconcile *deletions* into the other breakpoints. A
      // card the live layout gained on its own is placed there by the package at
      // the width it has here, and the placement never narrows it — so the pref
      // ends up holding a card wider than the grid it sits in, with nothing
      // raised. Now that the hook runs the walk after every controller mutation,
      // the constraint has an assertion behind it instead of a comment (#1393).
      // Under 0.9.1 the same walk hung instead; the assertion predates the bump
      // and is what still makes this fail (#1395).
      final controller = container.read(uspSliverDashboardControllerProvider);
      expect(
        () => controller.addItem(
          const LayoutItem(id: 'zz_probe', x: 0, y: 0, w: 6, h: 2),
        ),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('addWidget'),
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // #1395 — the input surface 2.6.0 turns on by default
  // ---------------------------------------------------------------------------
  //
  // Two majors of `sliver_dashboard` arrived with three interaction surfaces
  // already switched on: an undo/redo history, a rubberband selection over empty
  // grid space, and a keyboard set that includes Delete and Ctrl/Cmd+A. A bump
  // is not the place to start shipping gestures, so each is turned off here at
  // the one seam that builds every controller — and the tests below are what stop
  // a later refactor from quietly re-arming them.
  //
  // The history is not a preference. It is a defect for this notifier: see the
  // first test.
  group('2.6.0 input surface (#1395)', () {
    test('the undo history is off, because ours would restore a foreign grid',
        () async {
      final container = await createInitializedContainer();
      addTearDown(container.dispose);

      // `_importQuietly` suppresses *our* persist hook, not the package's
      // bookkeeping: `importLayout` records a history entry
      // (`dashboard_controller_impl.dart:1030`), so seeding the 8- and 4-column
      // caches pushes those two layouts onto the undo stack before the user has
      // touched anything. `_restoreSnapshot` then re-projects a snapshot taken at
      // another slot count onto the live grid, and #1393's hook persists the
      // result. Measured on 2.6.0 with the history left at its default: `canUndo`
      // was already true here, and the first Ctrl+Z narrowed `stats_panel` from
      // 12 slots to 8 on the desktop grid and saved it.
      //
      // So the entry condition is what is asserted — an empty stack, not a
      // well-behaved one. Turning the history on belongs to the follow-up that
      // first keeps this notifier's own imports out of it.
      final controller = container.read(uspSliverDashboardControllerProvider);
      expect(controller.maxHistoryLength, 0);
      expect(controller.canUndo.value, isFalse,
          reason: 'nothing the user did is undoable, because nothing the user '
              'did is on the stack — only our own seeding walk was');
      expect(controller.canRedo.value, isFalse);

      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString(pUspSliverDashboardLayout);
      final geometryBefore = _geometry(controller.exportLayout());

      expect(await controller.undo(), isFalse);
      expect(await controller.redo(), isFalse);
      await pumpAsync();

      expect(_geometry(controller.exportLayout()), geometryBefore,
          reason: 'a keyboard undo in edit mode must not move a card the user '
              'never moved');
      expect(prefs.getString(pUspSliverDashboardLayout), before,
          reason: 'and must not reach the pref');
    });

    test('every controller this provider publishes carries the input policy',
        () async {
      // The same five construction sites as the auto-persist test above. The
      // policy lives on the controller, not on the view, so an unwired instance
      // silently reverts to the package defaults for as long as it is published.
      //
      // Every field is named, not just the ones this ticket switched off. The
      // constraint is `^2.6.0` and `pubspec.lock` is gitignored, so a minor with
      // one more modifier field — or one flipped default — arrives on a
      // `flutter pub get` with no diff to review. `swapModeModifier` is why this
      // is written out: it was already live and unnoticed because nothing here
      // enumerated the set.
      void expectPolicy(ProviderContainer container, String site) {
        final controller = container.read(uspSliverDashboardControllerProvider);
        expect(controller.maxHistoryLength, 0, reason: 'history: $site');
        expect(controller.lassoStyle.isEnabled, isFalse,
            reason: 'lasso: $site');
        expect(controller.dragMode.value, DragMode.cascade,
            reason: 'drag mode: $site — our geometry rules are written against '
                'push-neighbours');

        final shortcuts = controller.shortcuts;
        expect(shortcuts, isNotNull,
            reason: 'shortcuts: $site — a null config is the package default, '
                'which binds Delete and Ctrl/Cmd+A');

        // Off (#1395). Each of these is new in 2.x, so an empty set is today's
        // behaviour rather than one taken away.
        expect(shortcuts!.delete, isEmpty, reason: 'delete key: $site');
        expect(shortcuts.selectAll, isEmpty, reason: 'select all: $site');
        expect(shortcuts.undo, isEmpty, reason: 'undo chord: $site');
        expect(shortcuts.redo, isEmpty, reason: 'redo chord: $site');
        expect(shortcuts.swapModeModifier, isEmpty,
            reason: 'swap-on-Shift: $site');

        // On, and asserted so that "narrow the set" cannot drift into "drop the
        // keyboard": grab / move / drop is the only way to reorder a card
        // without a pointer.
        expect(shortcuts.grab, isNotEmpty, reason: 'grab: $site');
        expect(shortcuts.drop, isNotEmpty, reason: 'drop: $site');
        expect(shortcuts.moveUp, isNotEmpty, reason: 'arrows: $site');
        expect(shortcuts.moveDown, isNotEmpty, reason: 'arrows: $site');
        expect(shortcuts.moveLeft, isNotEmpty, reason: 'arrows: $site');
        expect(shortcuts.moveRight, isNotEmpty, reason: 'arrows: $site');
        expect(shortcuts.cancel, isNotEmpty, reason: 'escape: $site');

        // Left at the package default, and named here so that a change to one
        // shows up as a failing test rather than as a behaviour report from the
        // field. `duplicate` and `cloneKeys` are inert while no
        // `onCloneRequested` is registered; `multiSelectKeys` predates the bump.
        expect(shortcuts.duplicate, isNotEmpty, reason: 'duplicate: $site');
        expect(shortcuts.cloneKeys, isNotEmpty, reason: 'clone keys: $site');
        expect(shortcuts.multiSelectKeys, isNotEmpty,
            reason: 'multi-select click: $site');
        expect(shortcuts.lassoModifier, isNotEmpty,
            reason: 'lasso modifier: $site — inert while the lasso is off, and '
                'the field that arms it if it is ever turned back on');
      }

      // The instance a first run keeps, which is `_createDefaultController`'s —
      // not the bootstrap in the initializer list, which `_swapController`
      // replaces before anything can read the provider. That one carries the
      // policy through `_applyInputPolicy` because no test can reach it.
      final fresh = await createInitializedContainer();
      addTearDown(fresh.dispose);
      expectPolicy(fresh, 'a first run, with no stored layout');

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(pUspSliverDashboardLayout)!;

      final reloaded = await createInitializedContainer(
        initialValues: {pUspSliverDashboardLayout: stored},
      );
      addTearDown(reloaded.dispose);
      final notifier =
          reloaded.read(uspSliverDashboardControllerProvider.notifier);
      expectPolicy(
          reloaded, 'the instance the stored layout was imported into');

      await notifier.applyPreset(UspDashboardPreset.essential);
      expectPolicy(reloaded, 'after a preset');

      await notifier.removeWidget('stats_panel');
      expectPolicy(reloaded, 'after a membership change replaces the instance');

      await notifier.resetLayout();
      expectPolicy(reloaded, 'after a reset');
    });

    test('the shortcut config is one shared instance across controller swaps',
        () async {
      // `DashboardItemWidget` rebuilds its two intent maps whenever the config
      // is not `identical` to the one it cached (`dashboard_item_widget.dart:449`),
      // and every card holds its own cache. Handing each controller a freshly
      // built config would re-key all 18 of them on every preset and every
      // membership change.
      final container = await createInitializedContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);

      final first =
          container.read(uspSliverDashboardControllerProvider).shortcuts;
      await notifier.applyPreset(UspDashboardPreset.essential);
      final second =
          container.read(uspSliverDashboardControllerProvider).shortcuts;

      // Both null would satisfy `identical` while meaning "package defaults".
      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
    });
  });
}

/// Counts writes to the layout key, so "stored once" can be asserted as once
/// rather than as at-least-once.
///
/// Delegates everything else to the in-memory store `setMockInitialValues`
/// installs — the point is the count, not a second implementation of prefs.
class _LayoutWriteCounter extends SharedPreferencesStorePlatform {
  _LayoutWriteCounter(this.inner);

  final SharedPreferencesStorePlatform inner;
  int writes = 0;

  @override
  bool get isMock => inner.isMock;

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    // The legacy API namespaces keys with `flutter.`.
    if (key.endsWith(pUspSliverDashboardLayout)) writes++;
    return inner.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) => inner.remove(key);

  @override
  Future<bool> clear() => inner.clear();

  @override
  Future<Map<String, Object>> getAll() => inner.getAll();

  @override
  Future<bool> clearWithPrefix(String prefix) => inner.clearWithPrefix(prefix);

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) =>
      inner.clearWithParameters(parameters);

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix) =>
      inner.getAllWithPrefix(prefix);

  @override
  Future<Map<String, Object>> getAllWithParameters(
          GetAllParameters parameters) =>
      inner.getAllWithParameters(parameters);
}
