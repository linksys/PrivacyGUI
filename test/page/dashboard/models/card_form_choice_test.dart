import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

/// #1299 — the inversion, at the seam where a stored pick becomes geometry.
///
/// #1232 runs **width → density**. This ticket runs **density → the sizes that
/// are legal**, and [UspWidgetSpecs.applyCardForms] is the whole of that arrow:
/// a pure function from (layout, grid, picks) to a layout whose `isResizable`,
/// `minW` and `minH` say what the chosen form allows. Everything else in the
/// feature — the panel, the persistence, the render scope — only moves the pick
/// around.
///
/// ## Mutation table
///
/// Each row is one edit to `usp_widget_specs.dart` — except 19-21, which edit the
/// models in `card_form_choice.dart` — applied to the real file and run against
/// this file *and* `usp_card_form_persistence_test.dart` (some of the arithmetic is
/// only observable once a pick has been through the pref). The counts are what the
/// run actually reported, not what was predicted; where a mutation is killed by
/// more than three tests the column names the closest ones.
/// Re-taken after the suite grew the render, panel and gate files — per §2.6h item
/// 3, a ledger is a per-revision measurement, and four of these counts moved.
///
/// | # | mutation | killed by |
/// |---|---|---|
/// | 1 | `if (choices.isEmpty) return layout;` → `return [...layout];` | a layout with no picks is the same object |
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
/// | 16 | `selectableForms` drops the `spec.normalAbove != null` guard | 4, incl. offers compact only to the six cards that read it |
/// | 17 | `cardsWithoutPopupForm` emptied | 3, incl. offers popup to every card built through the template |
/// | 18 | `selectableForms` returns `[normal]` instead of `const []` when nothing else applies | stats_panel offers no form at all |
/// | 19 | `CardForms.props` → `[]` (equality on type alone) | a pick that differs anywhere is a different value |
/// | 20 | `CardForms` drops `Equatable` (back to identity) | a rebuilt CardForms equals the one it was rebuilt from |
/// | 21 | `CardFormChoice.props` → `[density]` | the restore size is part of what makes a choice equal |
///
/// ### One survivor, and why it is left alive
///
/// Replacing compact's `specMinW = _scaleFromTwelfths(constraints.minColumns, …)`
/// with the raw 12-column figure survives. It is an *equivalent* mutation on today's
/// data, not a gap: every one of the six compact consumers declares `minColumns: 3`,
/// and `minW` is the max of the scaled spec floor and the scaled compact floor, which
/// the compact floor wins on all three grids. The scaling there is defensive —
/// it becomes observable the first time a card declares a `minColumns` above 4 —
/// and writing a test that only passes because of a card that does not exist would
/// be worse than recording this.
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

  Map<String, dynamic> applyTo(
    Map<String, dynamic> subject, {
    required CardDensity density,
    required int cols,
  }) =>
      UspWidgetSpecs.applyCardForms(
        [subject],
        cols,
        {subject['id'] as String: CardFormChoice(density: density)},
      ).single as Map<String, dynamic>;

  // ---------------------------------------------------------------------------
  // The no-pick path has to stay exactly where it was
  // ---------------------------------------------------------------------------
  group('a dashboard nobody has picked a form on', () {
    test('a layout with no picks is the same object', () {
      final layout = [item('device_info'), item('lan_info')];

      expect(
        UspWidgetSpecs.applyCardForms(layout, desktop, const {}),
        same(layout),
        reason: 'Returning a copy would be harmless in itself, but _normalize '
            'uses identity to decide whether the desktop grid needs re-importing '
            'at all, and an unconditional re-import compacts the layout on every '
            'boot. Byte-identical for an install with no picks is the guarantee.',
      );
    });

    test('a card nobody picked a form for is passed through untouched', () {
      final untouched = item('lan_info');
      final layout = [item('device_info'), untouched];

      final result = UspWidgetSpecs.applyCardForms(layout, desktop, {
        'device_info': const CardFormChoice(density: CardDensity.popup),
      });

      expect(result[1], same(untouched),
          reason: 'A pick is per card. Rewriting the neighbours would make one '
              'popup selection quietly restate every other card\'s caps.');
    });

    test('a pick for a card the grid does not hold changes nothing', () {
      final layout = [item('device_info')];

      expect(
        UspWidgetSpecs.applyCardForms(layout, desktop, {
          'a_card_from_a_previous_session':
              const CardFormChoice(density: CardDensity.popup),
        }),
        [layout.single],
        reason: 'Picks outlive deletions in a stale pref, and the import path '
            'must not throw on one.',
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
      // The order of the two rules must not be load-bearing: whatever
      // applyCardForms writes for mobile has to be what the lock would write.
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
  // Which cards get a control at all
  // ---------------------------------------------------------------------------
  group('selectableForms', () {
    test('offers compact only to the six cards that read it', () {
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
          'network_health',
        ],
        reason: 'A compact entry on a card that ignores the density renders '
            'exactly the normal form — a control that visibly does nothing. '
            'Building compact forms for the other twelve is #1288-#1291-scale '
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
  // What gets written down
  // ---------------------------------------------------------------------------
  group('CardForms round-trips through JSON', () {
    test('a pick per breakpoint survives encode and decode', () {
      const forms = CardForms({
        12: {'device_info': CardFormChoice(density: CardDensity.normal)},
        4: {
          'device_info': CardFormChoice(
              density: CardDensity.popup, restoreW: 4, restoreH: 3),
        },
      });

      final decoded =
          CardForms.fromJson(jsonDecode(jsonEncode(forms.toJson())));

      expect(decoded.densityFor(12, 'device_info'), CardDensity.normal);
      expect(
          decoded.choiceFor(4, 'device_info'),
          const CardFormChoice(
              density: CardDensity.popup, restoreW: 4, restoreH: 3),
          reason:
              'The restore size is the only thing standing between popup and '
              'a one-way door, so it has to be as durable as the pick itself.');
    });

    test('an unreadable pick is dropped, not fatal', () {
      final decoded = CardForms.fromJson({
        '12': {
          'device_info': {'density': 'a_form_from_the_future'},
          'lan_info': {'density': 'popup'},
        },
        'not_a_grid': {
          'device_info': {'density': 'popup'}
        },
      });

      expect(decoded.densityFor(12, 'device_info'), isNull);
      expect(decoded.densityFor(12, 'lan_info'), CardDensity.popup,
          reason: 'The geometry stored beside these picks is the user\'s real '
              'work. Losing one density pick is a far smaller loss than '
              'resetting a dashboard they arranged.');
    });

    test('an empty breakpoint is not written down', () {
      final forms = CardForms.empty
          .withChoice(12, 'device_info',
              const CardFormChoice(density: CardDensity.popup))
          .withChoice(12, 'device_info', null);

      expect(forms.isEmpty, isTrue);
      expect(forms.toJson(), isEmpty,
          reason: 'An install that picked a form and then undid it should be '
              'indistinguishable on disk from one that never picked.');
    });

    test('a pick does not outlive the card it was made for', () {
      final forms = CardForms.empty
          .withChoice(12, 'device_info',
              const CardFormChoice(density: CardDensity.popup))
          .withChoice(4, 'device_info',
              const CardFormChoice(density: CardDensity.compact))
          .withChoice(
              4, 'lan_info', const CardFormChoice(density: CardDensity.popup));

      final pruned = forms.withoutCard('device_info');

      expect(pruned.densityFor(12, 'device_info'), isNull);
      expect(pruned.densityFor(4, 'device_info'), isNull);
      expect(pruned.densityFor(4, 'lan_info'), CardDensity.popup,
          reason: 'Membership is not per breakpoint — deleting a card deletes '
              'the card — so a surviving pick would silently apply a form from a '
              'previous session the moment the card was re-added.');
    });

    test('only popup and compact count as shaping the geometry', () {
      // What `UspLayoutEnvelope.version` is a claim about. An explicit normal is
      // a pick — it out-ranks the width-derived form — but the geometry it writes
      // is the spec's own bounds with `isResizable` on, which is what a build
      // carrying no card-form rule writes for itself. Treating it as shaping
      // stamped the payload unreadable-to-older-builds for the rest of the
      // install's life the first time anyone tried popup and undid it.
      expect(CardForms.empty.hasFormBeyondNormal, isFalse);

      const onlyNormal = CardForms({
        12: {'device_info': CardFormChoice(density: CardDensity.normal)},
        4: {'lan_info': CardFormChoice(density: CardDensity.normal)},
      });
      expect(onlyNormal.hasFormBeyondNormal, isFalse);
      expect(onlyNormal.isNotEmpty, isTrue,
          reason: 'Still a pick: it is written down and it still decides the '
              'form. Only the version stamp treats it as a non-event.');

      for (final shaping in [CardDensity.popup, CardDensity.compact]) {
        expect(
            CardForms({
              12: {
                'device_info':
                    const CardFormChoice(density: CardDensity.normal),
                'lan_info': CardFormChoice(density: shaping),
              },
            }).hasFormBeyondNormal,
            isTrue,
            reason: 'One ${shaping.name} card is enough — the stamp describes '
                'the whole payload, not one entry.');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Both models are Riverpod state, so equality is behaviour
  // ---------------------------------------------------------------------------
  group('two sets of picks that say the same thing are the same value', () {
    test('a rebuilt CardForms equals the one it was rebuilt from', () {
      const original = CardForms({
        12: {'device_info': CardFormChoice(density: CardDensity.popup)},
        4: {'lan_info': CardFormChoice(density: CardDensity.compact)},
      });

      final rebuilt =
          CardForms.fromJson(jsonDecode(jsonEncode(original.toJson())) as Map);

      expect(rebuilt, original,
          reason:
              'This is the value of a StateProvider, and a reload, a revert '
              'and a preset swap each republish a freshly built instance. On '
              'identity alone every one of those would rebuild every card that '
              'reads its density, for picks that did not move.');
      expect(rebuilt.hashCode, original.hashCode,
          reason: 'The nested map is compared deeply, so it has to be hashed '
              'deeply too — Map.hashCode is identity, which would put two equal '
              'values in different buckets.');
    });

    test('a pick that differs anywhere is a different value', () {
      const base = CardForms({
        12: {'device_info': CardFormChoice(density: CardDensity.popup)},
      });

      expect(
        base,
        isNot(const CardForms({
          12: {'device_info': CardFormChoice(density: CardDensity.compact)},
        })),
        reason: 'A different form on the same card.',
      );
      expect(
        base,
        isNot(const CardForms({
          8: {'device_info': CardFormChoice(density: CardDensity.popup)},
        })),
        reason: 'The same form on a different grid. The breakpoint is part of '
            'the value — that is the whole of #1294 — so equality that ignored '
            'the key would let a phone pick pass for a desktop one.',
      );
      expect(
        base,
        isNot(const CardForms({
          12: {
            'device_info': CardFormChoice(density: CardDensity.popup),
            'lan_info': CardFormChoice(density: CardDensity.popup),
          },
        })),
        reason: 'A pick added for another card.',
      );
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
