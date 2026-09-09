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
    /// One item, with the caps given as `int?` so a test can ask for *no* cap
    /// and get [double.infinity] the way [LayoutItem] itself defaults it.
    List<LayoutItem> _singleItemLayout({
      int x = 0,
      int y = 0,
      int w = 6,
      int h = 3,
      int minW = 3,
      int? maxW = 8,
    }) {
      return [
        LayoutItem(
          id: 'test',
          x: x,
          y: y,
          w: w,
          h: h,
          minW: minW,
          maxW: maxW?.toDouble() ?? double.infinity,
        )
      ];
    }

    LayoutItem _first(List<LayoutItem> layout) => layout.first;

    test('tablet 12→8: w=6 → w=4', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(w: 6),
        12,
        8,
      );
      expect(_first(result).w, 4);
    });

    test('tablet 12→8: w=12 → w=8', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(w: 12, minW: 6, maxW: 12),
        12,
        8,
      );
      expect(_first(result).w, 8);
    });

    test('mobile 12→4: forces full-width', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(w: 6, x: 6),
        12,
        4,
      );
      expect(_first(result).w, 4);
    });

    test('mobile 12→4: forces x=0', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(x: 6),
        12,
        4,
      );
      expect(_first(result).x, 0);
    });

    test('scales minW proportionally', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(minW: 3),
        12,
        8,
      );
      // 3 * 8 / 12 = 2
      expect(_first(result).minW, 2);
    });

    test('scales maxW proportionally', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(maxW: 8),
        12,
        8,
      );
      // 8 * 8 / 12 = 5.33 → 5
      expect(_first(result).maxW.toInt(), 5);
    });

    // There used to be a 'maxW is stored as double' test here. It was asserting
    // `isA<double>()` on a map value, because the map form could hold an `int`
    // there and `LayoutItem.fromMap`'s `as num?` would have accepted it —
    // silently, then compared it against doubles elsewhere. `LayoutItem.maxW` is
    // declared `double`, so the claim is now the compiler's and a test for it
    // could only ever pass (#1310).

    test('an unbounded cap scales to the whole target grid', () {
      // The `Infinity.toInt()` trap, from the other side. `maxW` defaults to
      // [double.infinity] and only `toMap()` turns that into the `null` the map
      // form read as "absent"; handed a live item — which is every item on the
      // grid — the old `(map['maxW'] as num?)?.toInt() ?? fromCols` matched the
      // infinity and threw `Unsupported operation: Infinity or NaN toInt`
      // (#1310).
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(w: 6, minW: 1, maxW: null),
        12,
        8,
      );
      expect(_first(result).maxW, 8.0);
    });

    test('clamps minW to at least 1', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(minW: 1),
        12,
        4,
      );
      expect(_first(result).minW, greaterThanOrEqualTo(1));
    });

    test('clamps maxW to toCols', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(maxW: 12),
        12,
        4,
      );
      expect(_first(result).maxW.toInt(), lessThanOrEqualTo(4));
    });

    test('overflow correction shifts x left when newX+newW > toCols', () {
      // x=10, w=4 on 12 cols → scale to 8: newX~7, newW~3 → 7+3=10 > 8
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(x: 10, w: 4, minW: 1, maxW: 12),
        12,
        8,
      );
      final item = _first(result);
      expect(item.x + item.w, lessThanOrEqualTo(8));
    });

    test('underflow correction forces full-width when newX < 0', () {
      // Edge case: items that would result in negative x after correction
      // x=11, w=2 on 12 → scale to 8: newX~7, newW~1 → should fit
      // But test the code path by creating extreme case
      final layout = [
        LayoutItem(
          id: 'test',
          x: 11,
          y: 0,
          w: 3,
          h: 2,
          minW: 1,
          maxW: 12,
        )
      ];
      final result = UspWidgetSpecs.scaleLayout(layout, 12, 8);
      final item = _first(result);
      expect(item.x, greaterThanOrEqualTo(0));
      expect(item.x + item.w, lessThanOrEqualTo(8));
    });

    test('preserves y, h, and id', () {
      final result = UspWidgetSpecs.scaleLayout(
        _singleItemLayout(y: 5, h: 4),
        12,
        8,
      );
      final item = _first(result);
      expect(item.y, 5);
      expect(item.h, 4);
      expect(item.id, 'test');
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

  // ---------------------------------------------------------------------------
  // Which cards exist is global; only their geometry is per grid (#1293)
  //
  // `alignMembership` is the join between those two rules, and until #1310 it had
  // no tests of its own — it was covered only through the controller, where a
  // failure arrives as a card missing from a breakpoint nobody rendered. Its two
  // lines make four separate promises, so each is staked here where the inputs
  // are visible.
  //
  // Mutation table — each row is one edit to the two-line body:
  //
  //   | # | mutation | killed by |
  //   |---|----------|-----------|
  //   | 1 | return `refItem` unscaled instead of `scaleLayout([refItem], ...)` | 2 — the missing-card test and the empty-grid one |
  //   | 2 | `scaleLayout(reference, ...)`, dropping the `stored` lookup | 1 — the keeps-its-own-geometry test, and only that one |
  //   | 3 | iterate `layout` filtered by the reference's ids, instead of `reference` | 3 — missing-card, order, empty-grid |
  //   | 4 | union: the reference's cards *plus* the ones only `layout` has | 1 — the dropped-card test, and only that one |
  //
  // Rows 2 and 4 are each killed by exactly one test, which is why neither of
  // those two is redundant with the others: without row 2's the stored geometry
  // could be thrown away silently, and without row 4's a deleted card could come
  // back on the grids nobody was looking at.
  // ---------------------------------------------------------------------------
  group('alignMembership', () {
    LayoutItem at(String id, {int x = 0, int w = 6, int h = 3}) =>
        LayoutItem(id: id, x: x, y: 0, w: w, h: h, minW: 3, maxW: 8.0);

    test('a card the stored grid is missing is scaled in from the reference',
        () {
      final aligned = UspWidgetSpecs.alignMembership(
        [at('device_info', w: 4)],
        [at('device_info', w: 6), at('lan_info', w: 6)],
        fromCols: 12,
        toCols: 8,
      );

      expect(aligned.map((i) => i.id), ['device_info', 'lan_info']);
      expect(aligned.last.w, 4,
          reason: 'the added card arrives at the target grid\'s width, not the '
              'reference\'s 6 of 12 — passing it through unscaled is what makes '
              'a desktop card overflow an 8-column grid');
    });

    test('a card the stored grid already has keeps its own geometry', () {
      // The whole point of storing per breakpoint: this card was resized on the
      // 8-column grid, and the reference is the 12-column one. Re-deriving it
      // would silently discard the user's edit.
      final aligned = UspWidgetSpecs.alignMembership(
        [at('device_info', x: 2, w: 5, h: 7)],
        [at('device_info', w: 6)],
        fromCols: 12,
        toCols: 8,
      );

      expect([aligned.single.x, aligned.single.w, aligned.single.h], [2, 5, 7]);
    });

    test('a card the reference dropped is dropped here too', () {
      // Deleting a card on a phone deletes the card. The stored grid is the
      // stale side, so an entry it still holds is not evidence the card exists.
      final aligned = UspWidgetSpecs.alignMembership(
        [at('device_info'), at('lan_info')],
        [at('device_info')],
        fromCols: 12,
        toCols: 8,
      );

      expect(aligned.map((i) => i.id), ['device_info']);
    });

    test('the order is the reference\'s, not the stored grid\'s', () {
      // Not cosmetic: `setSlotCount` reconciles the grid it is leaving against
      // the one it is entering, and the package matches by position when it
      // places items it does not recognise.
      final aligned = UspWidgetSpecs.alignMembership(
        [at('lan_info'), at('device_info')],
        [at('device_info'), at('lan_info')],
        fromCols: 12,
        toCols: 8,
      );

      expect(aligned.map((i) => i.id), ['device_info', 'lan_info']);
    });

    test('an empty stored grid is the whole reference, scaled', () {
      // What a fresh breakpoint looks like — nothing stored yet — and the path
      // that must not return an empty grid.
      final aligned = UspWidgetSpecs.alignMembership(
        const [],
        [at('device_info', w: 6), at('lan_info', x: 6, w: 6)],
        fromCols: 12,
        toCols: 8,
      );

      expect(aligned.map((i) => i.id), ['device_info', 'lan_info']);
      expect(aligned.map((i) => i.w), everyElement(4));
    });
  });

  // ---------------------------------------------------------------------------
  // The phone width lock is now these four fields and nothing else (#1399)
  //
  // It used to be two mechanisms: this pin, plus `lockItemsToFullWidth`
  // rewriting the live layout from a beacon listener whenever a left-hand resize
  // handle got past the pin. `sliver_dashboard` 2.6.0 clamps `x` against the
  // caps as well as `w`, so the corrector became unreachable and was deleted
  // along with its seven tests. What is left is a pure projection, and every
  // guarantee the phone grid makes about width now rests on the map it returns
  // — hence a group of its own, where the deleted one used to be.
  //
  // The gesture half of the proof is `edit_mode_interactions_test.dart`, which
  // drags both families on a real 4-column page and samples every frame. These
  // tests only pin what that page is handed.
  // ---------------------------------------------------------------------------
  group('lockToFullWidth', () {
    List<LayoutItem> oneCard({
      int x = 0,
      int y = 0,
      int w = 4,
      int h = 2,
      int minW = 1,
      num maxW = 4,
      int minH = 1,
      num maxH = 6,
    }) =>
        [
          LayoutItem(
            id: 'a',
            x: x,
            y: y,
            w: w,
            h: h,
            minW: minW,
            maxW: maxW.toDouble(),
            minH: minH,
            maxH: maxH.toDouble(),
          )
        ];

    LayoutItem firstOf(List<LayoutItem> layout) => layout.first;

    test('all four width fields collapse onto the grid width', () {
      // Asserted together rather than one per test: it is the *combination*
      // that the 2.6.0 resolver reads. `w` inside `[minW, maxW]` bounds the
      // right-hand handles, and `x` inside `[right - maxW, right - minW]` — a
      // single point once the caps are equal — bounds the left-hand ones.
      // Any one of the four alone leaves a handle live.
      //
      // The `4` / `4.0` asymmetry is now the field types themselves — `int minW`,
      // `double maxW` (`layout_item.dart:233,239`) — rather than documentation
      // about what a map could hold. It used to be the latter: `4 == 4.0` in
      // Dart, so either literal passed, and the note here had to explain that
      // `fromMap`'s `(map['maxW'] as num?)?.toDouble()` would coerce whichever
      // one was stored. #1310 makes the wrong one a compile error.
      final item = firstOf(UspWidgetSpecs.lockToFullWidth(oneCard(), 4));
      expect([item.x, item.w, item.minW, item.maxW], [0, 4, 4, 4.0]);
    });

    test('a card the previous grid left displaced is pinned too', () {
      // x=1, w=3 is what a left-edge drag produced at 0.9.1, and it is also
      // what a stored 2.3.1-era layout can still hold. The pin is applied on
      // every import, so a layout that predates the lock is repaired by being
      // read rather than needing a migration.
      final item =
          firstOf(UspWidgetSpecs.lockToFullWidth(oneCard(x: 1, w: 3), 4));
      expect([item.x, item.w], [0, 4]);
    });

    test('a scaled maxW below the width is raised, not left to snap', () {
      // Scaling 12→4 gives a card with `maxW: 8` a maxW of 3 while its width is
      // set to 4 — a width outside its own cap, which the first resize would
      // have snapped down to 3 of 4 columns.
      final item = firstOf(UspWidgetSpecs.lockToFullWidth(oneCard(maxW: 3), 4));
      expect(item.maxW, 4.0);
    });

    test('a desktop maxW wider than the phone grid is brought down', () {
      // The other side of the same clamp, and the commoner one: a stored
      // 12-column entry read at 4 columns arrives with `maxW: 12`. Left there,
      // `x` may range over `[right - 12, right - minW]` and the left handle is
      // free again — the leak this ticket had to keep closed, so it is asserted
      // rather than left to the equality in the first test.
      final item =
          firstOf(UspWidgetSpecs.lockToFullWidth(oneCard(maxW: 12), 4));
      expect(item.maxW, 4.0);
    });

    test('a spec minW wider than the phone grid is lowered', () {
      // Not cosmetic: `minW: 6` on a 4-column grid trips the engine's own
      // `currentL.minW <= cols` assertion (`layout_engine.dart:963`) while the
      // page is building, so a projection that lowered only `w` would crash
      // rather than mis-size.
      final item = firstOf(UspWidgetSpecs.lockToFullWidth(oneCard(minW: 6), 4));
      expect(item.minW, 4);
    });

    test('the height is left to the user, bounds and all', () {
      final item = firstOf(UspWidgetSpecs.lockToFullWidth(
        oneCard(y: 5, h: 3, minH: 2, maxH: 6),
        4,
      ));
      expect([item.y, item.h, item.minH, item.maxH], [5, 3, 2, 6]);
    });

    test('an 8-column grid gets the 8-column pin', () {
      // The helper takes `cols` rather than reading a breakpoint, and the tablet
      // grid does not use it — this is here so that a hard-coded 4 in the
      // implementation cannot pass.
      final item = firstOf(UspWidgetSpecs.lockToFullWidth(oneCard(w: 3), 8));
      expect([item.w, item.minW, item.maxW], [8, 8, 8.0]);
    });

    test('fields the lock has no opinion about survive', () {
      final locked = UspWidgetSpecs.lockToFullWidth([
        LayoutItem(id: 'a', x: 1, y: 0, w: 3, h: 2, isStatic: true)
      ], 4);
      expect(firstOf(locked).id, 'a');
      expect(firstOf(locked).isStatic, isTrue);
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
