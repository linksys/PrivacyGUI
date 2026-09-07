@Tags(['layout-gate', 'overflow'])
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../layout_gate/families/forced_form_card_family.dart';
import '../../../layout_gate/sweep.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';

/// The boxes #1299 lets a user ask for, swept at the geometry the pick produces
/// (AC 11).
///
/// Every existing sweep pumps a width the *grid* chose. #1299 inverts that: the
/// user chooses the form and the form chooses the box, so two footprints now exist
/// that no drag could ever have produced and no file was measuring.
///
/// ## The two new geometries, and why they are not dominated
///
/// **A forced popup tile is 2 columns by 1 row.** Its narrowest realization is
/// 122.3px — 69px narrower than the 191.4px 3-column floor, which was the
/// narrowest width any card had ever been pumped at — and 120px tall against the
/// 2-4 rows every other sweep gives it. Both bounds move the wrong way at once,
/// and `dashboard_card_popup_overflow_test.dart` cannot cover it: that file pumps
/// each card at *its own* narrowest realization, which is a width the card's
/// `minColumns` permits. The pick overrides `minColumns`, so the box is smaller
/// than the spec would allow.
///
/// It also reaches cards that file skips entirely. Nine of the eighteen are
/// floored above [kPopupBelow] by their own `minColumns`, so no width selects
/// popup for them and that sweep leaves them out — correctly, then. A pick is not
/// a width, so eight of those nine (all but `stats_panel`, which has no popup
/// path) can now render a popup form, and this is the first file to render one.
///
/// **A forced compact card cannot go below 4 columns**, which realizes at 260.5px.
/// The #1183 gate pumps only each spec's min / preferred / max spans — 3, 6 and 8
/// for six of the seven compact consumers — so the span this ticket makes their
/// floor is pumped by nothing. And for two of the seven the automatic rule would
/// not select compact there at all: 260.5px is above `lan_info`'s 250 and
/// `time_settings`' 256, so those two render their compact form at that width only
/// because the user asked, which is exactly the "width the automatic rule would
/// not select" the AC names. The inventory below pins which two, rather than
/// leaving it as prose.
///
/// The seventh is `dhcp_reservations`, and it is the exception that made the
/// inventory a partition rather than an emptiness. #1321 gave it a threshold, and
/// its `minColumns` is 4 — so the gate's own min-span case *is* this floor, in the
/// compact form, in all 26 locales, at the same 3 rows. Its three cases below are
/// therefore duplicates. They are kept because the sweep is generated from "the
/// cards a user can pick compact for", which is the honest definition of what this
/// file covers; excluding a card because another file happens to reach the same
/// coordinate opens a hole the moment a `normalAbove` or a `minColumns` moves, and
/// three cases is not a price worth that.
///
/// ## What is deliberately not swept
///
/// **The mobile popup realization.** On the 4-column grid popup owns the height
/// only and the #1293 lock keeps the card full width, so the tile there is 288px
/// by 1 row: wider than the collapse case at the same height. Overflow is
/// monotonic in width, so it is strictly dominated — and `is dominated by the
/// collapse case` pins that claim against the geometry rather than asserting it in
/// a comment, so a change to either rule surfaces here instead of silently
/// dropping coverage.
///
/// **Compact above `normalAbove`.** A compact card can now be forced at any width
/// up to its 8-column maximum. Those widths are wider than its floor at the same
/// height, so they are dominated for overflow the same way. That the *form* still
/// renders there — decision 3 on the issue, a chosen density is not re-promoted by
/// widening — is a question about which form is selected rather than whether it
/// fits, and it is asserted at the `CardDensityHost` seam in
/// `test/page/dashboard/views/card_form_control_test.dart`.
///
/// **Twenty-three of the twenty-six locales.** The popup and compact forms are
/// already swept in all 26 at the widths the grid produces; the dimension this
/// file adds is the geometry and the card list, not the string table. So it takes
/// the same three the popup file's second pump takes, for the same reason: English
/// as the baseline, German for the longest Latin compounds, Traditional Chinese for
/// the widest glyphs. Since #1344 that set is `kCardTextBoundingLocales`, shared
/// with the file it borrowed the argument from.
///
/// ## No allowlist
///
/// `known_overflows.json` baselines the normal form's inherited debt — since #1341
/// keyed on the overflow's `file:line`, so an exemption is a source location rather
/// than a coordinate the grid chose. Nothing here is inherited — these boxes did
/// not exist before this ticket — so a failure is this ticket's regression and
/// there is nothing to grandfather. AC 10 is the other half of that: the fixture is
/// unchanged, and the #1183 gate stays green.
///
/// ## Mutation table
///
/// The sweep's own assertions are already ratcheted — they fail on a real overflow,
/// which is what found the skeleton defect in the first place. So the rows are the
/// **fix** this file forced, applied to `card_skeleton.dart` and run against this
/// file.
///
/// | # | mutation | killed by |
/// |---|---|---|
/// | 1 | remove the popup branch (the pre-fix skeleton) | 10 — 4 variant tests + `connected_devices` and `wifi_performance` × 3 locales |
/// | 2 | the popup branch skips one variant (`_variant != list`) | 4 — the `list` variant and `connected_devices` × 3 |
/// | 3 | `_buildPopup` drops the `Flexible` around the value line | **survived** — equivalent today |
///
/// Row 1 is the measurement behind the fix: 94.0px over on `connected_devices`,
/// 6.0px on `wifi_performance`, and 4 of the 5 variants over on their own. Row 2 is
/// there because row 1 alone would also pass with the branch applied to a single
/// variant — the popup form is card-independent, and so is its placeholder.
///
/// The kill counts are unchanged by #1367 deleting the `stats` variant, and the
/// reason is worth recording: that variant was a subclass overriding `build`
/// outright, so it never reached the popup branch these rows mutate and was killed
/// by neither. The denominator above was 6 and is now 5; the numerator never
/// included it.
///
/// Row 3 survives because the popup skeleton's content is 48px inside an 86px box,
/// so nothing is ever asked to shrink. The `Flexible` is kept anyway: it mirrors
/// `CardPopupForm`'s own shape, which is what keeps the placeholder and the form it
/// resolves into from jumping. Recorded rather than removed, and recorded rather
/// than left to look covered.
///
/// The row counts are per-*locale* tests, which is what this file used to declare;
/// since #1344 the same mutation is killed by the coordinate test that carries
/// those locales. Row 2 is the one to read twice: 4 killed tests becomes 2 (the
/// `list` variant, and `connected_devices` across its three locales in one test),
/// and the mutation is no less dead for it.
///
/// ## What this file is, since #1344
///
/// Three [runOverflowSweep] declarations and the five hand-written tests that keep
/// them honest. The 77 cells the three sweeps measure are enumerated by
/// `test/layout_gate/families/forced_form_card_family.dart`; the tolerance filter,
/// the fresh-subtree key, the surface reset and the failure prose are the shared
/// runner's, which is what #1344 is for.
///
/// The five that remain are the inventory: which cards can be picked into each
/// form (both sweep sizes are entirely a function of those two lists), that the
/// tile is narrower and shorter than anything the grid produces, that the mobile
/// rule does not undercut it, that the compact floor is a span the gate never
/// pumps, and which two cards make the compact sweep *forced*. None of them pumps a
/// card, which is why none of them is in #1337's dataset.
///
/// **80 tests before, 37 after**, and the whole difference is the grouping the
/// runner fixes: 75 per-locale tests become 29 coordinate tests, each looping its
/// three locales inside one body, plus the three cell-count pins those coordinates
/// can no longer be counted by eye. 5 + 17 + 6 + 6 + 3 = 37.
///
/// **38 since the #1325 merge**, and the +1 is the arithmetic rather than a decision:
/// `dhcp_reservations` became pickable-compact, so the compact sweep's coordinates go
/// 6 → 7 and its cells 18 → 21. 5 + 17 + 6 + 7 + 3 = 38.
///
/// **37 since #1367**, and this one *is* a decision: the `stats` skeleton variant is
/// deleted, so the skeleton sweep's coordinates go 6 → 5 and its cells with them.
/// 5 + 17 + 5 + 7 + 3 = 37. It is the same count #1344 landed at by coincidence, and
/// the three cell-count pins are what tell the two apart.
///
/// One cell **id** changes with the port — the skeleton cells gain
/// `|locale=en`, which they were always measured in — and `forced_form.tsv` is
/// re-captured for it. The family header has the before/after and the argument;
/// the other 69 rows are byte-identical.

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('what this file sweeps', () {
    test('is every card that can be picked into popup', () {
      // 17 of the 18: `stats_panel` is not built through DashboardCardTemplate,
      // so it has no popup form to force. An id disappearing from this list has
      // silently lost coverage here; the list appearing shorter than
      // `UspWidgetSpecs.all` minus one means a card stopped offering the form.
      expect(
        specsOfferingForm(CardDensity.popup).map((s) => s.id).toList(),
        UspWidgetSpecs.all
            .map((s) => s.id)
            .where((id) => !UspWidgetSpecs.cardsWithoutPopupForm.contains(id))
            .toList(),
      );
    });

    test('at a box narrower and shorter than any width the grid produces', () {
      // The argument that this sweep is not dominated by the existing ones. If a
      // spec ever floors itself below two columns this stops being true, and the
      // popup sweep would then already be covering this width.
      final narrowestGridWidth = UspWidgetSpecs.all
          .map(widthCasesFor)
          .where((cases) => cases.isNotEmpty)
          .map((cases) => cases.first.cardWidth)
          .reduce(math.min);

      expect(forcedPopupTileCase.cardWidth, lessThan(narrowestGridWidth),
          reason: 'a picked popup tile is ${forcedPopupTileCase.widthKey}px '
              'against the grid\'s narrowest '
              '${narrowestGridWidth.toStringAsFixed(1)}px');
      expect(
        UspWidgetSpecs.popupHeightRows,
        lessThanOrEqualTo(UspWidgetSpecs.all
            .map((s) => s.getConstraints(DisplayMode.normal).minHeightRows)
            .reduce(math.min)),
        reason: 'and no taller than the shortest card the grid places',
      );
    });

    test('and the mobile popup rule is dominated by the collapse case', () {
      // The skip justification for the 4-column grid, pinned. Popup takes the
      // height there and #1293's lock keeps the width, so the tile is full width
      // at the same one row. Wider at equal height is dominated, because overflow
      // is monotonic in width — the premise every "one width per span" claim in
      // this suite rests on.
      const mobileScreen = kMinSupportedScreenWidth;
      final mobileColumns = gridColumnsForWidth(mobileScreen);
      expect(mobileColumns, UspLayoutEnvelope.mobileSlotCount);
      final mobileWidth = cardWidthAt(mobileScreen, mobileColumns);

      expect(mobileWidth, greaterThan(forcedPopupTileCase.cardWidth),
          reason: 'if the mobile rule ever produces a narrower tile than the '
              'collapse, it is the worst case and this file must sweep it '
              'instead');
    });

    test('compact\'s floor is a span the gate pumps for one card only', () {
      // This began as `a span the gate never pumps`, which held while every
      // compact consumer declared min/preferred/max 3/6/8 — the inventory #1299
      // measured. #1321 broke it: `dhcp_reservations` is the first card to declare
      // a threshold *and* floor itself at 4 columns, so the gate's min-span case
      // is this file's compact floor.
      //
      // The claim is a three-way partition rather than an emptiness, and every
      // side is pinned, because which side a card sits on decides what this file
      // is the *only* coverage for. `notPumped` is exclusive coverage on the width;
      // `pumpedInNormal` is exclusive coverage on the form (the gate reaches the
      // width and production renders normal there, so only a pick shows compact);
      // `pumpedInCompact` is duplicated, and the header says why it is kept.
      final notPumped = <String>[];
      final pumpedInCompact = <String>[];
      final pumpedInNormal = <String>[];

      for (final spec in specsOfferingForm(CardDensity.compact)) {
        final spans = widthCasesFor(spec).map((c) => c.columnSpan);
        if (!spans.contains(UspWidgetSpecs.compactMinColumns)) {
          notPumped.add(spec.id);
        } else if (densityForWidth(
                width: forcedCompactFloorCase.cardWidth,
                normalAbove: spec.normalAbove) ==
            CardDensity.compact) {
          pumpedInCompact.add(spec.id);
        } else {
          pumpedInNormal.add(spec.id);
        }
      }

      expect(
        notPumped,
        [
          'device_info',
          'lan_info',
          'ethernet_ports',
          'connected_devices',
          'time_settings',
          'network_health',
        ],
        reason: 'these declare no ${UspWidgetSpecs.compactMinColumns}-column '
            'span, so ${forcedCompactFloorCase.widthKey}px is a width no sweep but this one '
            'reaches. An id leaving this list has not lost coverage — it has '
            'moved to one of the two below, and the reason has to be read',
      );
      expect(
        pumpedInCompact,
        ['dhcp_reservations'],
        reason:
            'the gate already pumps these at ${forcedCompactFloorCase.widthKey}px in '
            'the compact form, so their cases below are duplicates rather than '
            'coverage. A list growing here is fine; a list growing to include '
            'every card means this file\'s compact sweep has stopped adding '
            'anything and should be reconsidered',
      );
      expect(
        pumpedInNormal,
        isEmpty,
        reason: 'a card here declares the floor span but sits above its own '
            'threshold at ${forcedCompactFloorCase.widthKey}px, so the gate measures its '
            'normal form and only a pick reaches the compact one. Nothing is '
            'wrong with that — it is the strongest case for this sweep — but it '
            'is a shape #1299 never measured, so it is pinned rather than '
            'assumed away',
      );
    });

    test('and for two of the seven the rule there would say normal', () {
      // Which cards make this file's compact sweep *forced* rather than merely
      // un-pumped. Named rather than counted: the two are the cards whose
      // threshold sits below the 4-column realization, and a spec edit that moves
      // a threshold across it changes the meaning of the sweep.
      final ruleSaysNormal = specsOfferingForm(CardDensity.compact)
          .where((s) =>
              densityForWidth(
                  width: forcedCompactFloorCase.cardWidth,
                  normalAbove: s.normalAbove) ==
              CardDensity.normal)
          .map((s) => s.id)
          .toList();

      expect(ruleSaysNormal, ['lan_info', 'time_settings'],
          reason: 'at ${forcedCompactFloorCase.widthKey}px these are the cards '
              'production would render in their normal form, so a pick is the '
              'only way to see their compact form at this width — AC 11\'s "a '
              'width the automatic rule would not select". The other five are '
              'already in their compact band here, and are swept for the '
              'geometry alone');
    });
  });

  // ─── A forced popup tile ──────────────────────────────────────────────────
  //
  // Every card a user can pick popup for, in the 122x1 box the pick produces.
  // 17 cards x 3 locales. The count is pinned because the grouping hides a
  // narrowing: 17 coordinates report the same green whether each ran 3 locales or
  // 1 — and this sweep's size is a function of `selectableForms`, which the
  // inventory test above pins from the other side.
  runOverflowSweep(
    family: const ForcedPopupTileFamily(),
    expectedCellCount: 51,
  );

  // ─── The loading state at the picked box ──────────────────────────────────
  //
  // Found by the sweep above, and a separate sweep rather than part of it: a card
  // only renders its skeleton in the frames before its data arrives, and the
  // shared fixture resolves most cards' data immediately, so 13 of the 15 cards
  // that return a skeleton were covered by fixture timing rather than by a test.
  // The variants are therefore pumped directly, in `en` alone — the input is a
  // widget under a popup scope, which has nothing to do with locale or card data.
  //
  // These cells are the ones whose ids change at #1344, gaining the `|locale=en`
  // the runner appends to every cell by construction. See the family header.
  //
  // 6 until #1367 deleted the `stats` variant. It was the one cell here measuring a
  // box production never produced — `stats_panel` is the single card with no popup
  // path at all, which is why the inventory test above excludes it — and #1367 left
  // `CardSkeleton.stats()` with no production caller. The family header has the
  // argument; this pin is what makes the removal a number rather than prose.
  runOverflowSweep(
    family: const ForcedFormSkeletonFamily(),
    expectedCellCount: 5,
  );

  // ─── A forced compact card at its floor ───────────────────────────────────
  //
  // 7 cards x 3 locales, at the 261px the pick floors them at and the row count
  // [forcedCompactFloorRows] takes the max of — see it for the four cards the
  // constant alone would measure a shorter card than the floor permits for.
  //
  // 18 until #1325 gave `dhcp_reservations` a `normalAbove`, which is the predicate
  // `selectableForms` reads: a threshold added for the normal band's sake made a
  // seventh card pickable-compact, and this pin is what said so.
  runOverflowSweep(
    family: const ForcedCompactFloorFamily(),
    expectedCellCount: 21,
  );
}
