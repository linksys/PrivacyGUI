@Tags(['layout-gate', 'overflow'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../layout_gate/families/dashboard_card_family.dart';
import '../../../layout_gate/families/dashboard_card_gate.dart';
import '../../../layout_gate/locale_tag.dart';
import '../../../layout_gate/sweep.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/dashboard/card_data_profiles.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';
import '../../../util/overflow_baseline.dart';

/// Defensive RenderFlex-overflow gate for every dashboard card (#1183).
///
/// WHY THIS TEST EXISTS
///   The golden pipeline already *detects* overflow, but it can't *gate* PRs:
///   goldens are excluded from the PR test command, and overflow is recorded as
///   a silent warning rather than a failure. It also has coverage holes — it
///   screenshots only the default tab, at fixed widths, and doesn't cover every
///   card. The #1145 Network Health legend overflow slipped through all three.
///
/// WHAT IT DOES DIFFERENTLY
///   * Data-driven over [UspWidgetSpecs.all] — the app's own card registry — so
///     new cards are gated automatically, including ones with no golden.
///   * Pumps each card at the **real pixel widths the production grid yields**
///     (see [widthCasesFor]): the narrowest realization of its min / preferred
///     / max column span. Overflow is monotonic in width and height-independent
///     (measured), so the narrowest realization of each span is that span's
///     worst case. That narrowest width is found by **enumerating** the
///     supported screen-width range (`kMinSupportedScreenWidth` upward), not by
///     sampling a list of screen widths — so the worst case is guaranteed by
///     construction rather than asserted (#1225).
///   * **Sweeps every tab** (via [cardTabIndexProvider], not geometric taps),
///     so overflow that only appears on a non-default tab is caught — several
///     cards overflow *worse* on a non-default tab than on tab 0.
///   * **One fresh tree per measurement** — Flutter reports each RenderFlex's
///     overflow only once per render-object lifetime, so a sweep that re-pumped
///     into the same tree would silently drop all but the first. Every (card,
///     width, tab, locale) gets its own keyed subtree; see [runOverflowSweep]
///     invariant 1.
///   * Runs under **every shipped locale** (all 26), so script-specific width
///     blowups (German/Finnish compounds, CJK/Thai glyphs, Arabic RTL) are all
///     covered instead of a hand-picked Latin sample.
///   * Loads the **real fonts** first (see [loadAppFonts]) so text widths — and
///     therefore overflow — are measured accurately, not with the Ahem block.
///
/// WHY IT GATES PRs
///   Tagged `layout-gate`, which is NOT in `run_tests.sh`'s
///   `--exclude-tags="golden||loc||ui"` blacklist, so the PR gate runs it and a
///   failure blocks the PR. (Do not retag it golden/ui/loc — it would silently
///   drop out of the gate.) It also carries `overflow` (#1336), the narrower
///   selector `flutter test --tags overflow` uses to run the four sweeps alone.
///
/// ## What this file is, since #1343
///
/// Three [runOverflowSweep] declarations and the hand-written tests that keep them
/// honest. The 1,898 cells the three sweeps measure are enumerated by
/// `test/layout_gate/families/dashboard_card_family.dart` and judged by
/// [CardSweepGate]; what used to be ~500 lines of nested loops, ratchet plumbing
/// and failure prose in this file is now the framework's, shared with the chrome
/// sweep and — at #1344/#1345 — with the other two.
///
/// The 23 tests that remain here are the ones that are *not* a sweep: 18 for the
/// tab registry (six cards pinning a tab count, twelve pinning that they are
/// single-view, which is what decides how many tabs the sweeps cover), 3 for the
/// normal band's inventory (which decides that sweep's size), and 2 profile guards
/// — one that the swept tab exists, one that the profile's data reaches the tree —
/// which decide whether the 52 profile cells are pumping the profile at all. Each
/// is a measured coordinate in #1337's dataset for the same reason: a port that
/// dropped one would diff clean while taking the coverage with it.
///
/// With the three sweeps' 73 coordinate tests and their 3 cell-count pins, that is
/// the 99 this file declares. The `list all registered dashboard cards` test is not
/// among them — it exists only under `--dart-define=LIST_CARDS`, where it is the
/// whole run.
///
/// The sweeps' own reasoning stays with each `runOverflowSweep` call below, in the
/// section comment above it. The pinned cell counts are the ticket's arithmetic;
/// `./tool/overflow_baseline.sh check card` is what proves the cells behind them
/// did not move.

/// The ratchet, the report, the dump modes and the coverage counters, shared by all
/// three families. One per run — see [CardSweepGate] for why it cannot be per
/// family.
final CardSweepGate _gate = CardSweepGate();

bool get _isListOnly {
  const d = String.fromEnvironment('LIST_CARDS');
  if (d == 'true' || d == '1') return true;
  final env = Platform.environment;
  return env['LIST_CARDS'] == 'true' || env['LIST_CARDS'] == '1';
}

void main() {
  if (_isListOnly) {
    test('list all registered dashboard cards', () {
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('================================================================');
      // ignore: avoid_print
      print(
          ' 📋 Registered Dashboard Cards in UspWidgetSpecs.all (${UspWidgetSpecs.all.length} cards)');
      // ignore: avoid_print
      print('================================================================');
      for (var i = 0; i < UspWidgetSpecs.all.length; i++) {
        final spec = UspWidgetSpecs.all[i];
        final c = spec.getConstraints(DisplayMode.normal);
        final tabCount = tabCountFor(spec.id);
        final tabInfo = tabCount > 1 ? ' | $tabCount tabs' : ' | single tab';
        // ignore: avoid_print
        print(
          '  ${(i + 1).toString().padLeft(2)}. ${spec.id.padRight(28)} (columns: min ${c.minColumns} / pref ${c.preferredColumns} / max ${c.maxColumns}$tabInfo)',
        );
      }
      // ignore: avoid_print
      print('================================================================');
    });
    return;
  }

  setUpAll(() async {
    _gate.loadRatchet();
    await loadAppFonts();
  });

  tearDownAll(() async {
    // The report, the coverage skip note and the ratchet's closing direction, in
    // that order — see [CardSweepGate.close]. A `tearDownAll` failure is reported
    // as `(tearDownAll)` and fails the suite without adding a test to the count.
    final dead = await _gate.close();
    if (dead != null) fail(dead);
  });

  // Meta-test: the hardcoded tab counts in kTabbedCardTabCounts must match what
  // each card actually builds. If a card gains/loses a tab, this fails and
  // points at the registry to update (keeping the sweep exhaustive).
  //
  // Measured at the **desktop** width, not at the narrowest realization it used
  // to pump. A card that declares `normalAbove` renders its popup form below
  // 200px, and the popup form has no tab bar at all — `network_health` was the
  // first tabbed card to declare one (#1291) and this guard read its 0 visible
  // tabs as "the card lost its tabs". How many tabs a card *has* is a property
  // of its whole form; which form a given width selects is a density claim, and
  // it belongs to the per-card density suites rather than to a registry check
  // that happens to pump a narrow width (#1291).
  //
  // Hand-written rather than a family: it pumps one coordinate per card and
  // asserts something other than overflow about it, so a sweep's grouping and
  // locale loop would buy it nothing. It stays in the dataset because it is a real
  // pump — see the `cell:` argument.
  group('tab registry', () {
    for (final entry in kTabbedCardTabCounts.entries) {
      testWidgets('${entry.key} still has ${entry.value} tabs', (tester) async {
        final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == entry.key);
        final wc = desktopCaseFor(spec);
        final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
        await probeCardOverflow(
          tester,
          cardId: entry.key,
          widthCase: wc,
          cardHeightRows: rows,
          tabIndex: 0,
          locale: const Locale('en'),
          // In the dataset even though the assertion below is about tab counts,
          // not about overflow: this pumps a real card and collects real
          // incidents, so it is a measured coordinate — and it is the guard that
          // decides how many tabs the sweeps cover. A port that dropped it would
          // otherwise diff clean while quietly taking the tab registry with it.
          cell: OverflowCell('card.tab_registry', {
            'card': entry.key,
            'px': wc.widthKey,
          }),
        );
        expect(
          visibleTabCount(tester),
          entry.value,
          reason:
              'Tab count for "${entry.key}" changed. Update kTabbedCardTabCounts '
              'in dashboard_card_probe.dart so the overflow sweep covers every '
              'tab.',
        );
      });
    }

    // The inverse claim, which is the half that decides coverage for a *new*
    // card: `tabCountFor` falls back to 1 for anything absent from the registry,
    // so a tabbed card nobody registered is swept at tab 0 and its other tabs
    // are never measured — silently, because every case it does run still
    // passes. Registering a card is therefore not bookkeeping, and the loop
    // above cannot say so: it only iterates ids that are already there.
    final registered = kTabbedCardTabCounts.keys.toSet();
    for (final spec
        in UspWidgetSpecs.all.where((s) => !registered.contains(s.id))) {
      testWidgets('${spec.id} is single-view, so tab 0 is full coverage',
          (tester) async {
        final wc = desktopCaseFor(spec);
        final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
        await probeCardOverflow(
          tester,
          cardId: spec.id,
          widthCase: wc,
          cardHeightRows: rows,
          tabIndex: 0,
          locale: const Locale('en'),
          cell: OverflowCell('card.single_view', {
            'card': spec.id,
            'px': wc.widthKey,
          }),
        );
        expect(
          visibleTabCount(tester),
          1,
          reason: '"${spec.id}" builds a tab bar but is absent from '
              'kTabbedCardTabCounts in dashboard_card_probe.dart, so the sweep '
              'measures tab 0 only and the rest of its tabs go unmeasured. Add '
              'it with its tab count.',
        );
      });
    }
  });

  // ─── The main width sweep ─────────────────────────────────────────────────
  //
  // 18 cards x their realizable spans x their tabs x 26 locales. The count is
  // pinned because the grouping hides a narrowing: 63 coordinates report the same
  // green whether each ran 26 locales or 1.
  runOverflowSweep(
    family: CardWidthFamily(_gate),
    expectedCellCount: 1638,
  );

  // ─── The normal band (#1318) ──────────────────────────────────────────────
  //
  // The sweep above pumps the widths the grid produces for each span, and claims
  // that is exhaustive because overflow is monotonic in width. Since #1288/#1290
  // six cards declare a `normalAbove`, so their narrowest realization renders a
  // *different form* — popup at 191.4px for all six, compact at 288.0px for the
  // three whose threshold is above it — and a different form is not a narrower
  // instance of the same one. For those three **this sweep is the only place the
  // grid's own widths reach the normal form at all**; what the gate had otherwise
  // is `dashboard_card_popup_overflow_test`'s two dialog groups, which render it at
  // the fixed `kCardPresentationWidth` (400px, above every threshold), tab 0 only,
  // in 3 locales, inside dialog chrome rather than a grid cell. That is not the
  // coordinate #1183's own motivating measurement lived at (`network_health`, Loss
  // tab, `de`, 500px, +41px): tab 2 in `de` used to be covered by transitivity from
  // the 191.4px normal case, and #1288 removed that without replacing it.
  //
  // So each of the six is swept once more, at [normalBandCaseFor] — the narrowest
  // width the grid produces at or above its own threshold. One width, because
  // monotonicity is intact *within* a form: see that function for the argument, and
  // `the gate's own widths cannot reach the normal band` below for the half of it
  // that is pinned rather than argued.
  //
  // No density is pinned. The coordinate is chosen so production's own selection
  // lands on normal, and every cell asserts that it did — in
  // [CardNormalBandFamily.onCellSettled], because a pinned sweep would keep
  // passing after a threshold moved out from under it, measuring a form the width
  // no longer selects.
  //
  // Exemptions here are keyed on the overflow's own `file:line`, like every other
  // sweep since #1341 — this sweep needs no key grammar of its own, which is one of
  // the things the re-key bought. Unlike the forced-form sweep these coordinates
  // are *inherited* debt — the normal form was always rendered here in production,
  // only never measured — so grandfathering is the right mechanism if this finds
  // anything. Note the coarsening it comes with: a site exempted for the normal
  // band is exempted wherever else it overflows, including in the popup form the
  // main sweep pumps, because the key carries no width.
  //
  // No report collection, for a reason specific to this sweep: the report's
  // recommendation columns advise a wider span, and this coordinate sits exactly at
  // the width the card's own threshold names. "Use one more column" there reads as
  // "raise `normalAbove`", which is a design decision (#1288's measurement), not a
  // layout fix. The failure message carries everything triage needs.
  //
  // ## Mutation table
  //
  // Each assertion below was run against a mutation of the code it guards. Row 1 is
  // the one that justifies the sweep's existence rather than its shape: the main
  // width sweep stayed **green** through it.
  //
  // **Re-run on 2026-08-22 (#1348), against the ported code rather than the code
  // these rows were written for.** #1343 turned 1,822 `testWidgets` into 63 declared
  // coordinates with locale as an inner loop, so a killer the pre-port table counted
  // in *cells* is counted in *tests* now, and a table carried over unchanged would be
  // quoting a measurement of code that no longer exists. Every mutation below was
  // re-applied to the working tree, run, and reverted; "killed by" is the observed
  // failure set, and the pre-port figure is named wherever the port moved it.
  //
  // Two things the re-run found, neither of them predicted. Row 4 caught a coverage
  // change that grew the sweep — the direction a count pin is usually assumed to be
  // useless in. And every row that changes what is measured now also trips an
  // `expectedCellCount`, which is why that parameter is required rather than
  // defaulted (`sweep.dart` §4): rows 2, 4 and 5 each gained a killer from it,
  // including row 2, whose pre-port entry argued the count *could not* fail.
  //
  // Row 1's counts are read off the **dataset**, not off the failure log, and the
  // difference is not pedantic: `flutter test` truncates a long `expect` message
  // mid-list, so the log showed 21 failing locales where the run had 26. A
  // `OVERFLOW_BASELINE=1` capture under the same mutation states it exactly —
  // `card.width` 1,638 cells with **0** significant incidents, `card.profile` 52
  // with 0, `card.normal_band` 26 at one coordinate and 0 at the other seven. That
  // is the sharpest available form of "large, green and blind": not "the big sweep
  // passed" but "the big sweep measured 1,638 cells and saw nothing".
  //
  // | # | assertion | mutation | killed by (re-run 2026-08-22) |
  // |---|---|---|---|
  // | 1 | the per-cell overflow verdict | `usp_network_health_card`: the `if (!compact)` metric row gives its three `_MetricChip`s a fixed `width: 140` instead of `Expanded` — a width the desktop realization has room for and this card's own threshold does not | **7 tests, none of them the main width sweep**: `usp_network_health_density_test`'s four pinned-normal assertions, the two dialog groups in `dashboard_card_popup_overflow_test` (400px — 6 tests pre-port, regrouped by #1344), and one coordinate of *this* sweep, `network_health` tab 0, which was 26 failing `testWidgets` pre-port and is one failing test naming 26 locales now. `card.width` — still the largest thing in the file at 1,638 cells — sees **nothing**, before the port and after |
  // | 2 | `the six cards that declare a threshold` + `each threshold is realizable` + the selected-form table | delete `normalAbove: 366` from `network_health`'s spec | **4**: all 3 meta-tests, plus `card.normal_band`'s declared count (208 → 130). The pre-port entry said the sweep "stays green *if the pin is edited to match*" — post-port there is a pin to edit, and it fails first, so the narrowing is a failure rather than a bookkeeping opportunity |
  // | 3 | `selectedCardDensity(…) == normal` | `normalBandCaseFor` accepts widths 100px below the threshold | **9**: all 8 `card.normal_band` coordinates (208 of 208 cells pre-port — same coverage, counted per coordinate now), plus `each threshold is realizable` |
  // | 4 | `widest lessThanOrEqualTo 288.0` | `kMinSupportedScreenWidth` 320 → 480 (the plausible version of this: dropping 320px support) | **3**, where pre-port it was 1: `the gate's own widths cannot reach the normal band` (`widest` becomes 448.0), plus `card.width` 1,638 → **2,470** and `card.profile` 52 → **78**. Dropping a screen floor makes the generator realize *more* widths, so the sweep silently grows by 858 cells — coverage drift upward, which nothing in the pre-port suite could see |
  // | 5 | the 8-coordinate count | drop `'network_health': 3` from `kTabbedCardTabCounts` | **4**, where pre-port it was 1: `the six cards that declare a threshold` (8 → 6), `card.width` 1,638 → 1,534, `card.normal_band` 208 → 156, and — instead of `network_health still has 3 tabs`, which no longer exists because that loop iterates the registry — `network_health is single-view, so tab 0 is full coverage`, the inverse half written for exactly this case |
  group('normal band coverage', () {
    // The inventory, asserted rather than narrated — the counts in the comment
    // above are the whole justification for this sweep's existence and its size.
    test('the six cards that declare a threshold, at 8 card x tab coordinates',
        () {
      expect(
        {for (final s in normalBandSpecs) s.id: s.normalAbove},
        {
          'device_info': 262.0,
          'lan_info': 250.0,
          'ethernet_ports': 386.0,
          'connected_devices': 336.0,
          'time_settings': 256.0,
          'network_health': 366.0,
        },
        reason: 'a card that gains or loses a `normalAbove` changes what this '
            'sweep covers, so the list is pinned here rather than left to the '
            'family that enumerates it',
      );
      expect(
        normalBandSpecs.fold<int>(0, (n, s) => n + tabCountFor(s.id)),
        8,
        reason: 'five single-view cards plus network_health\'s three tabs',
      );
      // #1183's motivating coordinate, named so a change that drops it is a
      // failure rather than a silent narrowing.
      expect(tabCountFor('network_health'), 3,
          reason: 'the Loss tab is index 2; #1183 measured +41px there in de');
      expect(
        AppLocalizations.supportedLocales.map(localeTag),
        contains('de'),
        reason: 'de is the locale #1183 measured the Loss-tab legend overflow '
            'in, so it has to be in the sweep this replaces it with',
      );
    });

    // Why one width per card is enough, in the direction that can rot: the
    // generator the main sweep uses tops out at 288.0px, because spans 5 upward all
    // realize 288.0px at the 320px screen floor — a card spanning the whole
    // 4-column mobile grid is full width. So no coordinate `widthCasesFor` can
    // produce reaches a threshold above 288, and the three cards below are outside
    // its range by construction rather than by sampling. If a wider realization
    // ever appears this fails, instead of the sweep quietly duplicating coverage.
    test('the gate\'s own widths cannot reach the normal band', () {
      // Every span any card declares — the generator's whole domain, taken from
      // the specs rather than from a hardcoded 1..12 so a new span comes with it.
      final spans = <int>{
        for (final s in UspWidgetSpecs.all) ...[
          s.getConstraints(DisplayMode.normal).minColumns,
          s.getConstraints(DisplayMode.normal).preferredColumns,
          s.getConstraints(DisplayMode.normal).maxColumns,
        ],
      };
      final widest = spans
          .map((span) => narrowestRealizationOf(span, minScreen: 0)!.cardWidth)
          .reduce(math.max);
      expect(widest, lessThanOrEqualTo(288.0),
          reason: 'widthCasesFor draws from narrowestRealizationOf, so 288.0px '
              'is the widest coordinate the main sweep can pump');

      // And the form each of those coordinates actually selects, per card. This is
      // the measurement the comment above quotes; asserting it means a threshold
      // change surfaces here with the numbers, rather than as an unexplained
      // failure in a satellite suite.
      final selected = {
        for (final spec in normalBandSpecs)
          spec.id: [
            for (final wc in widthCasesFor(spec))
              '${wc.widthKey}=${densityForWidth(width: wc.cardWidth, normalAbove: spec.normalAbove).name}',
          ],
      };
      expect(selected, {
        'device_info': ['191=popup', '288=normal'],
        'lan_info': ['191=popup', '288=normal'],
        'ethernet_ports': ['191=popup', '288=compact'],
        'connected_devices': ['191=popup', '288=compact'],
        'time_settings': ['191=popup', '288=normal'],
        'network_health': ['191=popup', '288=compact'],
      });
    });

    // The coordinate itself: derived from the spec, and a width the grid produces
    // rather than the bare threshold value.
    test('each threshold is realizable, so the sweep pumps a production width',
        () {
      expect(
        {
          for (final spec in normalBandSpecs)
            spec.id: '${normalBandCaseFor(spec)!.cardWidth.toStringAsFixed(1)}'
                '@${normalBandCaseFor(spec)!.screenWidth.toStringAsFixed(0)}'
                'x${normalBandCaseFor(spec)!.columnSpan}',
        },
        {
          'device_info': '262.0@1144x3',
          'lan_info': '250.0@1096x3',
          'ethernet_ports': '386.0@552x3',
          'connected_devices': '336.0@2096x3',
          'time_settings': '256.0@1120x3',
          'network_health': '366.0@2216x3',
        },
        reason:
            'every threshold happens to be exactly realizable at the card\'s '
            'minColumns — a consequence of the grid\'s near-continuity in screen '
            'width, pinned here because normalBandCaseFor searches for it rather '
            'than assuming it',
      );
    });
  });

  runOverflowSweep(
    family: CardNormalBandFamily(_gate),
    expectedCellCount: 208,
  );

  // ─── Named data profiles (#1267) ──────────────────────────────────────────
  //
  // The sweeps above are one router shape. `kCardDataProfileSweeps` adds the
  // (card, tab) pairs worth measuring on a second one — see
  // `card_data_profiles.dart` for why the list is opt-in per card rather than
  // all 18, and what that deliberately does not claim.
  //
  // Same widths, same 26 locales, same one-tree-per-measurement rule as above;
  // only the data differs. One thing is deliberately *not* shared with the default
  // sweep:
  //
  //   * No report collection. `OverflowReportItem` has no profile dimension, so a
  //     second-profile item would render in the HTML report indistinguishable
  //     from a default-profile one at the same coordinate — a worse outcome than
  //     its absence. Profile sweeps are measured by reading the failure, which
  //     names the profile.
  //
  // The allowlist used to be the second item on that list, and losing it is worth
  // naming: keys carried an `@profile` suffix, so an exemption earned on this data
  // could not silence the default sweep. A `file:line` key has no profile axis (nor
  // a width or tab one), so an exemption granted for a profile overflow now covers
  // that same source location everywhere, default data included. The trade was made
  // knowingly at #1341 — the suffix bought separation, while the coordinate key it
  // was part of invalidated wholesale on any layout rearrangement — and the fixture
  // is empty today, so nothing is in fact widened. If a profile-only exemption is
  // ever needed the answer is a narrower key shape in `OverflowRatchet`, not a
  // second fixture.
  group('card data profiles', () {
    for (final sweep in kCardDataProfileSweeps) {
      final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == sweep.cardId);
      final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
      final tabCount = tabCountFor(spec.id);
      final profile = sweep.profile;

      for (final tab in sweep.tabs) {
        // A profile pinned to a tab the card no longer has would silently sweep
        // nothing, which is the same failure mode `kTabbedCardTabCounts` exists
        // to prevent.
        test('${sweep.cardId} tab $tab exists', () {
          expect(tab, lessThan(tabCount),
              reason: 'the ${profile.key} profile sweeps ${sweep.cardId} tab '
                  '$tab, but the card has $tabCount tab(s). Update '
                  'kCardDataProfileSweeps in card_data_profiles.dart.');
        });

        // The profile's data must reach the tree, or the 52 cells of `card.profile`
        // are pumping the default fixture and reporting green — see
        // [CardDataProfile.markers]. Measured at the desktop width so nothing is
        // absent for a density reason, in `en` because the markers are
        // untranslated.
        testWidgets(
            '${sweep.cardId} ${profile.key} data reaches the render (tab $tab)',
            (tester) async {
          final desktop = desktopCaseFor(spec);
          await probeCardOverflow(
            tester,
            cardId: sweep.cardId,
            widthCase: desktop,
            cardHeightRows: rows,
            tabIndex: tab,
            locale: const Locale('en'),
            extraOverrides: profile.overrides(),
            // The guard that keeps the 52 cells honest, so it belongs in the
            // dataset as much as they do: without it they can pump the default
            // fixture and pass. A port that dropped it would diff clean here and
            // silently turn the profile sweep into a duplicate of the plain one.
            cell: OverflowCell('card.profile_data', {
              'card': sweep.cardId,
              'profile': profile.key,
              'tab': tab,
              'px': desktop.widthKey,
            }),
          );
          for (final marker in profile.markers) {
            expect(find.textContaining(marker), findsWidgets,
                reason: '"$marker" is absent from ${sweep.cardId} tab $tab, so '
                    'the "${profile.key}" overrides did not reach the render. '
                    'The sweep would then be measuring the default fixture and '
                    'passing for the wrong reason. Check which provider the card '
                    'reads and that CardDataProfile.overrides layers over it.');
          }
        });
      }
    }
  });

  runOverflowSweep(
    family: CardProfileFamily(_gate),
    expectedCellCount: 52,
  );
}
