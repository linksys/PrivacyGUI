import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  group('Registry', () {
    test('all has 18 specs', () {
      // speedTest disabled (#857)
      expect(UspWidgetSpecs.all.length, 18);
    });

    test('all IDs are unique', () {
      final ids = UspWidgetSpecs.all.map((s) => s.id).toSet();
      expect(ids.length, 18);
    });

    test('all displayNames are unique', () {
      final names = UspWidgetSpecs.all.map((s) => s.displayName).toSet();
      expect(names.length, 18);
    });

    test('all specs have DisplayMode.normal constraints', () {
      for (final spec in UspWidgetSpecs.all) {
        expect(
          spec.constraints[DisplayMode.normal],
          isNotNull,
          reason: '${spec.id} missing normal constraints',
        );
      }
    });

    test('non-hideable cards: stats_panel, device_info, network_status', () {
      final nonHideable =
          UspWidgetSpecs.all.where((s) => !s.canHide).map((s) => s.id).toSet();
      expect(nonHideable,
          containsAll(['stats_panel', 'device_info', 'network_status']));
    });
  });

  group('getById', () {
    test('returns spec for valid ID', () {
      final spec = UspWidgetSpecs.getById('stats_panel');
      expect(spec, isNotNull);
      expect(spec!.id, 'stats_panel');
    });

    test('returns null for unknown ID', () {
      expect(UspWidgetSpecs.getById('invalid_id'), isNull);
    });

    test('case-sensitive lookup', () {
      expect(UspWidgetSpecs.getById('Stats_Panel'), isNull);
    });
  });

  group('scaleLayout', () {
    List<dynamic> _singleItemLayout({
      int x = 0,
      int y = 0,
      int w = 6,
      int h = 3,
      int minW = 3,
      int maxW = 8,
    }) {
      return [
        {
          'id': 'test',
          'x': x,
          'y': y,
          'w': w,
          'h': h,
          'minW': minW,
          'maxW': maxW,
        }
      ];
    }

    Map<String, dynamic> _first(List<dynamic> layout) =>
        layout.first as Map<String, dynamic>;

    test('tablet 12→8: w=6 → w=4', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(w: 6),
        12,
        8,
      );
      expect(_first(result)['w'], 4);
    });

    test('tablet 12→8: w=12 → w=8', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(w: 12, minW: 6, maxW: 12),
        12,
        8,
      );
      expect(_first(result)['w'], 8);
    });

    test('mobile 12→4: forces full-width', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(w: 6, x: 6),
        12,
        4,
      );
      expect(_first(result)['w'], 4);
    });

    test('mobile 12→4: forces x=0', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(x: 6),
        12,
        4,
      );
      expect(_first(result)['x'], 0);
    });

    test('scales minW proportionally', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(minW: 3),
        12,
        8,
      );
      // 3 * 8 / 12 = 2
      expect(_first(result)['minW'], 2);
    });

    test('scales maxW proportionally', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(maxW: 8),
        12,
        8,
      );
      // 8 * 8 / 12 = 5.33 → 5
      final maxW = (_first(result)['maxW'] as num).toInt();
      expect(maxW, 5);
    });

    test('maxW is stored as double', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(),
        12,
        8,
      );
      expect(_first(result)['maxW'], isA<double>());
    });

    test('clamps minW to at least 1', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(minW: 1),
        12,
        4,
      );
      expect(_first(result)['minW'], greaterThanOrEqualTo(1));
    });

    test('clamps maxW to toCols', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(maxW: 12),
        12,
        4,
      );
      final maxW = (_first(result)['maxW'] as num).toInt();
      expect(maxW, lessThanOrEqualTo(4));
    });

    test('overflow correction shifts x left when newX+newW > toCols', () {
      // x=10, w=4 on 12 cols → scale to 8: newX~7, newW~3 → 7+3=10 > 8
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(x: 10, w: 4, minW: 1, maxW: 12),
        12,
        8,
      );
      final item = _first(result);
      expect((item['x'] as int) + (item['w'] as int), lessThanOrEqualTo(8));
    });

    test('underflow correction forces full-width when newX < 0', () {
      // Edge case: items that would result in negative x after correction
      // x=11, w=2 on 12 → scale to 8: newX~7, newW~1 → should fit
      // But test the code path by creating extreme case
      final layout = [
        {
          'id': 'test',
          'x': 11,
          'y': 0,
          'w': 3,
          'h': 2,
          'minW': 1,
          'maxW': 12,
        }
      ];
      final result = UspWidgetSpecs.scaleLayout(layout, 12, 8);
      final item = _first(result);
      expect(item['x'], greaterThanOrEqualTo(0));
      expect(
        (item['x'] as int) + (item['w'] as int),
        lessThanOrEqualTo(8),
      );
    });

    test('preserves y, h, and id', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(y: 5, h: 4),
        12,
        8,
      );
      final item = _first(result);
      expect(item['y'], 5);
      expect(item['h'], 4);
      expect(item['id'], 'test');
    });
  });

  group('createDefaultLayout', () {
    test('returns 18 items', () {
      // speedTest disabled (#857)
      final layout = UspWidgetSpecs.createDefaultLayout();
      expect(layout.length, 18);
    });

    test('stats_panel is first and full-width', () {
      final layout = UspWidgetSpecs.createDefaultLayout();
      expect(layout.first.id, 'stats_panel');
      expect(layout.first.x, 0);
      expect(layout.first.w, 12);
      expect(layout.first.y, 0);
    });

    test('remaining items in 6-col pairs', () {
      final layout = UspWidgetSpecs.createDefaultLayout();
      // Skip stats_panel (first item)
      for (int i = 1; i < layout.length; i++) {
        expect(
          layout[i].w,
          6,
          reason: '${layout[i].id} should have w=6',
        );
        expect(
          layout[i].x == 0 || layout[i].x == 6,
          isTrue,
          reason: '${layout[i].id} x should be 0 or 6, got ${layout[i].x}',
        );
      }
    });

    test('y positions accumulate without overlaps', () {
      final layout = UspWidgetSpecs.createDefaultLayout();
      // Check that y values are non-decreasing for left-column items
      int lastY = -1;
      for (final item in layout) {
        if (item.x == 0) {
          expect(
            item.y,
            greaterThanOrEqualTo(lastY),
            reason: '${item.id} y=${item.y} should >= $lastY',
          );
          lastY = item.y;
        }
      }
    });

    test('all IDs match UspWidgetSpecs.all', () {
      final layout = UspWidgetSpecs.createDefaultLayout();
      final layoutIds = layout.map((item) => item.id).toSet();
      final specIds = UspWidgetSpecs.all.map((s) => s.id).toSet();
      expect(layoutIds, equals(specIds));
    });
  });

  group('createLayoutForCards', () {
    test('empty list returns empty', () {
      final layout = UspWidgetSpecs.createLayoutForCards([]);
      expect(layout, isEmpty);
    });

    test('single non-stats card at y=0', () {
      final layout = UspWidgetSpecs.createLayoutForCards(['device_info']);
      expect(layout.length, 1);
      expect(layout.first.y, 0);
      expect(layout.first.w, 6);
    });

    test('stats_panel always full-width when present', () {
      final layout = UspWidgetSpecs.createLayoutForCards([
        'stats_panel',
        'device_info',
      ]);
      final statsPanel = layout.firstWhere((i) => i.id == 'stats_panel');
      expect(statsPanel.w, 12);
    });

    test('stats_panel at y=0 when present', () {
      final layout = UspWidgetSpecs.createLayoutForCards([
        'device_info',
        'stats_panel',
      ]);
      final statsPanel = layout.firstWhere((i) => i.id == 'stats_panel');
      expect(statsPanel.y, 0);
    });

    test('odd number of remaining cards handled', () {
      final layout = UspWidgetSpecs.createLayoutForCards([
        'stats_panel',
        'device_info',
        'topology',
        'lan_info',
      ]);
      // stats_panel (full) + 3 remaining → 2 pairs (1 full pair + 1 alone)
      expect(layout.length, 4);
    });

    test('unknown cardId skipped', () {
      final layout = UspWidgetSpecs.createLayoutForCards([
        'device_info',
        'nonexistent_widget',
        'topology',
      ]);
      final ids = layout.map((i) => i.id).toSet();
      expect(ids.contains('nonexistent_widget'), isFalse);
    });

    test('pair row height = max of pair', () {
      // device_info h=3, topology h=5 → y should advance by 5 (not 3)
      final layout = UspWidgetSpecs.createLayoutForCards([
        'device_info',
        'topology',
        'lan_info',
      ]);
      final lanInfo = layout.firstWhere((i) => i.id == 'lan_info');
      final deviceInfo = layout.firstWhere((i) => i.id == 'device_info');
      final topology = layout.firstWhere((i) => i.id == 'topology');
      final maxH = deviceInfo.h > topology.h ? deviceInfo.h : topology.h;
      expect(lanInfo.y, deviceInfo.y + maxH);
    });

    test('stats_panel + 1 card produces 2 items', () {
      final layout = UspWidgetSpecs.createLayoutForCards([
        'stats_panel',
        'device_info',
      ]);
      expect(layout.length, 2);
    });

    test('stats_panel + 2 cards produces 3 items', () {
      final layout = UspWidgetSpecs.createLayoutForCards([
        'stats_panel',
        'device_info',
        'network_status',
      ]);
      expect(layout.length, 3);
    });

    test('all 18 cards layout matches createDefaultLayout', () {
      final allIds = UspWidgetSpecs.all.map((s) => s.id).toList();
      final fromCards = UspWidgetSpecs.createLayoutForCards(allIds);
      final defaultLayout = UspWidgetSpecs.createDefaultLayout();
      expect(fromCards.length, defaultLayout.length);
      for (int i = 0; i < fromCards.length; i++) {
        expect(fromCards[i].id, defaultLayout[i].id);
        expect(fromCards[i].x, defaultLayout[i].x);
        expect(fromCards[i].y, defaultLayout[i].y);
      }
    });

    test('subset of 6 cards produces correct items', () {
      final ids = UspDashboardPresetIds.essential;
      final layout = UspWidgetSpecs.createLayoutForCards(ids);
      final layoutIds = layout.map((i) => i.id).toSet();
      expect(
          layoutIds,
          containsAll(ids.where(
            (id) => UspWidgetSpecs.getById(id) != null,
          )));
    });

    test('respects input order for left-right placement', () {
      final layout = UspWidgetSpecs.createLayoutForCards([
        'device_info',
        'network_status',
      ]);
      expect(layout[0].id, 'device_info');
      expect(layout[0].x, 0);
      expect(layout[1].id, 'network_status');
      expect(layout[1].x, 6);
    });
  });

  // ---------------------------------------------------------------------------
  // Constraints are written for 12 columns and have to be read on the grid the
  // user is actually looking at (#1293).
  // ---------------------------------------------------------------------------
  group('scaleSpan', () {
    test('halves nothing on the grid it was written for', () {
      expect(UspWidgetSpecs.scaleSpan(6, fromCols: 12, toCols: 12), 6);
    });

    test('12→8 keeps the proportion', () {
      expect(UspWidgetSpecs.scaleSpan(6, fromCols: 12, toCols: 8), 4);
      expect(UspWidgetSpecs.scaleSpan(12, fromCols: 12, toCols: 8), 8);
    });

    test('never scales a card out of existence', () {
      // 1 of 12 rounds to 0 of 4, which is not a width any grid can hold.
      expect(UspWidgetSpecs.scaleSpan(1, fromCols: 12, toCols: 4), 1);
    });

    test('never returns more columns than the grid has', () {
      expect(UspWidgetSpecs.scaleSpan(12, fromCols: 8, toCols: 4), 4);
    });
  });

  group('correctedSize', () {
    // stats_panel: the widest floor in the catalogue, and the reason this
    // scaling has to exist at all.
    const wide = WidgetGridConstraints(
      minColumns: 6,
      maxColumns: 12,
      preferredColumns: 12,
      heightStrategy: HeightStrategy.strict(1),
      minHeightRows: 1,
      maxHeightRows: 2,
    );

    test('a size within its spec needs no correction', () {
      expect(
        UspWidgetSpecs.correctedSize(wide, w: 8, h: 1, slotCount: 12),
        isNull,
      );
    });

    test('a too-narrow card is widened to its floor', () {
      expect(
        UspWidgetSpecs.correctedSize(wide, w: 3, h: 1, slotCount: 12),
        (w: 6, h: 1),
      );
    });

    test('on a tablet the floor is scaled, not taken literally', () {
      // The bug: `minColumns: 6` enforced as-is gives this card six of the
      // tablet's eight columns — three quarters of the row for what is supposed
      // to be a half-width floor.
      expect(
        UspWidgetSpecs.correctedSize(wide, w: 2, h: 1, slotCount: 8),
        (w: 4, h: 1),
      );
    });

    test('on a tablet the ceiling is scaled too', () {
      expect(
        UspWidgetSpecs.correctedSize(wide, w: 9, h: 1, slotCount: 8),
        (w: 8, h: 1),
      );
    });

    test('a phone never has a width corrected onto it', () {
      // Taken literally the floor is wider than the whole grid, so the old code
      // wrote w=6 into a 4-column layout. Mobile widths are pinned by
      // lockToFullWidth, so there is nothing here to enforce.
      expect(
        UspWidgetSpecs.correctedSize(wide, w: 4, h: 1, slotCount: 4),
        isNull,
      );
    });

    test('a phone still has its height corrected', () {
      expect(
        UspWidgetSpecs.correctedSize(wide, w: 4, h: 5, slotCount: 4),
        (w: 4, h: 2),
      );
    });

    test('rows are absolute — the height floor is not scaled', () {
      expect(
        UspWidgetSpecs.correctedSize(wide, w: 8, h: 0, slotCount: 8),
        (w: 8, h: 1),
      );
    });
  });

  group('lockItemsToFullWidth', () {
    const full = LayoutItem(id: 'a', x: 0, y: 0, w: 4, h: 2);

    test('a locked layout needs no rewrite', () {
      // Null, not an equal list: the caller is a listener on the very layout it
      // would be writing back into.
      expect(UspWidgetSpecs.lockItemsToFullWidth([full], 4), isNull);
    });

    test('a card the left edge displaced is put back', () {
      // x=1, w=3 is what dragging the left edge inwards by a column leaves.
      final locked = UspWidgetSpecs.lockItemsToFullWidth(
        [full.copyWith(x: 1, w: 3)],
        4,
      );
      expect(locked, isNotNull);
      expect(locked!.single.x, 0);
      expect(locked.single.w, 4);
    });

    test('a card narrowed without moving is put back too', () {
      // Dragging the same edge outwards keeps x at 0 — the row's own edge does
      // the trimming instead — so a displaced x cannot be the thing looked for.
      final locked = UspWidgetSpecs.lockItemsToFullWidth(
        [full.copyWith(w: 3)],
        4,
      );
      expect(locked, isNotNull);
      expect(locked!.single.w, 4);
    });

    test('a card moved without narrowing is put back too', () {
      final locked = UspWidgetSpecs.lockItemsToFullWidth(
        [full.copyWith(x: 1)],
        4,
      );
      expect(locked, isNotNull);
      expect(locked!.single.x, 0);
    });

    test('the height is not the width lock\'s business', () {
      final locked = UspWidgetSpecs.lockItemsToFullWidth(
        [full.copyWith(x: 1, w: 3, h: 7)],
        4,
      );
      expect(locked!.single.h, 7);
    });

    test('the row a card sits on is not the width lock\'s business', () {
      final locked = UspWidgetSpecs.lockItemsToFullWidth(
        [full.copyWith(x: 1, w: 3, y: 5)],
        4,
      );
      expect(locked!.single.y, 5);
    });

    test('cards that are already locked keep their identity', () {
      final displaced = full.copyWith(id: 'b', x: 1, w: 3);
      final locked = UspWidgetSpecs.lockItemsToFullWidth([full, displaced], 4);
      expect(identical(locked!.first, full), isTrue);
      expect(locked.last.x, 0);
    });
  });
}

/// Helper to access preset card IDs without importing the preset model.
abstract class UspDashboardPresetIds {
  static const essential = [
    'stats_panel',
    'device_info',
    'network_status',
    'lan_info',
    'connected_devices',
    'wifi_status',
  ];
}
