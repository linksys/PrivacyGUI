import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

import '../../../util/dashboard/layout_provider_harness.dart';

/// Per-breakpoint layout persistence, and the mobile full-width lock (#1293).
///
/// ## The bug
///
/// `DashboardController.exportLayout()` returns coordinates in whatever slot
/// count the controller is currently on, and the pref used to be a bare list
/// with no record of that. So the dashboard wrote 4-column coordinates at
/// mobile and read them back as 12-column ones at desktop: every card came back
/// a third of its width. Worse, the mobile seed also scales `minW`/`maxW` down,
/// so the narrow widths were then *capped* narrow — the user could not drag them
/// back even manually. Resizing on a phone permanently wrecked the desktop
/// dashboard.
///
/// ## The fix, in two halves
///
/// 1. The pref is an envelope keyed by slot count, so each breakpoint keeps its
///    own geometry and a save at one never speaks for another.
/// 2. At 4 columns the width is not the user's to change: every card is pinned
///    full-width (`x=0, w=4, minW=maxW=4`), leaving height and order editable.
///    The package clamps resize deltas to `[minW, maxW]`
///    (`dashboard_controller_impl.dart`), so pinning those two *is* the lock —
///    true of every handle since 2.6.0, which clamps `x` against the same caps
///    rather than only `w`. Under 0.9.1 the left-hand handles got past it and a
///    beacon subscription put the layout back; that subscription is gone (#1399).
///
/// Membership is deliberately **not** per-breakpoint: deleting a card on a phone
/// deletes the card, not just its phone placement. Only geometry is per-grid.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<UspLayoutEnvelope> storedEnvelope() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(pUspSliverDashboardLayout);
    expect(raw, isNotNull, reason: 'Nothing was persisted.');
    final envelope = UspLayoutEnvelope.tryDecode(raw!);
    expect(envelope, isNotNull, reason: 'Persisted value is unreadable: $raw');
    return envelope!;
  }

  /// The layout the controller is holding right now.
  ///
  /// `layout.value` rather than `exportLayout()`, which is that same beacon put
  /// through `toMap()` (`dashboard_controller_impl.dart:1055`). Reading the typed
  /// side is what lets the two helpers below take `LayoutItem` for both callers —
  /// the live grid and a decoded envelope — instead of `List<dynamic>` because the
  /// two used to arrive in different shapes (#1310).
  List<LayoutItem> liveLayout(ProviderContainer container) =>
      container.read(uspSliverDashboardControllerProvider).layout.value;

  /// The geometry fields only. `moved` and friends are engine bookkeeping that
  /// flips on compaction, so comparing whole items would compare noise.
  List<Map<String, Object?>> geometryOf(List<LayoutItem> layout) => layout
      .map((item) => {
            'id': item.id,
            'x': item.x,
            'y': item.y,
            'w': item.w,
            'h': item.h,
            'minW': item.minW,
            'maxW': item.maxW,
          })
      .toList();

  LayoutItem itemNamed(List<LayoutItem> layout, String id) =>
      layout.firstWhere((item) => item.id == id);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ---------------------------------------------------------------------------
  // The regression this ticket is about
  // ---------------------------------------------------------------------------
  group('a save at one breakpoint cannot rewrite another', () {
    test('editing on mobile leaves the desktop layout byte-identical',
        () async {
      final first = await bootLayout();
      final desktopBefore = geometryOf(liveLayout(first));

      // Narrow the window to phone width, then do the one edit mobile allows:
      // make a card taller.
      first.read(uspSliverDashboardControllerProvider).setSlotCount(4);
      await first
          .read(uspSliverDashboardControllerProvider.notifier)
          .updateItemSize('device_info', 4, 5);
      first.dispose();

      final second = await rebootLayout();
      addTearDown(second.dispose);

      expect(
        geometryOf(liveLayout(second)),
        desktopBefore,
        reason: 'A phone edit rewrote the desktop grid. This is #1293: the '
            'desktop cards come back at mobile widths, with minW/maxW capped '
            'there too, so they cannot even be dragged back.',
      );
    });

    test('the mobile edit itself survives the reboot', () async {
      final first = await bootLayout();
      first.read(uspSliverDashboardControllerProvider).setSlotCount(4);
      await first
          .read(uspSliverDashboardControllerProvider.notifier)
          .updateItemSize('device_info', 4, 5);
      first.dispose();

      final second = await rebootLayout();
      addTearDown(second.dispose);
      final controller = second.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(4);

      expect(itemNamed(controller.layout.value, 'device_info').h, 5,
          reason: 'Per-breakpoint storage is only worth having if the '
              'breakpoint that was edited actually keeps its edit.');
    });

    test('a desktop resize does not disturb a stored mobile layout', () async {
      final first = await bootLayout();
      first.read(uspSliverDashboardControllerProvider).setSlotCount(4);
      await first
          .read(uspSliverDashboardControllerProvider.notifier)
          .updateItemSize('device_info', 4, 5);
      first.read(uspSliverDashboardControllerProvider).setSlotCount(12);
      await first
          .read(uspSliverDashboardControllerProvider.notifier)
          .updateItemSize('device_info', 8, 3);
      first.dispose();

      final envelope = await storedEnvelope();
      expect(itemNamed(envelope[4]!, 'device_info').h, 5);
      expect(itemNamed(envelope[4]!, 'device_info').w, 4);
      expect(itemNamed(envelope[12]!, 'device_info').w, 8);
      expect(itemNamed(envelope[12]!, 'device_info').h, 3);
    });

    test('saving repeatedly at mobile does not drift the desktop entry',
        () async {
      // Every save visits all three grids to read them out of the controller,
      // so a rounding or compaction wobble in that walk would creep the desktop
      // layout one row at a time across a session.
      final container = await bootLayout();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);

      container.read(uspSliverDashboardControllerProvider).setSlotCount(4);
      await notifier.saveLayout();
      final afterFirst = geometryOf((await storedEnvelope())[12]!);

      for (var i = 0; i < 3; i++) {
        await notifier.saveLayout();
      }

      expect(geometryOf((await storedEnvelope())[12]!), afterFirst);
    });

    test('the walk leaves the controller on the breakpoint it started on',
        () async {
      final container = await bootLayout();
      addTearDown(container.dispose);
      final controller = container.read(uspSliverDashboardControllerProvider);

      controller.setSlotCount(8);
      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .saveLayout();

      expect(controller.slotCount.value, 8,
          reason: 'Saving must not move the grid the user is looking at.');
    });
  });

  // ---------------------------------------------------------------------------
  // Mobile is height-and-order only
  // ---------------------------------------------------------------------------
  group('mobile pins every card full-width', () {
    test('the seeded mobile layout is a locked single column', () async {
      final container = await bootLayout();
      addTearDown(container.dispose);
      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(4);

      for (final item in controller.exportLayout()) {
        expect(item['x'], 0, reason: '${item['id']} is not at the left edge');
        expect(item['w'], 4, reason: '${item['id']} is not full-width');
        expect(item['minW'], 4,
            reason: '${item['id']} can still be shrunk: the package clamps a '
                'resize to [minW, maxW], so minW must equal the slot count');
        expect(item['maxW'], 4.0,
            reason: '${item['id']} can still be widened past the grid');
      }
    });

    test('a stored mobile layout with loose widths is re-locked on load',
        () async {
      // What every existing install has: a mobile entry written before the lock
      // (or derived by the old scaler, which left w=4 with maxW=3 — a width
      // already outside its own cap).
      final container = await bootLayout(initialValues: {
        pUspSliverDashboardLayout: UspLayoutEnvelope({
          12: [
            _item('stats_panel', w: 12, h: 1, minW: 6, maxW: 12),
            _item('device_info', y: 1, w: 6, h: 3, minW: 3, maxW: 8),
          ],
          4: [
            _item('stats_panel', w: 2, h: 1, minW: 2, maxW: 4),
            _item('device_info', x: 2, y: 1, w: 1, h: 3, minW: 1, maxW: 3),
          ],
        }).encode(),
      });
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(4);

      for (final item in controller.exportLayout()) {
        expect(item['w'], 4, reason: '${item['id']} kept a stale narrow width');
        expect(item['minW'], 4);
        expect(item['maxW'], 4.0);
      }
    });

    test('what we persist for mobile is locked too', () async {
      final container = await bootLayout();
      addTearDown(container.dispose);

      for (final item in (await storedEnvelope())[4]!) {
        expect(item.w, 4);
        expect(item.minW, 4);
      }
    });

    test('tablet keeps proportional widths — the lock is mobile-only',
        () async {
      final container = await bootLayout();
      addTearDown(container.dispose);
      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(8);

      final widths =
          controller.exportLayout().map((item) => item['w'] as int).toSet();
      expect(widths, isNot({8}),
          reason: 'Tablet is a two-column grid; pinning it full-width would '
              'throw away the pairing that #1293 is trying to protect.');
    });
  });

  // ---------------------------------------------------------------------------
  // Membership is global, geometry is per-grid
  // ---------------------------------------------------------------------------
  group('adding and removing cards reaches every breakpoint', () {
    test('removing a card on mobile removes it everywhere', () async {
      final container = await bootLayout();
      addTearDown(container.dispose);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(4);

      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .removeWidget('device_info');

      final envelope = await storedEnvelope();
      for (final slots in [12, 8, 4]) {
        expect(
          envelope[slots]!.map((item) => item.id),
          isNot(contains('device_info')),
          reason: 'device_info survived at $slots columns. Deleting a card on '
              'a phone must delete the card, not just its phone placement.',
        );
      }
    });

    test('adding a card on mobile gives desktop its desktop width', () async {
      final container = await bootLayout();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(4);
      await notifier.removeWidget('port_forwarding');

      await notifier.addWidget('port_forwarding');

      final envelope = await storedEnvelope();
      expect(itemNamed(envelope[4]!, 'port_forwarding').w, 4);
      expect(
        itemNamed(envelope[12]!, 'port_forwarding').w,
        greaterThan(4),
        reason: 'A card added while on a phone came back to desktop stuck at '
            'phone width — the package reconciles new items by carrying the '
            'current width across, so the notifier has to place it per grid.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Migration and recovery
  // ---------------------------------------------------------------------------
  group('reading what is already on disk', () {
    test('a legacy bare list loads as the desktop layout', () async {
      final container = await bootLayout(initialValues: {
        pUspSliverDashboardLayout: _legacyBareList([
          _item('stats_panel', w: 12, h: 1, minW: 6, maxW: 12),
          _item('device_info', y: 1, w: 6, h: 3, minW: 3, maxW: 8),
        ]),
      });
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.layout.value;
      expect(layout, hasLength(2));
      expect(itemNamed(layout, 'device_info').w, 6);
    });

    test('a legacy value is upgraded in place on the first save', () async {
      final container = await bootLayout(initialValues: {
        pUspSliverDashboardLayout: _legacyBareList([
          _item('device_info', w: 6, h: 3, minW: 3, maxW: 8),
        ]),
      });
      addTearDown(container.dispose);

      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .saveLayout();

      final envelope = await storedEnvelope();
      expect(envelope.slotCounts, containsAll([12, 8, 4]),
          reason: 'After one save the install should be fully migrated, so a '
              'later mobile visit has somewhere of its own to write.');
    });

    test('an unreadable pref falls back to the default and rewrites it',
        () async {
      final container = await bootLayout(initialValues: {
        pUspSliverDashboardLayout: '{"version": 99}',
      });
      addTearDown(container.dispose);

      expect(
          container.read(uspSliverDashboardControllerProvider).exportLayout(),
          hasLength(18));
      expect((await storedEnvelope()).slotCounts, containsAll([12, 8, 4]));
    });

    test('a mobile entry missing a card the desktop has re-derives it',
        () async {
      // The shape a partial migration leaves behind: desktop has been edited
      // since the mobile entry was written.
      final container = await bootLayout(initialValues: {
        pUspSliverDashboardLayout: UspLayoutEnvelope({
          12: [
            _item('stats_panel', w: 12, h: 1, minW: 6, maxW: 12),
            _item('device_info', y: 1, w: 6, h: 3, minW: 3, maxW: 8),
          ],
          4: [
            _item('stats_panel', w: 4, h: 1, minW: 4, maxW: 4),
          ],
        }).encode(),
      });
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(4);
      expect(
        controller.exportLayout().map((item) => item['id']),
        containsAll(['stats_panel', 'device_info']),
        reason: 'A card absent from the stored mobile entry must be scaled in, '
            'not dropped — and it must not then be reconciled *out* of the '
            'desktop layout on the way back up.',
      );

      controller.setSlotCount(12);
      expect(controller.exportLayout(), hasLength(2),
          reason: 'Returning to desktop must not lose a card because the '
              'mobile entry was stale.');
    });

    test('resetLayout re-seeds every breakpoint', () async {
      final container = await bootLayout();
      addTearDown(container.dispose);
      final controller = container.read(uspSliverDashboardControllerProvider);

      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .resetLayout();
      container.read(uspSliverDashboardControllerProvider).setSlotCount(8);

      final widths = container
          .read(uspSliverDashboardControllerProvider)
          .exportLayout()
          .map((item) => item['w'] as int)
          .toSet();
      expect(widths, isNot({8}),
          reason: 'After a reset the tablet cache is empty, so setSlotCount '
              'falls back to correctBounds, which only shifts items left '
              'without scaling — the two-column tablet grid collapses. '
              'resetLayout has to re-seed like init does.');
      expect(controller, isNotNull);
    });
  });
}

/// A pre-envelope pref value: the bare JSON list the app wrote before the
/// layouts were keyed by slot count.
///
/// `toMap()` is spelled here rather than in each caller because this is one of
/// the two shapes an item legitimately becomes bytes in — the other being
/// `UspLayoutEnvelope.encode()` — and #1310's whole claim is that those are the
/// only two. A fixture that reached for `jsonEncode(item)` directly would be
/// inventing a third.
String _legacyBareList(List<LayoutItem> items) =>
    jsonEncode([for (final item in items) item.toMap()]);

/// One grid item, in the shape the controller's own layout beacon holds.
LayoutItem _item(
  String id, {
  int x = 0,
  int y = 0,
  int w = 6,
  int h = 3,
  int minW = 3,
  double maxW = 8.0,
  int minH = 1,
  double maxH = 8.0,
}) =>
    LayoutItem(
      id: id,
      x: x,
      y: y,
      w: w,
      h: h,
      minW: minW,
      maxW: maxW,
      minH: minH,
      maxH: maxH,
    );
