import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart' show LayoutItem;

/// #1299 — the inversion, at the seam where a stored pick becomes geometry.
///
/// #1232 runs **width → density**. This ticket runs **density → the sizes that
/// are legal**, and `UspWidgetSpecs._applyCardForm` is the whole of that arrow: a
/// function from (item, grid, pick) to a box whose `isResizable`, `minW` and
/// `minH` say what the chosen form allows. Everything else in the feature — the
/// panel, the persistence, the render scope — only moves the pick around.
///
/// #1400 changed the doors into that arrow, not the arms behind it. A pick is
/// *made* through [UspWidgetSpecs.withCardForm], which writes the pick and the
/// geometry it justifies into one copy of one item map; a grid nobody stored has
/// its picks re-derived by [UspWidgetSpecs.applyPickedForms]. There is no third
/// door — a stored grid's geometry was written at that grid's own column count and
/// travels with the pick on the item, so an import re-derives nothing. The
/// `(slotCount, cardId)`-keyed map this file used to hand in as an argument is
/// gone, and with it every way the two halves could disagree.
///
/// ## Mutation table
///
/// Each row is one edit to `usp_widget_specs.dart` — except 19-21 and 23-25, which
/// edit the models in `card_form_choice.dart` — applied to the real file and run
/// against this file *and* `usp_card_form_persistence_test.dart` (some of the
/// arithmetic is only observable once a pick has been through the pref). The counts
/// are what the run actually reported, not what was predicted; where a mutation is
/// killed by more than three tests the column names the closest ones.
///
/// Rows 2-18 and 22 are #1321's measurement and were not re-taken for #1400: the
/// ticket moved which function the arms are reached through, so each of those
/// mutations is still writable, in the same arm, and still lands in the same tests.
/// Row 1 had to be rewritten — the argument it guarded no longer exists — and rows
/// 23-26 are new; those five were measured against this revision, and for them the
/// count is *this* file's, with the persistence file's written as `(+n there)`.
/// Split out because the two files are not interchangeable: row 23 dies 7 times
/// here on the reader alone and 14 more once a pick has to survive a pref, while
/// row 24 dies twice here and not once there — nothing that goes through the pref
/// has a second `extra` payload to lose.
///
/// | # | mutation | killed by |
/// |---|---|---|
/// | 1 | `applyPickedForms` drops its `if (choice == null) continue;`, treating a card with no pick as normal | 2 — a layout with no picks is the same object; a card with no pick keeps the size the user gave it (+1 there: the AC 6 walk) |
/// | 2 | drop `map['isResizable'] = false` from the popup arm | 7, incl. popup refuses resize at the source |
/// | 3 | `popupColumns` 2 → 6 | 5, incl. collapses to a 2x1 tile on the wide grids |
/// | 4 | `_pinSpan` sets `w`/`h` but writes no caps | 3, incl. states its size in every field that describes it |
/// | 5 | popup arm uses `popupColumns` on every grid (drop the mobile branch) | 2 — on the phone grid keeps the full width; the mobile lock is a no-op on a tile |
/// | 6 | popup arm also sets `map['isStatic'] = true` | popup keeps drag, so a popup tile can still be reordered |
/// | 7 | `compactMinColumns` 4 → 3 | 6, incl. raises minW above the spec's own floor |
/// | 8 | compact raises `minW` but does not grow `w` to it | 3, incl. a card already narrower than the floor is grown to it |
/// | 9 | compact's floor not scaled (`floorW = floorColumns`) | 2 — the compact floor is scaled to the grid it lands on |
/// | 10 | `compactMinHeightRows` 2 → 1 | floors the height as well as the width; on the phone grid touches the height only |
/// | 11 | compact arm omits `map['isResizable'] = true` | compact puts the handles back after popup |
/// | 12 | normal arm restores nothing | 3, incl. normal lowers the floor back to the spec's |
/// | 13 | normal restores the minima but not the maxima | normal restores the handles and the spec bounds |
/// | 14 | normal's `maxW` not scaled to the grid | a card parked outside its spec bounds is pulled inside them |
/// | 15 | `_applyFloors` drops the `maxW < minW` repair | a raised floor never ends up above its own ceiling |
/// | 16 | `selectableForms` drops the `spec.normalAbove != null` guard | 4, incl. offers compact only to the seven cards that read it |
/// | 17 | `cardsWithoutPopupForm` emptied | 3, incl. offers popup to every card built through the template |
/// | 18 | `selectableForms` returns `[normal]` instead of `const []` when nothing else applies | stats_panel offers no form at all |
/// | 19 | `CardForms.props` → `[]` (equality on type alone) | a pick that differs anywhere is a different value |
/// | 20 | `CardForms` drops `Equatable` (back to identity) | a projection rebuilt from the pref equals the live one |
/// | 21 | `CardFormChoice.props` → `[density]` | the restore size is part of what makes a choice equal |
/// | 22 | compact's `specMinW` reads the raw 12-column figure instead of `_scaleFromTwelfths(constraints.minColumns, …)` | so is the spec's own floor, which is also written in twelfths |
/// | 23 | `readFrom` reads `extra` itself instead of `extra[extraKey]` (the pick unnested) | 7, incl. a pick is written onto the item it shapes (+14 there) |
/// | 24 | `writeInto` returns `{extraKey: toJson()}`, dropping the rest of `extra` | 2 — a payload another feature owns survives a pick; it is nested under a key of its own |
/// | 25 | `CardForms.of` keeps every item, defaulting a card with no pick to normal | a card with no pick is absent from the projection, not normal in it (+2 there) |
/// | 26 | compact arm drops the `_applySpecBounds` restore and only raises the floors | reached from popup, it restores the ceiling before raising the floor (+1 there) |
///
/// ### Row 26 was a live bug, not a hypothetical (#1400 review)
///
/// The arms are applied one on top of another — a card goes popup, then compact —
/// and only the `normal` arm said so in its own comment. Compact raised the floors
/// on whatever caps it found, and `_applyFloors` lifts a cap no further than the
/// floor it just wrote, so popup → compact left `maxW: 4.0` on a card whose spec
/// allows 8: capped at its own floor, un-widenable, with the pick and the geometry
/// perfectly consistent about it. The only way out was picking `normal` and
/// re-picking compact.
///
/// It predates this ticket — the arm bodies are #1299's — and #1400 is what made it
/// reachable-and-permanent rather than reachable-and-healed: while the geometry was
/// re-derived from a sibling map on every import, the same wrong figure was simply
/// recomputed each boot; now it is what the pref holds. The transition tests were
/// the gap, and both files had one only for popup → normal.
///
/// ### The survivor that stopped surviving (#1321)
///
/// Row 22 was recorded here as the table's one survivor, and as an *equivalent*
/// mutation rather than a gap: `minW` is the max of the scaled spec floor and the
/// scaled compact floor, every compact consumer declared `minColumns: 3`, and the
/// compact floor won on all three grids either way. The note said it would become
/// observable the first time a card declared a `minColumns` above 3, and that
/// writing a test against a card that did not exist would be worse than recording
/// it.
///
/// `dhcp_reservations` is that card — `minColumns: 4`, so on the 8-column grid its
/// spec floor and the compact floor agree at 3 only if both are scaled — and the
/// test named in row 22 is the one that was owed. The survivor list is empty.
///
/// ### Two claims that moved out of this file (#1400)
///
/// `CardForms` used to be a stored, breakpoint-keyed value with JSON of its own,
/// and two of its guarantees were asserted here: that the picks round-trip through
/// the pref, and that an install whose only pick was an explicit normal does not
/// stamp the payload unreadable to older builds (`hasFormBeyondNormal`). Both are
/// the envelope's now — the picks ride inside `layouts`, and the stamp is computed
/// by walking the items — and both are asserted in `usp_layout_envelope_test.dart`.
/// Neither claim was dropped; what is left here is what `CardForms` still is, a
/// projection of the live grid's items.
void main() {
  const desktop = UspLayoutEnvelope.desktopSlotCount;
  const tablet = UspLayoutEnvelope.tabletSlotCount;
  const mobile = UspLayoutEnvelope.mobileSlotCount;

  /// A layout item map in the shape `exportLayout()` produces.
  Map<String, dynamic> item(
    String id, {
    int x = 0,
    int y = 0,
    int w = 6,
    int h = 3,
    int minW = 3,
    double maxW = 8.0,
    int minH = 2,
    double maxH = 6.0,
    CardFormChoice? pick,
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
        if (pick != null) 'extra': pick.writeInto(null),
      };

  Map<String, dynamic> applyTo(
    Map<String, dynamic> subject, {
    required CardDensity density,
    required int cols,
  }) =>
      UspWidgetSpecs.withCardForm(
        [subject],
        subject['id'] as String,
        CardFormChoice(density: density),
        cols: cols,
      ).single as Map<String, dynamic>;

  /// The picks a grid holding [layout] publishes, built the way
  /// `UspSliverDashboardControllerNotifier` builds it from its live items.
  CardForms formsOf(List<dynamic> layout) => CardForms.of(layout.map((item) {
        final live = LayoutItem.fromMap((item as Map).cast<String, dynamic>());
        return (live.id, live.extra);
      }));

  // ---------------------------------------------------------------------------
  // The no-pick path has to stay exactly where it was
  // ---------------------------------------------------------------------------
  group('a dashboard nobody has picked a form on', () {
    test('a layout with no picks is the same object', () {
      final layout = [item('device_info'), item('lan_info')];

      expect(
        UspWidgetSpecs.applyPickedForms(layout, desktop),
        same(layout),
        reason: 'An install that never opened the control gets byte-identical '
            'output from every derivation the dashboard runs, exactly as it did '
            'before #1299 — no copies, no restated caps.',
      );
    });

    test('a card with no pick keeps the size the user gave it', () {
      // The behavioural half of the row above. The normal arm is a *restore*, so
      // running it on a card nobody picked for is not a harmless no-op: it pulls
      // the card inside its spec bounds. device_info declares maxColumns: 8, so a
      // card dragged to 10 would be snapped back to 8 by every scale.
      final widened = item('device_info', w: 10, maxW: 12.0);

      final result =
          UspWidgetSpecs.applyPickedForms([widened], desktop).single as Map;

      expect([result['w'], result['maxW']], [10, 12.0],
          reason:
              '"No pick" has to mean untouched, not "treated as normal". An '
              'absent pick means the width decides the form (#1232), and the '
              'width is the user\'s.');
    });

    test('a card nobody picked a form for is passed through untouched', () {
      final untouched = item('lan_info');
      final layout = [item('device_info'), untouched];

      final result = UspWidgetSpecs.withCardForm(
        layout,
        'device_info',
        const CardFormChoice(density: CardDensity.popup),
        cols: desktop,
      );

      expect(result[1], same(untouched),
          reason: 'A pick is per card. Rewriting the neighbours would make one '
              'popup selection quietly restate every other card\'s caps.');
    });

    test('a pick for a card the grid does not hold changes nothing', () {
      final layout = [item('device_info')];

      expect(
        UspWidgetSpecs.withCardForm(
          layout,
          'a_card_from_a_previous_session',
          const CardFormChoice(density: CardDensity.popup),
          cols: desktop,
        ),
        [layout.single],
        reason:
            'A pick can no longer outlive its card in the pref — it is *on* '
            'the card (#1400) — but the caller is a notifier reading a live grid, '
            'and a card can be deleted between the tap and the write.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // popup — cannot be resized at all
  // ---------------------------------------------------------------------------
  group('popup', () {
    test('refuses resize at the source', () {
      final popped = applyTo(item('device_info'),
          density: CardDensity.popup, cols: desktop);

      expect(popped['isResizable'], false,
          reason: 'The flag, not the caps. `isResizable: false` makes '
              'dashboard_item_wrapper skip building the handles entirely; caps '
              'alone leave a handle that can be grabbed and does nothing, which '
              'is the #1293 symptom that started this line of work.');
    });

    test('keeps drag, so a popup tile can still be reordered', () {
      final popped = applyTo(item('device_info'),
          density: CardDensity.popup, cols: desktop);

      expect(popped['isStatic'], isNot(true),
          reason:
              'isStatic disables dragging too. Reordering is the one edit a '
              'popup tile should keep — on a phone it is the only way to move a '
              'card up the scroll.');
    });

    test('collapses to a 2x1 tile on the wide grids', () {
      final popped = applyTo(item('device_info', w: 6, h: 3),
          density: CardDensity.popup, cols: desktop);

      expect(popped['w'], 2);
      expect(popped['h'], 1,
          reason: 'An icon, a label and a value on one line. A locked '
              '6-column icon-plus-value is absurd, and with the handles gone it '
              'is also unrecoverable.');
    });

    test('states its size in every field that describes it', () {
      final popped = applyTo(item('device_info'),
          density: CardDensity.popup, cols: desktop);

      expect([popped['minW'], popped['maxW']], [2, 2.0]);
      expect([popped['minH'], popped['maxH']], [1, 1.0],
          reason: 'A `w` outside its own [minW, maxW] is the shape that made '
              '#1293 permanent: correctBounds and setSlotCount both read the '
              'caps, so a pin that only sets `w` gets snapped back.');
    });

    test('on the phone grid keeps the full width and takes the height', () {
      final popped = applyTo(item('device_info', w: 4, minW: 4, maxW: 4.0),
          density: CardDensity.popup, cols: mobile);

      expect(popped['w'], mobile,
          reason:
              'Decision 2. The #1293 lock pins x: 0, w: cols and popup wants '
              'to be small; the two rules would overwrite each other, so each '
              'takes one axis. On a phone popup is a short full-width bar.');
      expect(popped['h'], 1);
      expect(popped['isResizable'], false);
    });

    test('the mobile width lock is a no-op on a popup tile', () {
      // The order of the two rules must not be load-bearing: whatever the popup
      // arm writes for mobile has to be what the lock would write.
      final popped = applyTo(item('device_info', w: 4),
          density: CardDensity.popup, cols: mobile);

      final locked =
          UspWidgetSpecs.lockToFullWidth([popped], mobile).single as Map;

      expect(locked['w'], popped['w']);
      expect(locked['minW'], popped['minW']);
      expect(locked['maxW'], popped['maxW']);
      expect(locked['h'], 1, reason: 'The lock reads x/w only.');
      expect(locked['isResizable'], false);
    });

    test('an overhanging stored item is pulled back onto the grid', () {
      final popped = applyTo(item('device_info', x: 11, w: 6),
          density: CardDensity.popup, cols: desktop);

      expect(popped['x'], 0,
          reason:
              'An item outside the grid is dropped rather than corrected on '
              'import, and a stale pref can arrive holding one.');
    });
  });

  // ---------------------------------------------------------------------------
  // compact — can be enlarged, not shrunk
  // ---------------------------------------------------------------------------
  group('compact', () {
    test('raises minW above the spec\'s own floor', () {
      // device_info declares minColumns: 3, and 3 columns is 191.4px at its
      // narrowest realization — below kPopupBelow, i.e. below the width at which
      // a label and a value fit side by side in any locale.
      final compacted = applyTo(item('device_info', minW: 3),
          density: CardDensity.compact, cols: desktop);

      expect(compacted['minW'], UspWidgetSpecs.compactMinColumns);
      expect(compacted['minW'], greaterThan(3),
          reason:
              'If the floor equals the spec, compact constrains nothing and '
              'the whole "can be enlarged, not shrunk" rule is decoration.');
    });

    test('leaves a card that is already wider alone', () {
      final compacted = applyTo(item('device_info', w: 6),
          density: CardDensity.compact, cols: desktop);

      expect(compacted['w'], 6,
          reason:
              'Enlarging works: compact raises the floor, it does not resize '
              'to it. A wide compact card is sparse, not broken.');
    });

    test('a card already narrower than the compact floor is grown to it', () {
      final compacted = applyTo(item('device_info', w: 3, minW: 3),
          density: CardDensity.compact, cols: desktop);

      expect(compacted['w'], UspWidgetSpecs.compactMinColumns,
          reason:
              'Raising minW to 4 while leaving w at 3 puts the card outside '
              'its own cap — the same self-inconsistent shape #1293 was.');
    });

    test('the compact floor is scaled to the grid it lands on', () {
      final compacted = applyTo(item('device_info', w: 4, minW: 2),
          density: CardDensity.compact, cols: tablet);

      // scaleSpan(4, 12 -> 8) == 3, and the spec's own 3 scales to 2.
      expect(compacted['minW'], 3,
          reason: 'Every column figure in a WidgetSpec is written for the '
              '12-column grid. Read literally on an 8-column one, a 4-column '
              'floor claims half the row.');
    });

    test('so is the spec\'s own floor, which is also written in twelfths', () {
      // The other half of the scaling, and until #1321 it could not be observed:
      // `minW` is the max of the scaled spec floor and the scaled compact floor,
      // and every compact consumer declared `minColumns: 3`, which the compact
      // floor wins on every grid whether the spec figure is scaled or not.
      // `dhcp_reservations` declares 4 — the same figure as the floor — so on the
      // 8-column grid the two agree at 3 only if both are scaled. Read raw, the
      // spec side claims 4 of 8 columns: half the row, for the form whose job is
      // to need less.
      final compacted = applyTo(item('dhcp_reservations', w: 4, minW: 2),
          density: CardDensity.compact, cols: tablet);

      expect(compacted['minW'], 3,
          reason: 'A spec column figure is twelfths at every site that reads '
              'one, including the one it is compared against its own grid at.');
    });

    test('floors the height as well as the width', () {
      final compacted = applyTo(item('device_info', h: 1, minH: 1),
          density: CardDensity.compact, cols: desktop);

      expect(compacted['minH'], UspWidgetSpecs.compactMinHeightRows);
      expect(compacted['h'], UspWidgetSpecs.compactMinHeightRows,
          reason: 'Shrinking is refused on both axes, not only sideways. The '
              'figure is a title line and a content line; it is a floor, not a '
              'measured raise, because the compact form is *shorter* than normal '
              'and a number above what each card declares could only be invented '
              '(§2.4).');
    });

    test('reached from popup, it restores the ceiling before raising the floor',
        () {
      // Each arm has to be independent of the arm before it, which is the one
      // property the arms do not get for free: popup pins by writing the caps
      // *down* to 2x1, and a floor is a raise, so compact applied on top of a
      // popup box would lift maxW no further than its own new floor. The card
      // would come out of popup capped at 4 of 12 columns, with no gesture that
      // could widen it and nothing on the import path to repair it (#1400).
      final pinned = applyTo(item('device_info', maxW: 8.0, maxH: 6.0),
          density: CardDensity.popup, cols: desktop);
      final compacted =
          applyTo(pinned, density: CardDensity.compact, cols: desktop);

      expect(compacted['maxW'], 8.0);
      expect(compacted['maxH'], 6.0);
      expect(compacted['minW'], UspWidgetSpecs.compactMinColumns,
          reason:
              'The floor is still raised; it is the ceiling that came back.');
    });

    test('keeps the height floor each card already declares when it is higher',
        () {
      // connected_devices declares minHeightRows: 3.
      final compacted = applyTo(item('connected_devices', h: 4, minH: 3),
          density: CardDensity.compact, cols: desktop);

      expect(compacted['minH'], 3,
          reason: 'The floor is a max(), so it can only ever raise. Lowering a '
              'card past its own declared minimum would let compact clip content '
              'the card measured itself against.');
    });

    test('on the phone grid touches the height only', () {
      final compacted = applyTo(item('device_info', w: 4, minW: 4, h: 1),
          density: CardDensity.compact, cols: mobile);

      expect(compacted['minW'], 4,
          reason: 'Mobile widths belong to lockToFullWidth. Writing a scaled '
              'compact floor here could only fight the lock — the same reason '
              'correctedSize leaves mobile widths alone.');
      expect(compacted['minH'], UspWidgetSpecs.compactMinHeightRows);
    });

    test('puts the handles back after popup', () {
      final compacted = applyTo(item('device_info'),
          density: CardDensity.compact, cols: desktop);

      expect(compacted['isResizable'], true,
          reason:
              'popup wrote false into the stored item. Leaving it unset here '
              'means a card can enter popup but never get its handles back — '
              '`isResizable` has to be restated, not merely not-set.');
    });

    test('a raised floor never ends up above its own ceiling', () {
      final compacted = applyTo(
          item('device_info', w: 2, minW: 2, maxW: 2.0, h: 1, maxH: 1.0),
          density: CardDensity.compact,
          cols: desktop);

      expect((compacted['maxW'] as num) >= (compacted['minW'] as num), isTrue);
      expect((compacted['maxH'] as num) >= (compacted['minH'] as num), isTrue,
          reason:
              'The item arriving here is whatever popup pinned, so its caps '
              'are 2x1. A floor above the ceiling makes every resize delta clamp '
              'to nonsense.');
    });
  });

  // ---------------------------------------------------------------------------
  // normal — today's behaviour, and the way back
  // ---------------------------------------------------------------------------
  group('normal', () {
    test('lowers the floor back to the spec\'s', () {
      final restored = applyTo(item('device_info', w: 4, minW: 4),
          density: CardDensity.normal, cols: desktop);

      expect(restored['minW'], 3,
          reason: 'device_info\'s own minColumns. If normal kept the compact '
              'floor, the choice would be one-way: the user could never drag the '
              'card back to the width its spec allows.');
      expect(restored['isResizable'], true);
    });

    test('is a pin, not the absence of a pick', () {
      // Chosen normal survives a width at which #1232 would have degraded the
      // card, because the pick is read before the measurement — see
      // CardDensityHost. Here that shows up as the card keeping a full-size box.
      final pinned = applyTo(item('device_info', w: 6, h: 3),
          density: CardDensity.normal, cols: desktop);

      expect([pinned['w'], pinned['h']], [6, 3]);
    });
  });

  // ---------------------------------------------------------------------------
  // The pick and the geometry it justifies are one value (#1400)
  // ---------------------------------------------------------------------------
  group('a pick and its geometry are written together', () {
    test('a pick is written onto the item it shapes', () {
      final popped = applyTo(item('device_info', w: 6, h: 3),
          density: CardDensity.popup, cols: desktop);

      expect(CardFormChoice.readFrom(popped['extra']),
          const CardFormChoice(density: CardDensity.popup));
      expect([popped['w'], popped['h']], [2, 1],
          reason: 'One copy of one map carries both halves, so whatever '
              'exportLayout, a snapshot or the undo history takes carries the '
              'pick and the box it justifies or neither. #1299 wrote them to two '
              'stores and re-derived one from the other on every import to keep '
              'them in step.');
    });

    test('the pick outlives the geometry it wrote, so a re-pick can undo it',
        () {
      final popped = applyTo(item('device_info', w: 6, h: 3),
          density: CardDensity.popup, cols: desktop);

      // What `setCardForm` reads to hand `restoreW`/`restoreH` back on the way
      // out of popup: the previous pick comes off the item, not out of a map
      // keyed by this grid's slot count.
      final reading = CardFormChoice.readFrom(popped['extra']);

      expect(reading?.density, CardDensity.popup);
      expect(popped['isResizable'], false,
          reason: 'With the handles gone the item map is the only record of '
              'what the card was, which is why the pick has to be readable back '
              'off it rather than inferred from the 2x1 box.');
    });

    test('a grid nobody stored derives the geometry from the pick it carries',
        () {
      final stored = UspWidgetSpecs.withCardForm(
        [item('device_info')],
        'device_info',
        const CardFormChoice(density: CardDensity.popup, restoreW: 6),
        cols: desktop,
      );

      final phone =
          UspWidgetSpecs.scaleLayout(stored, desktop, mobile).single as Map;

      expect([phone['w'], phone['h']], [mobile, 1],
          reason: 'A scale is proportional and a pin is not: scaled, the 2x1 '
              'desktop tile arrives 0 or 1 columns wide on a phone. The pick is '
              'what the derived grid reads, so it gets the phone\'s own popup '
              'geometry — a short full-width bar.');
      expect(CardFormChoice.readFrom(phone['extra']),
          const CardFormChoice(density: CardDensity.popup, restoreW: 6),
          reason: 'And the pick rides into the derived grid intact, restore '
              'size included. #1299 keyed the picks by slot count, so a '
              'breakpoint nobody had stored had no picks at all and rendered '
              'every card in the form its width implied.');
    });
  });

  // ---------------------------------------------------------------------------
  // Which cards get a control at all
  // ---------------------------------------------------------------------------
  group('selectableForms', () {
    test('offers compact only to the seven cards that read it', () {
      final withCompact = UspWidgetSpecs.all
          .map((spec) => spec.id)
          .where((id) =>
              UspWidgetSpecs.selectableForms(id).contains(CardDensity.compact))
          .toList();

      expect(
        withCompact,
        [
          'device_info',
          'lan_info',
          'ethernet_ports',
          'connected_devices',
          'time_settings',
          'dhcp_reservations',
          'network_health',
        ],
        reason: 'A compact entry on a card that ignores the density renders '
            'exactly the normal form — a control that visibly does nothing. '
            'Building compact forms for the other eleven is #1288-#1291-scale '
            'card-own design work and out of scope.',
      );
    });

    test('offers popup to every card built through the template', () {
      final withPopup = UspWidgetSpecs.all
          .map((spec) => spec.id)
          .where((id) =>
              UspWidgetSpecs.selectableForms(id).contains(CardDensity.popup))
          .toList();

      expect(withPopup, hasLength(UspWidgetSpecs.all.length - 1));
      expect(withPopup, isNot(contains('stats_panel')),
          reason:
              'popup is central, not per card: DashboardCardTemplate renders '
              'CardPopupForm from the scope and CardPopupForm falls back to the '
              'title, so it works on every templated card. stats_panel is the one '
              'card the factory builds directly, so it has no popup path.');
    });

    test('stats_panel offers no form at all', () {
      expect(UspWidgetSpecs.selectableForms('stats_panel'), isEmpty,
          reason: 'No compact consumer and no popup path leaves nothing but '
              'normal, and normal on its own is the status quo with a control '
              'attached.');
    });

    test('a card with something to choose lists normal first', () {
      expect(UspWidgetSpecs.selectableForms('device_info'),
          [CardDensity.normal, CardDensity.compact, CardDensity.popup]);
      expect(UspWidgetSpecs.selectableForms('topology'),
          [CardDensity.normal, CardDensity.popup],
          reason: 'normal has to be reachable wherever another form is, or the '
              'pick cannot be undone.');
    });

    test('a package widget offers nothing', () {
      expect(UspWidgetSpecs.selectableForms('some_remote_template'), isEmpty,
          reason: 'App widget cards load from a remote template and are not '
              'built through DashboardCardTemplate, so neither form has a path.');
    });
  });

  // ---------------------------------------------------------------------------
  // What gets written down, and where a reader finds it again
  // ---------------------------------------------------------------------------
  group('a pick rides inside the item it was made for', () {
    test('it survives the trip through the pref', () {
      const choice =
          CardFormChoice(density: CardDensity.popup, restoreW: 4, restoreH: 3);
      final stored = item('device_info', pick: choice);

      final reloaded = jsonDecode(jsonEncode(stored)) as Map;

      expect(CardFormChoice.readFrom(reloaded['extra']), choice,
          reason:
              'The restore size is the only thing standing between popup and '
              'a one-way door, so it has to be as durable as the pick itself.');
    });

    test('it is nested under a key of its own', () {
      final extra = const CardFormChoice(density: CardDensity.popup)
          .writeInto({'someOtherFeature': 1});

      expect(extra.keys, containsAll(['someOtherFeature', 'cardForm']));
      expect(extra[CardFormChoice.extraKey], isA<Map>(),
          reason:
              'Spread across `extra` instead, the next feature that needs a '
              'per-item payload would have to know this one exists — and a key '
              'collision would be read as a density.');
    });

    test('a payload another feature owns survives a pick', () {
      var extra = const CardFormChoice(density: CardDensity.popup)
          .writeInto({'k': 'v'});
      extra =
          const CardFormChoice(density: CardDensity.compact).writeInto(extra);

      expect(extra['k'], 'v',
          reason: '`extra` is the item\'s, not this feature\'s. A pick that '
              'replaced the whole map would silently delete whatever else was '
              'stored on the card.');
      expect(CardFormChoice.readFrom(extra)?.density, CardDensity.compact,
          reason: 'And a second pick replaces the first rather than nesting '
              'beside it.');
    });

    test('an unreadable pick is dropped, not fatal', () {
      expect(
          CardFormChoice.readFrom({
            CardFormChoice.extraKey: {'density': 'a_form_from_the_future'}
          }),
          isNull);
      expect(
          CardFormChoice.readFrom({CardFormChoice.extraKey: 'popup'}), isNull,
          reason: 'A choice is a map; a bare string is not one to read fields '
              'off.');
      expect(CardFormChoice.readFrom('cardForm'), isNull,
          reason: 'And `extra` itself can be anything — it is a free-form '
              'payload, and this is not the only feature allowed to write it.');
      expect(CardFormChoice.readFrom(null), isNull);
      expect(
          CardFormChoice.readFrom({
            CardFormChoice.extraKey: {'density': 'popup'}
          })?.density,
          CardDensity.popup,
          reason: 'The geometry stored beside these picks is the user\'s real '
              'work. Losing one density pick is a far smaller loss than '
              'resetting a dashboard they arranged.');
    });

    test('a pick cannot outlive the card it was made for', () {
      final layout = UspWidgetSpecs.withCardForm(
        [item('device_info'), item('lan_info')],
        'device_info',
        const CardFormChoice(density: CardDensity.popup),
        cols: desktop,
      );

      final deleted =
          layout.where((item) => (item as Map)['id'] != 'device_info').toList();

      expect(formsOf(deleted).byCard['device_info'], isNull,
          reason: 'Structural now, where #1299 had to prune a sibling map by '
              'hand (`withoutCard`). Membership is not per breakpoint — deleting '
              'a card deletes the card — so a surviving pick would silently apply '
              'a form from a previous session the moment the card was re-added.');
      expect(formsOf(layout).densityFor('device_info'), CardDensity.popup);
    });

    test('a card with no pick is absent from the projection, not normal in it',
        () {
      final forms = formsOf([item('device_info'), item('lan_info')]);

      expect(forms.densityFor('device_info'), isNull);
      expect(forms.isEmpty, isTrue,
          reason:
              'Absent means "the width decides" (#1232); an explicit normal '
              'pins the card to normal at every width. A projection that '
              'defaulted the first to the second would pin all seventeen cards '
              'on an install that never touched the control.');
    });
  });

  // ---------------------------------------------------------------------------
  // Both models are Riverpod state, so equality is behaviour
  // ---------------------------------------------------------------------------
  group('two sets of picks that say the same thing are the same value', () {
    test('a projection rebuilt from the pref equals the live one', () {
      final layout = UspWidgetSpecs.withCardForm(
        UspWidgetSpecs.withCardForm(
          [item('device_info'), item('lan_info')],
          'device_info',
          const CardFormChoice(density: CardDensity.popup, restoreW: 6),
          cols: desktop,
        ),
        'lan_info',
        const CardFormChoice(density: CardDensity.compact),
        cols: desktop,
      );

      final live = formsOf(layout);
      final reloaded = formsOf(jsonDecode(jsonEncode(layout)) as List);

      expect(reloaded, live,
          reason:
              'This is the value of a StateProvider, and it is republished on '
              'every write to the layout beacon — which includes each leg of the '
              'persistence walk\'s visit to the other breakpoints. On identity '
              'alone every one of those would rebuild every card that reads its '
              'density, for picks that did not move.');
      expect(reloaded.hashCode, live.hashCode,
          reason: 'The map is compared deeply, so it has to be hashed deeply '
              'too — Map.hashCode is identity, which would put two equal values '
              'in different buckets.');
    });

    test('a pick that differs anywhere is a different value', () {
      const base = CardForms({
        'device_info': CardFormChoice(density: CardDensity.popup),
      });

      expect(
        base,
        isNot(const CardForms({
          'device_info': CardFormChoice(density: CardDensity.compact),
        })),
        reason: 'A different form on the same card.',
      );
      expect(
        base,
        isNot(const CardForms({
          'lan_info': CardFormChoice(density: CardDensity.popup),
        })),
        reason: 'The same form on another card. The key is part of the value, '
            'or a rebuild that moved a pick from one card to another would '
            'republish nothing.',
      );
      expect(
        base,
        isNot(const CardForms({
          'device_info': CardFormChoice(density: CardDensity.popup),
          'lan_info': CardFormChoice(density: CardDensity.popup),
        })),
        reason: 'A pick added for another card.',
      );
      // The per-grid half of #1294 is not asserted here any more, because there
      // is no key left to get wrong: this is a projection of one grid's items,
      // and each slot count has its own cached list of them. That the phone
      // grid's pick stays on the phone grid is a property of the stored payload
      // now, asserted in usp_layout_envelope_test.dart and
      // usp_card_form_persistence_test.dart.
    });

    test('the restore size is part of what makes a choice equal', () {
      expect(
        const CardFormChoice(density: CardDensity.popup, restoreW: 6),
        isNot(const CardFormChoice(density: CardDensity.popup, restoreW: 4)),
        reason: 'Two popup tiles that look identical restore to different '
            'boxes. Equality that read only the density would let a revert '
            'keep the wrong one.',
      );
    });
  });
}
