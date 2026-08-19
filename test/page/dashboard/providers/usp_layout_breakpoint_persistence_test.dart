import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
///    (`dashboard_controller_impl.dart`), so pinning those two *is* the lock.
///
/// Membership is deliberately **not** per-breakpoint: deleting a card on a phone
/// deletes the card, not just its phone placement. Only geometry is per-grid.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Wait for the notifier's async init/save chains to settle.
  Future<void> pumpAsync() => Future.delayed(const Duration(milliseconds: 100));

  Future<ProviderContainer> boot({
    Map<String, Object>? initialValues,
  }) async {
    if (initialValues != null) {
      SharedPreferences.setMockInitialValues(initialValues);
    }
    final container = ProviderContainer();
    container.read(uspSliverDashboardControllerProvider);
    await pumpAsync();
    return container;
  }

  /// Reboots the app against whatever is already in the mock pref store — the
  /// "close the tab and come back on a laptop" path.
  Future<ProviderContainer> reboot() async {
    final container = ProviderContainer();
    container.read(uspSliverDashboardControllerProvider);
    await pumpAsync();
    return container;
  }

  Future<UspLayoutEnvelope> storedEnvelope() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(pUspSliverDashboardLayout);
    expect(raw, isNotNull, reason: 'Nothing was persisted.');
    final envelope = UspLayoutEnvelope.tryDecode(raw!);
    expect(envelope, isNotNull, reason: 'Persisted value is unreadable: $raw');
    return envelope!;
  }

  /// The geometry keys only. `moved` and friends are engine bookkeeping that
  /// flips on compaction, so comparing whole maps would compare noise.
  List<Map<String, Object?>> geometryOf(List<dynamic> layout) => layout
      .map((item) => {
            for (final k in ['id', 'x', 'y', 'w', 'h', 'minW', 'maxW'])
              k: (item as Map)[k],
          })
      .toList();

  Map<String, Object?> itemNamed(List<dynamic> layout, String id) =>
      (layout.firstWhere((item) => (item as Map)['id'] == id) as Map)
          .cast<String, Object?>();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ---------------------------------------------------------------------------
  // The regression this ticket is about
  // ---------------------------------------------------------------------------
  group('a save at one breakpoint cannot rewrite another', () {
    test('editing on mobile leaves the desktop layout byte-identical',
        () async {
      final first = await boot();
      final desktopBefore = geometryOf(
          first.read(uspSliverDashboardControllerProvider).exportLayout());

      // Narrow the window to phone width, then do the one edit mobile allows:
      // make a card taller.
      first.read(uspSliverDashboardControllerProvider).setSlotCount(4);
      await first
          .read(uspSliverDashboardControllerProvider.notifier)
          .updateItemSize('device_info', 4, 5);
      first.dispose();

      final second = await reboot();
      addTearDown(second.dispose);

      expect(
        geometryOf(
            second.read(uspSliverDashboardControllerProvider).exportLayout()),
        desktopBefore,
        reason: 'A phone edit rewrote the desktop grid. This is #1293: the '
            'desktop cards come back at mobile widths, with minW/maxW capped '
            'there too, so they cannot even be dragged back.',
      );
    });

    test('the mobile edit itself survives the reboot', () async {
      final first = await boot();
      first.read(uspSliverDashboardControllerProvider).setSlotCount(4);
      await first
          .read(uspSliverDashboardControllerProvider.notifier)
          .updateItemSize('device_info', 4, 5);
      first.dispose();

      final second = await reboot();
      addTearDown(second.dispose);
      final controller = second.read(uspSliverDashboardControllerProvider);
      controller.setSlotCount(4);

      expect(itemNamed(controller.exportLayout(), 'device_info')['h'], 5,
          reason: 'Per-breakpoint storage is only worth having if the '
              'breakpoint that was edited actually keeps its edit.');
    });

    test('a desktop resize does not disturb a stored mobile layout', () async {
      final first = await boot();
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
      expect(itemNamed(envelope[4]!, 'device_info')['h'], 5);
      expect(itemNamed(envelope[4]!, 'device_info')['w'], 4);
      expect(itemNamed(envelope[12]!, 'device_info')['w'], 8);
      expect(itemNamed(envelope[12]!, 'device_info')['h'], 3);
    });

    test('saving repeatedly at mobile does not drift the desktop entry',
        () async {
      // Every save visits all three grids to read them out of the controller,
      // so a rounding or compaction wobble in that walk would creep the desktop
      // layout one row at a time across a session.
      final container = await boot();
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
      final container = await boot();
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
      final container = await boot();
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
      final container = await boot(initialValues: {
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
      final container = await boot();
      addTearDown(container.dispose);

      for (final item in (await storedEnvelope())[4]!) {
        expect((item as Map)['w'], 4);
        expect(item['minW'], 4);
      }
    });

    test('tablet keeps proportional widths — the lock is mobile-only',
        () async {
      final container = await boot();
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
      final container = await boot();
      addTearDown(container.dispose);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(4);

      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .removeWidget('device_info');

      final envelope = await storedEnvelope();
      for (final slots in [12, 8, 4]) {
        expect(
          envelope[slots]!.map((item) => (item as Map)['id']),
          isNot(contains('device_info')),
          reason: 'device_info survived at $slots columns. Deleting a card on '
              'a phone must delete the card, not just its phone placement.',
        );
      }
    });

    test('adding a card on mobile gives desktop its desktop width', () async {
      final container = await boot();
      addTearDown(container.dispose);
      final notifier =
          container.read(uspSliverDashboardControllerProvider.notifier);
      container.read(uspSliverDashboardControllerProvider).setSlotCount(4);
      await notifier.removeWidget('port_forwarding');

      await notifier.addWidget('port_forwarding');

      final envelope = await storedEnvelope();
      expect(itemNamed(envelope[4]!, 'port_forwarding')['w'], 4);
      expect(
        itemNamed(envelope[12]!, 'port_forwarding')['w'],
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
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: jsonEncode([
          _item('stats_panel', w: 12, h: 1, minW: 6, maxW: 12),
          _item('device_info', y: 1, w: 6, h: 3, minW: 3, maxW: 8),
        ]),
      });
      addTearDown(container.dispose);

      final controller = container.read(uspSliverDashboardControllerProvider);
      final layout = controller.exportLayout();
      expect(layout, hasLength(2));
      expect(itemNamed(layout, 'device_info')['w'], 6);
    });

    test('a legacy value is upgraded in place on the first save', () async {
      final container = await boot(initialValues: {
        pUspSliverDashboardLayout: jsonEncode([
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
      final container = await boot(initialValues: {
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
      final container = await boot(initialValues: {
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
      final container = await boot();
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

/// A layout item map in the shape `exportLayout()` produces.
Map<String, dynamic> _item(
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
    {
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
