@Tags(['layout-gate'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/app_test_fonts.dart';
import '../util/overflow_baseline.dart';
import 'incident.dart';
import 'locale_tag.dart';
import 'screenshot.dart';
import 'sweep.dart';

/// The sweep runner's oracle (#1342).
///
/// Tagged `layout-gate` and **not** `overflow`, for the reason
/// `dart_test.yaml` gives: the second tag selects the five sweeps, and this file
/// is a framework self-test, next to `ratchet_test.dart` and
/// `overflow_probe_test.dart` rather than inside the pre-commit sweep set.
///
/// What it exists to prove is the part of #1342 that a baseline diff cannot see.
/// `./tool/overflow_baseline.sh check chrome` proves the chrome port measures the
/// same 1,248 coordinates it did before; it says nothing about *why* they were
/// still measured. These cases pin that: the identity the framework keys on, the
/// grouping policy §6 froze, and the three invariants of architecture doc §3.4 —
/// each one exercised rather than asserted in a comment, because a framework
/// whose invariants are only documented is how the gate ends up "faster, quieter,
/// blinder" (§9.3).
///
/// ## What each invariant is worth, measured (#1348)
///
/// R5's acceptance is that this file's claims are **executed**, not argued, so
/// every row below was applied to the working tree, run, and reverted on
/// 2026-08-22 at the R3 tip — F9 on 2026-08-24, once the `dev-2.7.0` merge made it
/// runnable, and F7′, F10 and F11 on the same day against #1364's and #1366's
/// fixes. "Killed by" is the
/// observed failure set, not the expected one. Where a mutation only becomes visible in the presence of a real
/// defect, the defect is named and the pair was run together — an invariant whose
/// removal is invisible on a clean tree is exactly the kind that gets refactored
/// away.
///
/// | # | mutation | killed by |
/// |---|---|---|
/// | F1 | drop the `KeyedSubtree(key: ValueKey(id))` wrapper (invariant 1) | 2 cases here (`INVARIANT 1: the same shape overflows again in the same test`, `the default verdict is the zero-tolerance one`) **and the popup sweep**, whose dataset flips 26 cells `clean` → `error` because its `onCellSettled` taps a form the stale tree left obscured. The card, forced-form and chrome datasets stay byte-identical. **With a real defect present it is worse than blind:** the same 104px overflow that 26 of 26 locales report on a clean framework is reported by **1 of 26** without the wrapper — the gate stays red only because the *first* locale happens to overflow. A `ru`-only defect would go green. |
/// | F2 | drop `_restoreSurfaceAfterTest(tester)` from `setLayoutSurface` (invariant 2) | 3 cases in `../util/overflow_probe_test.dart`, and **none here** — as `INVARIANT 2` below says in its own body, a test cannot watch its own teardown. The proof has to outlive the test that set the surface. |
/// | F3a | replace invariant 3's `catch` with a `rethrow` | 3 cases here. In a real sweep, with F1's throw as the defect: the throwing cell's record is still written (`"threw":true`, the collector got there first), but the coordinate aborts and **26 cells vanish from the dataset** — one per 3-locale coordinate, the locale that would have followed. `overflow_baseline.dart diff` calls that "coverage lost — this would otherwise read as a pass". With the `catch` in place the same throw kept all 347 cells and flagged 26. |
/// | F3b | drop `tester.takeException()` after the settle (invariant 3's build-phase half) | 2 cases here. |
/// | F4 | drop one coordinate (26 cells) from `CardWidthFamily.enumerate()` | `card.width enumerates 1638 cells` (1,638 → 1,612) **and** the #1337 baseline diff (26 cells "no longer measured"). Nothing else: the other 62 coordinate tests report the same green, and the dropped coordinate's own test simply stops existing. This is the whole case for `expectedCellCount` being required rather than defaulted. |
/// | F5 | `kOverflowTolerancePx` 2.0 → 200.0 | 5 cases — 4 here plus `kOverflowTolerancePx is still 2.0 and still reachable through the probe path` in `overflow_probe_test.dart`. |
/// | F5a | the same constant to **1.9** and to **2.1**, which is what #1348 actually asked for | **one case each, and it is the literal pin** — `kOverflowTolerancePx is still 2.0 …`. Nothing in this file notices either: the oracle's cases overflow by 1px and by 100px, so a ±0.1px move changes no verdict they assert on. Worth stating plainly, because F5's five killers make the constant look better defended than it is: what protects its *value* is one hand-written literal, and what the behavioural cases protect is the *shape* of the comparison. Both are needed, and only the gross mutation exercises both. |
/// | F5b | the significance filter's `>` → `>=`, i.e. the boundary itself | **Nothing, until this ticket.** The 1px case passes either way and no cell in any committed baseline overflows by exactly 2.0px, so neither the oracle nor the dataset could see the flip. Closed by `holds an incident of exactly kOverflowTolerancePx` below rather than filed as an issue, because the gap was five lines wide. |
/// | F6 | a dead `known_overflows.json` entry (a site nothing overflows at) | the ratchet's close phase, in `tearDownAll`, naming the site and telling the operator to delete the entry and its note. A second variant — `"*"` at a 500px ceiling against a real 104px overflow — is caught by the same phase with the tightening advice, and by *nothing else*: the sweep itself goes fully green, which is what the close phase is for. |
/// | F7 | empty `CardNormalBandFamily.onCardSettled` (the `expect` that the pumped form really is `normal`) | **Nothing on a clean tree — 102 of 102 green** (99 of 99 at #1348; re-run after the merge, since `dhcp_reservations`' new threshold gave the family a ninth coordinate). Paired with the `normalBandCaseFor` mutation the card table's row 3 uses, the killers dropped from **10 to 1**: the 9 coordinate tests all went quiet and only the `each threshold is realizable` meta-test still noticed. So the hook was worth 9 of those 10, and **234** cells would otherwise have kept measuring the wrong band in silence. The merge moved every figure in this row and moved the conclusion not at all — which is the point of re-running it rather than adjusting it. This was the executable substitute for "`onCellSettled` omitted", which is compile-enforced (the member is abstract) and so cannot be run as a mutation. **Closed by #1364**, below. |
/// | F7′ | the same premise after #1364, which moved it out of the body and onto the cell as `CardSweepCell.expectedDensity` | **Two mutations, one killer each, both named** (run 2026-08-24). Delete or empty `checkCardDensityPremise` — the framework half, in `CardOverflowFamily.onCellSettled` — and `the declared form premise a tree in another form fails, naming both and the reason` fails in `families/dashboard_card_gate_test.dart`, alone. Delete `expectedDensity:` from `CardNormalBandFamily.enumerate()` — the declaration half — and `the declared form premise every normal-band cell declares normal, and says why` fails, alone. Emptying `onCardSettled` is no longer a mutation at all: the body *is* empty now, which is the ticket's own answer to the two-empty-cases problem — a cell that declares no premise is answering the question, where an emptied body was not. A third mutation was run against the fix itself, because the check has an absence case: read the form with `selectedCardDensity` instead of `publishedCardDensity` and a tree that published *no* scope answers `normal` — the one value this band declares — so a card that lost its `CardDensityHost` would satisfy the premise having read nothing. Killed by `the declared form premise a tree with no scope at all fails rather than reading normal`, alone. Re-running F7's pairing against the fixed tree is what closes the row: the loosened `normalBandCaseFor` is killed by **10** again — the same 9 coordinates and `each threshold is realizable` — with the reason `enumerate()` declared quoted in each failure. And AC4's converse holds: all four baselines stay byte-identical at **3,616** cells, because this changes what the gate asserts and not what it measures. |
/// | F10 | the structural premise `ForcedCompactFloorFamily` and two more families held in their hook bodies — `find.byType(DashboardCardTemplate)` `findsOneWidget` plus `find.byType(CardPopupForm)` `findsNothing`, and the same shape in `ForcedPopupTileFamily` and `PopupFormFamily` | **Before #1366: nothing.** Emptying `ForcedCompactFloorFamily.onCardSettled` left the forced-form suite 38 of 38 green and the whole `layout-gate` tag **1,368 of 1,368** green. Paired with a real defect — `CardDensityHost` returning `_scope(CardDensity.popup)` for a cell that pinned an override, i.e. a picked form being ignored — the killers went from **7 to 0**: all 7 `forced_form.compact_floor` coordinates, and no overflow verdict among them, because the popup form is *smaller* than the compact one and fits the 261px box the coordinate is named after. So this is F7 one family over, with the fall-through half of the claim as the part that has teeth. `expectedDensity` was **not** the fix: these cells pin `compact` themselves, so declaring it would read back the override they set, while the defect publishes a popup scope the card obeys. **After #1366**, as `CardSweepCell.widgetPremises`: delete the check and `a required widget missing fails, naming it and the reason` + `a forbidden widget present fails, and says the smaller form fits` + `a failing premise stops the opener` fail; delete `widgetPremises:` from one enumeration and `the three premise families declare their structure, and say why` fails, alone, while the sweep stays 38 of 38 green. Re-running the pairing against the fix gives **7 again**, with the family's own reason quoted in each failure. |
/// | F11 | empty `PopupDialogFamily.onCardSettled` and `PickedPopupDialogFamily.onCardSettled` — which were `_openPresentation`, the tap that *opens the surface being measured* | **Before #1366: nothing, and this is the sharpest row in the table.** Both emptied left the popup suite **80 of 80 green** *and* `./tool/overflow_baseline.sh check popup` reporting **347 cells compared, identical**. So 78 cells stopped measuring the presentation and started measuring the 122px tile `popup.form` already covers — and the one tool built to answer "is the gate still measuring the same coordinates" cannot see it, because the cell id and the verdict are both unchanged and only the surface behind the id moved. A hook that produces its own subject is not an assertion that can be weakened; it is coverage that can be deleted. **After #1366**, as `CardSweepCell.openWith`: delete the execution in `CardOverflowFamily.onCellSettled` and `the declared opener runs, and runs before the hook` fails; delete `openWith:` from both enumerations and `the two dialog families declare the presentation opener` fails — alone, with the sweep still 80 of 80 green and the baseline still identical, which is the whole reason the oracle case has to exist. |
/// | F8 | revert #1328's top-bar fix (`git revert c3cd0bac`) | `chrome.top_bar` at **601, 640 and 700px** — exactly the three swept widths inside the 601–767px band — plus the icon-only presentation test. 600px and 768px, the immediate neighbours, stay clean. The per-width locale counts reproduce the band's shape: 22 of 26 locales at 601px, 13 at 640px, 2 (`nl`, `pl`) at 700px. Note the revert is not applicable as-is: the chrome suite references `kTopNavLabelMinWidth`, so reverting the constant too breaks compilation — a compile-time coupling between the fix and its gate. |
/// | F9 | revert #1321's DHCP fixture fix: the three `testDhcpClients` expiries back to `DateTime(2024, 6, 16, ...)` | **2 cases, and neither is a swept cell.** `default fixture conditional content dhcp_reservations renders it (tab 0)` (3 duration strings → 0) and `the shared fixture pins no absolute date …` (the source-literal check, naming all three lines). 1,360 of 1,362 pass: **every sweep in the tag goes green on the defect that #1321 was filed for**, because a stale expiry makes `leaseTimeFormatted` return the empty string, the trailing slot renders IP-only ~50px narrower than production's, and narrower never overflows. The density suite is green by construction, not by luck — it builds its own `DateTime.now().add(maxLease)` client and never reads this fixture. So what defends this fixture is one content assertion and one grep of its own source; the 3,616-cell gate cannot see it at all. That is the argument for both meta-tests existing, and the reason a fixture-freshness check is not something a sweep can subsume. |
///
/// F9 is the one row #1348 could not run: it needed #1321's fix present to revert,
/// and PR #1325 was open. It stays measured rather than dropped, and it is the row
/// that cost the least to run and said the most.
///
/// F7, F10 and F11 are one finding measured three times, and the progression is worth
/// reading in order: an assertion a family could delete (F7), the same thing in a
/// second family where a *smaller* form made the deletion doubly invisible (F10), and
/// a hook that was not asserting at all but *opening the surface* — where deletion
/// cost 78 cells of coverage and the tool built to detect exactly that reported
/// "identical" (F11). What the three have in common is that the gate was green and the
/// baseline was green, so the only possible detector is a test that reads the
/// declarations back. That is `families/dashboard_card_gate_test.dart`, and it is why
/// #1366's fix is half a mechanism and half an oracle.
void main() {
  setUpAll(() async {
    // The invariant tests below measure real overflow in pixels, so the Ahem
    // placeholder font would make every number fiction. They pump no text today
    // and would pass without this; loading it keeps the file honest if one ever
    // does.
    await loadAppFonts();
  });

  group('cell identity', () {
    test('names the family, then the axes in order, then the locale last', () {
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final id = overflowSweepCellId(
        family,
        _cell(
            axes: const {'screen_px': '640'}, locale: const Locale('zh', 'TW')),
      );

      expect(id, 'fake|screen_px=640|locale=zh_TW');
    });

    test('is the same string the baseline record is keyed on', () {
      // The one identity, single-sourced. The runner uses it for the
      // `KeyedSubtree` (invariant 1) *and* hands it to the collector as the
      // baseline coordinate, so a port cannot make the freshness key and the
      // dataset key drift apart — which is exactly how a re-keyed cell reads as
      // 1,248 coordinates lost and 1,248 found (`overflow_baselines.md` §2).
      final family = _FakeFamily(axisNames: const ['screen_px', 'mode']);
      final cell = _cell(
        axes: const {'screen_px': '320', 'mode': 'editing'},
        locale: const Locale('pl'),
      );

      expect(
        overflowSweepCellId(family, cell),
        overflowBaselineCellId(overflowSweepBaselineCell(family, cell)),
      );
    });

    test('spells the locale the way every other sweep does', () {
      // `zh_TW`, not `zh-TW` — the sixteenth family difference #1356 closed. The
      // runner reaches `localeTag()` rather than `Locale.toLanguageTag()`, and
      // this is the case that fails if someone "simplifies" it back.
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final cell = _cell(
        axes: const {'screen_px': '320'},
        locale: const Locale('zh', 'TW'),
      );

      expect(overflowSweepCellId(family, cell), endsWith('|locale=zh_TW'));
    });

    test('the coordinate label names the non-locale axes only', () {
      final cell = _cell(
        axes: const {'screen_px': '640', 'mode': 'viewing_local'},
        locale: const Locale('fr'),
      );

      expect(
        overflowSweepCoordinateLabel(cell),
        'screen_px=640 mode=viewing_local',
      );
    });
  });

  group('grouping policy', () {
    // §6, decided 2026-08-20 and frozen: group by every axis except locale, and
    // loop locale inside one test.
    test('one group per non-locale coordinate, locale inside it', () {
      final grouped = groupOverflowSweepCells([
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('pl')),
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('pl')),
      ]);

      expect(grouped.keys, ['screen_px=320', 'screen_px=768']);
      expect(grouped.values.map((cells) => cells.length), [2, 2]);
    });

    test('keeps the family\'s enumeration order', () {
      // Declaration order is the family's, not alphabetical: the test report
      // reads in the order the sweep sweeps, which is how a porter finds the
      // width they are looking at.
      final grouped = groupOverflowSweepCells([
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
      ]);

      expect(grouped.keys, ['screen_px=768', 'screen_px=320']);
    });

    test('a locale interleaved across coordinates still groups by coordinate',
        () {
      // The family is free to enumerate locale-major; the policy is not.
      final grouped = groupOverflowSweepCells([
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('pl')),
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('pl')),
      ]);

      expect(grouped.keys, ['screen_px=320', 'screen_px=768']);
      expect(
        grouped['screen_px=320']!.map((c) => c.locale.languageCode),
        ['en', 'pl'],
      );
    });
  });

  group('group and test names', () {
    test('the first axis names the group and the rest name the test', () {
      // §5 contract 1: `run_overflow_test.sh --name "$CARD_ID"` is an unanchored
      // substring match against the full name, so the first axis has to be the
      // *enclosing group* for `card=lan_info` to keep resolving after the port.
      final names = overflowSweepNames(_cell(
        axes: const {'card': 'lan_info', 'px': '191', 'tab': '0'},
        locale: const Locale('en'),
      ));

      expect(names.group, 'card=lan_info');
      expect(names.test, 'px=191 tab=0 lays out cleanly in every locale');
    });

    test('an axis value containing a space stays whole in the group name', () {
      // The names used to be recovered by splitting the coordinate label on
      // spaces, which named the group after the first *word* of a value. Nothing
      // forbids a spaced value — `chrome.header`'s mode axis read
      // `mode=viewing, local (3 actions)` until #1356, and only the id was made
      // prose-free — so the split would have collapsed two coordinates into one
      // group and broken contract 1 silently.
      final names = overflowSweepNames(_cell(
        axes: const {'card': 'network health', 'px': '191'},
        locale: const Locale('en'),
      ));

      expect(names.group, 'card=network health');
      expect(names.test, startsWith('px=191'));
    });

    test('a family with no axes is still declarable', () {
      // The count test is what reports "this family declares no axes", so the
      // sweep has to survive *declaring* one — a throw while naming groups
      // aborts the whole suite at load and the report never runs.
      final names = overflowSweepNames(
        _cell(axes: const {}, locale: const Locale('en')),
      );

      expect(names.group, '(no axes)');
      expect(names.test, 'lays out cleanly in every locale');
    });
  });

  group('enumeration integrity', () {
    // What the pinned cell count cannot see on its own. After the regrouping a
    // family reports 12 tests where it used to report 312, so "deliberately
    // regrouped" and "stopped enumerating" look identical (§6) — the literal
    // count closes the first hole and these three close the ones underneath it.
    test('a conforming enumeration reports nothing', () {
      final family = _FakeFamily(axisNames: const [
        'screen_px'
      ], cells: [
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('pl')),
      ]);

      expect(overflowSweepEnumerationProblems(family, family.enumerateCells()),
          isEmpty);
    });

    test('a cell that does not carry the declared axes is named', () {
      final family = _FakeFamily(axisNames: const [
        'screen_px',
        'mode'
      ], cells: [
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
      ]);

      expect(
        overflowSweepEnumerationProblems(family, family.enumerateCells())
            .join('\n'),
        allOf(contains('screen_px, mode'), contains('screen_px')),
      );
    });

    test('axes in the wrong order are named, because the id is ordered', () {
      // Not pedantry: the cell id is the axes in insertion order, so a family
      // that swaps two axes renames every cell it enumerates and the baseline
      // diff reports its whole coverage lost.
      final family = _FakeFamily(axisNames: const [
        'screen_px',
        'mode'
      ], cells: [
        _cell(
          axes: const {'mode': 'editing', 'screen_px': '320'},
          locale: const Locale('en'),
        ),
      ]);

      expect(overflowSweepEnumerationProblems(family, family.enumerateCells()),
          isNotEmpty);
    });

    test('two cells with one id are named, because one of them is not measured',
        () {
      // The count says 2 and the coverage is 1: the second pump overwrites the
      // first's row in the dataset and its `KeyedSubtree` key, so it is measured
      // in name only.
      final family = _FakeFamily(axisNames: const [
        'screen_px'
      ], cells: [
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
      ]);

      expect(
        overflowSweepEnumerationProblems(family, family.enumerateCells())
            .join('\n'),
        contains('fake|screen_px=320|locale=en'),
      );
    });

    test('declaring locale as an axis is named', () {
      // Locale is a field on the cell and the runner's inner loop, so a family
      // that also declares it as an axis would have it twice in the id.
      final family = _FakeFamily(axisNames: const ['screen_px', 'locale']);

      expect(
        overflowSweepEnumerationProblems(family, family.enumerateCells())
            .join('\n'),
        contains('locale'),
      );
    });

    test('a family with no axes at all is named', () {
      // Every axis except locale becomes the grouping, so a family with none
      // has no group to hang a test on — and §5 contract 1 has nothing to
      // resolve `--name "$CARD_ID"` against.
      final family = _FakeFamily(axisNames: const []);

      expect(overflowSweepEnumerationProblems(family, family.enumerateCells()),
          isNotEmpty);
    });
  });

  group('failure aggregation', () {
    test('names the locale count and every failing locale', () {
      final reason = overflowSweepFailureReason(
        familyName: 'chrome.top_bar',
        coordinateLabel: 'screen_px=640',
        failures: const ['pl: +47.0px right', 'fi: +12.0px right'],
        threwCount: 0,
      );

      expect(reason, contains('chrome.top_bar'));
      expect(reason, contains('overflowed at screen_px=640'));
      expect(reason, contains('in 2 locale(s)'));
      expect(reason, contains('pl: +47.0px right'));
      expect(reason, contains('fi: +12.0px right'));
    });

    test('says a cell threw rather than calling it an overflow', () {
      // "overflowed at 640px in 1 locale(s)" would be a lie about a cell whose
      // tree never finished building, and the two are remediated differently.
      final reason = overflowSweepFailureReason(
        familyName: 'chrome.header',
        coordinateLabel: 'screen_px=320 mode=editing',
        failures: const ['ru: threw Bad state: no fixture'],
        threwCount: 1,
      );

      expect(reason, contains('overflowed or threw'));
      expect(reason, contains('1 threw'));
      expect(reason, contains('ru: threw Bad state: no fixture'));
    });
  });

  group('measuring one cell', () {
    testWidgets('reports the overflow the cell produced, with its site',
        (tester) async {
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '100'},
          locale: const Locale('en'),
          surfaceSize: const Size(100, 200),
          build: () => _overflowingRow(childWidth: 300),
        ),
      );

      expect(verdict.error, isNull);
      expect(verdict.significant, hasLength(1));
      expect(verdict.significant.single.pixels, closeTo(200, 1));
      expect(verdict.significant.single.side, 'right');
      // The join key #1338 added, read off the same incident — proof the runner
      // reports through the one parser rather than re-reading the string.
      expect(verdict.significant.single.site, contains('sweep_test.dart'));
    });

    testWidgets('a cell that fits is measured and reports nothing',
        (tester) async {
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '400'},
          locale: const Locale('en'),
          surfaceSize: const Size(400, 200),
          build: () => _overflowingRow(childWidth: 100),
        ),
      );

      expect(verdict.failed, isFalse);
      expect(verdict.incidents, isEmpty);
    });

    testWidgets('holds an incident under tolerance without failing on it',
        (tester) async {
      // Recorded, not significant: the baseline dataset keeps every incident so
      // that loosening the filter cannot look like fixing a layout
      // (`overflow_baseline.dart`'s record builder), while the gate's verdict
      // still comes from `kOverflowTolerancePx`.
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '100'},
          locale: const Locale('en'),
          surfaceSize: const Size(100, 200),
          build: () => _overflowingRow(childWidth: 101),
        ),
      );

      expect(verdict.incidents, hasLength(1));
      expect(verdict.incidents.single.pixels, closeTo(1, 0.01));
      expect(verdict.significant, isEmpty);
      expect(verdict.failed, isFalse);
    });

    testWidgets('holds an incident of exactly kOverflowTolerancePx',
        (tester) async {
      // The boundary itself, and the only case that pins which comparison the
      // filter uses. #1348 mutated `> tolerancePx` to `>= tolerancePx` and
      // **nothing failed** — the 1px case above passes either way, and no cell in
      // any of the four committed baselines overflows by exactly 2.0px, so the
      // dataset could not report the flip either. A boundary no test names is a
      // boundary the next refactor gets to choose.
      //
      // Tolerated, not significant, because that is what the constant says it is:
      // `kOverflowTolerancePx` is documented as "the overflow every probe in this
      // suite ignores", and the ratchet grants the same figure inclusively
      // (`OverflowExemption.coversMagnitude`: `pixels <= maxOverflowPx +
      // kOverflowTolerancePx`). An exclusive filter here against an inclusive one
      // there would make 2.0px a failure the allowlist cannot exempt.
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '100'},
          locale: const Locale('en'),
          surfaceSize: const Size(100, 200),
          build: () => _overflowingRow(childWidth: 100 + kOverflowTolerancePx),
        ),
      );

      expect(verdict.incidents, hasLength(1));
      expect(
          verdict.incidents.single.pixels, closeTo(kOverflowTolerancePx, 0.01));
      expect(verdict.significant, isEmpty,
          reason: 'an overflow of exactly the tolerance is tolerated');
      expect(verdict.failed, isFalse);
    });

    testWidgets('INVARIANT 1: the same shape overflows again in the same test',
        (tester) async {
      // Flutter reports each `RenderFlex`'s overflow once per render-object
      // lifetime, so two pumps of one shape inside one `testWidgets` measure
      // the second cell as clean unless something forces a fresh subtree. That
      // is the trap the whole locale inner loop sits on, and the framework's
      // `KeyedSubtree(key: ValueKey(cell.key))` is what disarms it.
      final family = _FakeFamily(axisNames: const ['screen_px']);
      Future<OverflowCellVerdict> measure(String locale) => measureOverflowCell(
            tester,
            family: family,
            cell: _cell(
              axes: const {'screen_px': '100'},
              locale: Locale(locale),
              surfaceSize: const Size(100, 200),
              build: () => _overflowingRow(childWidth: 300),
            ),
          );

      final first = await measure('en');
      final second = await measure('pl');

      expect(first.significant, hasLength(1));
      expect(second.significant, hasLength(1),
          reason: 'the second cell must get its own render objects');
      expect(second.cellId, isNot(first.cellId));
    });

    testWidgets(
        'INVARIANT 3: a settled-cell hook that throws is that cell\'s failure',
        (tester) async {
      var settled = 0;
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onSettled: (tester, cell) async {
          settled++;
          if (cell.locale.languageCode == 'ru') {
            throw StateError('unreadable at ${cell.axes['screen_px']}');
          }
        },
      );
      Future<OverflowCellVerdict> measure(String locale) => measureOverflowCell(
            tester,
            family: family,
            cell: _cell(
              axes: const {'screen_px': '400'},
              locale: Locale(locale),
              surfaceSize: const Size(400, 200),
              build: () => _overflowingRow(childWidth: 100),
            ),
          );

      final thrown = await measure('ru');
      final next = await measure('fi');

      expect(thrown.error, isA<StateError>());
      expect(thrown.failed, isTrue);
      expect(thrown.summary, contains('threw'));
      expect(thrown.summary, contains('unreadable at 400'));
      expect(next.failed, isFalse,
          reason: 'one locale throwing must not take the next 25 with it');
      expect(settled, 2);
    });

    testWidgets(
        'INVARIANT 3: a host that throws while building is that cell\'s '
        'failure too', (tester) async {
      // The half of invariant 3 that no `catch` reaches. A build-phase error is
      // reported through `FlutterError.onError`, which `collector.dart` forwards
      // to the binding for anything that is not an overflow — so `pumpWidget`
      // returns normally, and before the runner claimed the pending exception
      // this cell's baseline row was written *unflagged*: measured-and-clean for
      // a tree that never built, which is the one reading
      // `overflow_baselines.md` §2 calls dangerous. The whole grouped test also
      // failed with a bare stack instead of the aggregated reason.
      //
      // That this test passes at all is the other half of the proof: an
      // untaken exception fails the test it happened in, so reaching the
      // assertions below means the runner cleared it.
      final family = _FakeFamily(axisNames: const ['screen_px']);
      Future<OverflowCellVerdict> measure(String locale,
              {required bool broken}) =>
          measureOverflowCell(
            tester,
            family: family,
            cell: _cell(
              axes: const {'screen_px': '400'},
              locale: Locale(locale),
              surfaceSize: const Size(400, 200),
              build: broken
                  ? _hostThatThrowsWhileBuilding
                  : () => _overflowingRow(childWidth: 100),
            ),
          );

      final broken = await measure('ru', broken: true);
      final next = await measure('fi', broken: false);

      expect(broken.error, isA<StateError>());
      expect(broken.failed, isTrue);
      expect(broken.summary, contains('no fixture'));
      expect(next.failed, isFalse,
          reason: 'the locales after a broken host must still be measured');
    });

    testWidgets('the settled-cell hook runs on the settled tree',
        (tester) async {
      // The hook is the readability slot, so it has to see the laid-out tree —
      // measured by finding a widget only the pumped host provides.
      Finder? seen;
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onSettled: (tester, cell) async {
          seen = find.byKey(const ValueKey('sweep-probe'));
          expect(seen!, findsOneWidget);
        },
      );

      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '400'},
          locale: const Locale('en'),
          surfaceSize: const Size(400, 200),
          build: () => _overflowingRow(childWidth: 100),
        ),
      );

      expect(seen, isNotNull);
      expect(verdict.failed, isFalse);
    });

    testWidgets('overflow raised inside the hook is still collected',
        (tester) async {
      // The hook runs inside the collector, which is what lets a family re-pump
      // (the card family's adjusted-screenshot capture does) and still have its
      // incidents attributed to the cell that produced them.
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onSettled: (tester, cell) async {
          await tester
              .pumpWidget(_overflowingRow(childWidth: 300, tag: 'hook'));
          await tester.pump();
        },
      );

      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '100'},
          locale: const Locale('en'),
          surfaceSize: const Size(100, 200),
          build: () => _overflowingRow(childWidth: 100),
        ),
      );

      expect(verdict.significant, hasLength(1),
          reason: 'the hook pumped an overflowing tree inside the collector');
    });

    testWidgets('INVARIANT 2: the tree is laid out at the cell\'s surface',
        (tester) async {
      // Only half of invariant 2, and the half a test can see from inside its
      // own body: the surface the cell asked for is the surface the tree was
      // measured in. The *reset* is registered by `setLayoutSurface` and runs in
      // teardown, after every assertion here, so proving it needs a test that
      // outlives the one that set it — which `overflow_probe_test.dart` already
      // is, by reading the surface the *previous* test left behind (#1340).
      // Naming the restore in this test would be a green check for something it
      // never looks at.
      Size? seen;
      await measureOverflowCell(
        tester,
        family: _FakeFamily(
          axisNames: const ['screen_px'],
          onSettled: (tester, cell) async {
            seen = tester.view.physicalSize;
          },
        ),
        cell: _cell(
          axes: const {'screen_px': '640'},
          locale: const Locale('en'),
          surfaceSize: const Size(640, 480),
          build: () => _overflowingRow(childWidth: 10),
        ),
      );

      expect(seen, const Size(640, 480));
    });
  });

  group('the family judges its own cells (#1343)', () {
    // The hook the card port needed. Everything the runner used to decide — this
    // overflow fails, that one does not — is now one overridable answer per cell,
    // and these cases are the only place the ratchet's shape can be proved without
    // a ratchet: a test cannot assert that another test failed, so the coordinate
    // loop is exercised directly.
    List<OverflowSweepCell> twoLocales({required double childWidth}) => [
          for (final tag in const ['de', 'pl'])
            _cell(
              axes: const {'screen_px': '100'},
              locale: Locale(tag),
              surfaceSize: const Size(100, 200),
              build: () => _overflowingRow(childWidth: childWidth),
            ),
        ];

    testWidgets('the default verdict is the zero-tolerance one',
        (tester) async {
      // What every family gets for free, and what the three unported sweeps keep:
      // any overflow past the tolerance is that locale's failure line.
      final family = _FakeFamily(axisNames: const ['screen_px']);

      final verdict = await measureOverflowCoordinate(
        tester,
        family: family,
        cells: twoLocales(childWidth: 300),
      );

      expect(verdict.failures, hasLength(2));
      expect(verdict.failures.first, startsWith('de: '));
      expect(verdict.failures.first, contains('200.0px'));
      expect(verdict.threwCount, 0);
    });

    testWidgets('a family may clear a cell the tolerance filter failed',
        (tester) async {
      // The ratchet in miniature: `known_overflows.json` says this site is leased,
      // so the overflow is real, recorded, and not blocking. Before #1343 the
      // runner had no way to be told that, which is why the card sweep could not
      // move onto it.
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onJudge: (cell, verdict) async => null,
      );

      final verdict = await measureOverflowCoordinate(
        tester,
        family: family,
        cells: twoLocales(childWidth: 300),
      );

      expect(verdict.failures, isEmpty);
      expect(family.judged, hasLength(2),
          reason: 'a cleared cell is still a judged cell');
    });

    testWidgets('the family\'s own words become the failure line',
        (tester) async {
      // The runner contributes the locale tag and nothing else, so the card
      // family's remediation paragraph survives intact.
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onJudge: (cell, verdict) async => 'shorten the label, or wrap it',
      );

      final verdict = await measureOverflowCoordinate(
        tester,
        family: family,
        cells: twoLocales(childWidth: 300).take(1),
      );

      expect(verdict.failures, ['de: shorten the label, or wrap it']);
    });

    testWidgets('every measured cell is judged, clean ones included',
        (tester) async {
      // Not an implementation detail: the ratchet finds an expired entry by
      // noticing that a site it leases stopped overflowing (#1321), and a family
      // counts what it measured to know whether its coverage was complete. A hook
      // that only fired on failures would have left both to the runner.
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onJudge: (cell, verdict) async => null,
      );

      final verdict = await measureOverflowCoordinate(
        tester,
        family: family,
        cells: twoLocales(childWidth: 10),
      );

      expect(verdict.failures, isEmpty);
      expect(family.judged, [
        'fake|screen_px=100|locale=de',
        'fake|screen_px=100|locale=pl',
      ]);
    });

    testWidgets('a cell that threw is never judged', (tester) async {
      // There is no measurement to judge, and its dataset row is already flagged
      // `threw`. Handing it over would also let a family count it as measured,
      // turning a hole in the run into a green coverage claim.
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onJudge: (cell, verdict) async => null,
      );

      final verdict = await measureOverflowCoordinate(
        tester,
        family: family,
        cells: [
          _cell(
            axes: const {'screen_px': '100'},
            locale: const Locale('ru'),
            surfaceSize: const Size(100, 200),
            build: _hostThatThrowsWhileBuilding,
          ),
          ...twoLocales(childWidth: 10).take(1),
        ],
      );

      expect(family.judged, ['fake|screen_px=100|locale=de']);
      expect(verdict.failures, hasLength(1));
      expect(verdict.failures.single, startsWith('ru: threw'));
      expect(verdict.threwCount, 1);
    });

    testWidgets('a judge that throws fails its cell, not the coordinate',
        (tester) async {
      // INVARIANT 3 one step later, and the step most able to break for an
      // unrelated reason: the judge is where a family does its I/O — the card
      // family writes two PNGs and a report row from here — so a full disk in `de`
      // must not cost the other 25 locales their measurement.
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onJudge: (cell, verdict) async {
          if (localeTag(cell.locale) == 'de') throw StateError('no disk');
          return null;
        },
      );

      final verdict = await measureOverflowCoordinate(
        tester,
        family: family,
        cells: twoLocales(childWidth: 10),
      );

      expect(family.judged, hasLength(2),
          reason: 'pl must still be measured and judged after de raised');
      expect(verdict.failures, hasLength(1));
      expect(verdict.failures.single,
          'de: threw while judging: Bad state: no disk');
      expect(verdict.threwCount, 1,
          reason: 'a judge that raised is remediated like a broken host, not '
              'like an overflow');
    });
  });

  group('a narrowed run does not pin a subset (#1343)', () {
    test('a family declares no enumeration gaps by default', () {
      // The pin is checked for every family that cannot be narrowed, which is
      // four of the five sweeps — every one but the card sweep, whose LOCALE /
      // MIN_SCREEN / -c knobs are the only narrowing the family set has.
      expect(_FakeFamily(axisNames: const ['screen_px']).enumerationGaps(),
          isEmpty);
    });

    test('an unnarrowed run pins its count', () {
      expect(
        overflowSweepCountAction(
            enumerated: 1638, expectedCellCount: 1638, gaps: const []),
        OverflowSweepCountAction.pin,
      );
    });

    test('a family that narrowed itself is what makes the pin skip', () {
      // The composition `runOverflowSweep` performs, with the family's own answer
      // feeding it: the count test cannot be observed from here (it is declared at
      // top level), so the decision is what this proves.
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        gaps: const ['--dart-define=LOCALE selected 1 of 26 locales'],
      );

      expect(
        overflowSweepCountAction(
          enumerated: 63,
          expectedCellCount: 1638,
          gaps: family.enumerationGaps(),
        ),
        OverflowSweepCountAction.skip,
      );
    });

    test('a narrowing that matched nothing fails instead of skipping', () {
      // The hole the skip branch opened, and the one state a gate may never be
      // green in. `LOCALE=zz` matches no shipped locale, so all three card
      // families multiply out to zero cells and every pin would skip with an
      // accurate note — a suite reporting success over nothing rendered.
      expect(
        overflowSweepCountAction(
          enumerated: 0,
          expectedCellCount: 1638,
          gaps: const ['--dart-define=LOCALE selected 0 of 26 locales'],
        ),
        OverflowSweepCountAction.failEmpty,
      );

      final failure = overflowSweepEmptyRunFailure(
        familyName: 'card.width',
        expectedCellCount: 1638,
        gaps: const ['--dart-define=LOCALE selected 0 of 26 locales'],
      );

      expect(failure, contains('card.width enumerated no cells at all'));
      expect(failure, contains('against the 1638'));
      expect(failure, contains('selected 0 of 26 locales'),
          reason: 'the gap names the define, which is where the typo is');
      expect(failure, contains('never measuring nothing'));
    });

    test('the skip note names both counts and every gap', () {
      // `-L de` is the run this exists for: 63 cells of 1,638, on purpose, and the
      // pin cannot be made from it. Skipping says so; passing would be the #1321
      // failure again, and failing would break §5 contract 3.
      final note = overflowSweepCountSkipNote(
        familyName: 'card.width',
        enumerated: 63,
        expectedCellCount: 1638,
        gaps: const ['LOCALE=de narrowed 26 locales to 1'],
      );

      expect(note, contains('card.width enumerated 63 cells'));
      expect(note, contains('not the 1638 this sweep pins'));
      expect(note, contains('LOCALE=de narrowed 26 locales to 1'));
      expect(note, contains('Run the sweep unfiltered'));
    });
  });

  group('the cell screenshot dump', () {
    /// A dump pointed at a fresh directory, installed for one test.
    ///
    /// The runner reads a library-level variable rather than the environment
    /// directly, which is what makes this observable at all: `OVERFLOW_PNG` is set
    /// by `tool/overflow_baseline.sh` and a test cannot set it for itself.
    OverflowScreenshotDump install(String pattern) {
      final dir = Directory.systemTemp.createTempSync('overflow-shots');
      addTearDown(() {
        overflowScreenshotDump = OverflowScreenshotDump.off();
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      return overflowScreenshotDump =
          OverflowScreenshotDump(pattern: pattern, dir: dir.path);
    }

    /// [childWidth] against a 100px surface is what decides the verdict: 50 fits,
    /// 101 overflows by one pixel (under the 2px tolerance, so not a failure), and
    /// 300 overflows by 200.
    Future<OverflowCellVerdict> measure(
      WidgetTester tester, {
      required String screenPx,
      String locale = 'en',
      double childWidth = 50,
      Widget Function()? build,
    }) {
      return measureOverflowCell(
        tester,
        family: _FakeFamily(axisNames: const ['screen_px']),
        cell: _cell(
          axes: {'screen_px': screenPx},
          locale: Locale(locale),
          surfaceSize: const Size(100, 200),
          build: build ?? () => _overflowingRow(childWidth: childWidth),
        ),
      );
    }

    test('is off until something turns it on', () {
      // The gate's default. Read from the environment on first use, and
      // `tool/overflow_baseline.sh` only sets `OVERFLOW_PNG` in its `shoot` mode —
      // so every capture, check and PR-gate run allocates no key and writes no
      // file. A dump mode that were on by default would put 4,032 PNGs and
      // several minutes of encoding into the PR gate.
      expect(OverflowScreenshotDump.off().enabled, isFalse);
      expect(OverflowScreenshotDump.off().wants('fake|screen_px=100|locale=en'),
          isFalse);
      expect(
        OverflowScreenshotDump(pattern: 'all', dir: '').enabled,
        isFalse,
        reason: 'a pattern with nowhere to write is not a dump',
      );
    });

    testWidgets('writes nothing when it is off', (tester) async {
      final dir = Directory.systemTemp.createTempSync('overflow-shots-off');
      addTearDown(() {
        overflowScreenshotDump = OverflowScreenshotDump.off();
        dir.deleteSync(recursive: true);
      });
      // A real, writable directory and no pattern — the half of "off" that is easy
      // to get wrong, because `shoot` gives `OVERFLOW_PNG_DIR` a default and gives
      // `OVERFLOW_PNG` none. Not even the manifest may appear: an empty index is
      // indistinguishable from a run whose images were deleted.
      overflowScreenshotDump =
          OverflowScreenshotDump(pattern: '', dir: dir.path);

      final verdict = await measure(tester, screenPx: '100');

      expect(verdict.error, isNull);
      expect(dir.listSync(), isEmpty);
    });

    testWidgets('shoots the cells the pattern names, and no others',
        (tester) async {
      // The pattern is the whole selector: no verdict is consulted, so this mode
      // photographs cells that *passed* — which is the case the gate is blind to by
      // construction (four cards pass at 191px rendering unreadably, #1240 AC1) and
      // the reason the dump exists at all.
      final dump = install('locale=ar');

      await measure(tester, screenPx: '100', locale: 'ar');
      await measure(tester, screenPx: '100', locale: 'ru');

      expect(dump.written.keys, ['fake|screen_px=100|locale=ar']);
    });

    testWidgets('`all` shoots every measured cell', (tester) async {
      final dump = install(kOverflowScreenshotAll);

      await measure(tester, screenPx: '100', locale: 'ar');
      await measure(tester, screenPx: '200', locale: 'ru');

      expect(dump.written, hasLength(2));
      for (final name in dump.written.values) {
        expect(File('${dump.dir}/$name').lengthSync(), greaterThan(0));
      }
    });

    testWidgets('`failed` shoots what overflowed and nothing that fitted',
        (tester) async {
      // The second selector, and the one a person actually reaches for when a
      // sweep goes red: the failures are what they want to look at, and their ids
      // are exactly what they do not want to retype. `all` on the page sweep is 416
      // images to find three in.
      //
      // It costs one thing the pattern modes do not: the boundary must be in place
      // *before* the pump, when no verdict exists yet, so `failed` wraps every cell
      // and throws most of the wrappers away. The claim that this moves nothing is
      // pinned by the case below and, at dataset scale, by `check` after a shoot.
      final dump = install(kOverflowScreenshotFailed);

      final fitted = await measure(tester, screenPx: '100');
      final overflowed = await measure(tester, screenPx: '200', childWidth: 300);

      expect(fitted.significant, isEmpty);
      expect(overflowed.significant, hasLength(1));
      expect(dump.written.keys, ['fake|screen_px=200|locale=en']);
      expect(
        File('${dump.dir}/${dump.written.values.single}').lengthSync(),
        greaterThan(0),
      );
    });

    testWidgets('`failed` on a green sweep writes nothing at all',
        (tester) async {
      // Which is what makes it safe to leave on: the common case is a green tree,
      // and there the mode must leave no trace — not even a manifest, since an
      // empty index reads the same as a run whose images were deleted.
      final dump = install(kOverflowScreenshotFailed);

      await measure(tester, screenPx: '100');
      await measure(tester, screenPx: '200');

      expect(dump.written, isEmpty);
      expect(Directory(dump.dir).listSync(), isEmpty);
    });

    testWidgets('`failed` uses the verdict\'s own bar, not "any incident"',
        (tester) async {
      // A one-pixel overflow is an incident and not a failure — `kOverflowTolerance`
      // absorbs mac↔CI sub-pixel shaping. If the dump read `incidents` instead of
      // `significant` it would photograph cells the report calls clean, and the
      // gallery would disagree with the rows beside it.
      final dump = install(kOverflowScreenshotFailed);

      final verdict = await measure(tester, screenPx: '100', childWidth: 101);

      expect(verdict.incidents, hasLength(1));
      expect(verdict.significant, isEmpty);
      expect(dump.written, isEmpty);
    });

    testWidgets('`failed` photographs a cell that threw', (tester) async {
      // A cell whose pump died is a failure too, and the picture of it is Flutter's
      // red error box naming the throw — which is worth having when the throw is
      // some family's `onCellSettled` rather than a build error. The capture runs in
      // the `catch` branch, so it must not be able to replace the error it is
      // documenting: the verdict below still carries the original throw.
      final dump = install(kOverflowScreenshotFailed);

      final verdict = await measure(
        tester,
        screenPx: '100',
        build: _hostThatThrowsWhileBuilding,
      );

      expect(verdict.error, isA<StateError>());
      expect(verdict.error.toString(), contains('no fixture'));
      expect(dump.written.keys, ['fake|screen_px=100|locale=en']);
    });

    testWidgets('wrapping every cell for `failed` measures the same pixels',
        (tester) async {
      // The cost of the pre-pump boundary, stated as a test. A `RepaintBoundary`
      // adds a layer, not a constraint, so the geometry under it is unchanged — but
      // "unchanged" is the entire premise of shooting a dataset and comparing it to
      // a committed one, so it is asserted rather than assumed.
      overflowScreenshotDump = OverflowScreenshotDump.off();
      final bare = await measure(tester, screenPx: '100', childWidth: 300);

      install(kOverflowScreenshotFailed);
      final wrapped = await measure(tester, screenPx: '100', childWidth: 300);

      expect(bare.significant.single.pixels, 200.0);
      expect(wrapped.significant.single.pixels, bare.significant.single.pixels);
      expect(wrapped.significant.single.side, bare.significant.single.side);
      expect(wrapped.significant.single.site, bare.significant.single.site);
    });

    testWidgets('records what it wrote in a manifest keyed by cell id',
        (tester) async {
      // The join between the two halves of this feature, and the reason there is
      // no second copy of the filename rule. `render` reads this file rather than
      // deriving a name from the cell id itself — the deriving happens in one
      // program, and the other is told the answer. `test_scripts/` cannot import
      // `test/` (it runs under a bare `dart run`), so a shared rule would have
      // been two rules that must never disagree.
      final dump = install(kOverflowScreenshotAll);

      await measure(tester, screenPx: '100', locale: 'ar');

      final manifest = File(dump.manifestPath).readAsLinesSync();
      expect(manifest.first, '# $kOverflowScreenshotManifestFormat');
      expect(
        manifest[1],
        'fake|screen_px=100|locale=ar\t'
        '${dump.written['fake|screen_px=100|locale=ar']}',
      );
    });

    testWidgets('a shoot that cannot write does not change the verdict',
        (tester) async {
      // The one behaviour that makes this safe to leave in the runner at all. A
      // capture happens after the measurement and before the judge, so anything it
      // raises would otherwise be attributed to the cell by invariant 3 — and a
      // mistyped `OVERFLOW_PNG_DIR` would turn a green sweep into 4,032 cells that
      // "threw". The verdict below is the same one the same cell reports with the
      // dump off.
      final blocker = Directory.systemTemp.createTempSync('overflow-shots-bad');
      File('${blocker.path}/a-file').writeAsStringSync('not a directory');
      addTearDown(() {
        overflowScreenshotDump = OverflowScreenshotDump.off();
        blocker.deleteSync(recursive: true);
      });
      overflowScreenshotDump = OverflowScreenshotDump(
        pattern: kOverflowScreenshotAll,
        // A path *under a file*, so neither `create(recursive: true)` nor the
        // manifest's write can succeed however the platform spells the errno.
        dir: '${blocker.path}/a-file/shots',
      );

      final verdict = await measure(tester, screenPx: '100');

      expect(verdict.error, isNull);
      expect(verdict.incidents, isEmpty);
      expect(overflowScreenshotDump.written, isEmpty);
    });

    test('a file name is derived from the cell id, and stays unique', () {
      // Browsable on purpose: the folder is opened by a person comparing widths,
      // so `card.width__card-lan_info__px-191__locale-ar.png` is worth more than a
      // serial number. The characters the id grammar uses are the ones a shell and
      // a URL both dislike, hence the mapping.
      final taken = <String>{};
      expect(
        overflowScreenshotFileName('page.dhcp|screen_px=320|locale=ar',
            taken: taken),
        'page.dhcp__screen_px-320__locale-ar.png',
      );

      // An axis *value* may carry prose — `chrome.header`'s mode axis read
      // `mode=viewing, local (3 actions)` until #1356 — so two distinct ids can
      // sanitise to one name. The manifest would then have two rows pointing at
      // one image, and the report would show the wrong screenshot for a cell,
      // which is the failure mode this whole feature exists to avoid.
      final first = overflowScreenshotFileName('c|m=a b', taken: taken);
      final second = overflowScreenshotFileName('c|m=a_b', taken: taken);
      expect(first, isNot(second));
      expect(second, contains('~2'));
    });
  });
}

/// A `Row` that overflows by `childWidth - surfaceWidth` and nothing else.
///
/// [tag] keys the tree so a caller can pump two of them; the runner keys the
/// subtree it wraps this in, which is what invariant 1's case measures.
Widget _overflowingRow({required double childWidth, String tag = 'cell'}) {
  return MaterialApp(
    key: ValueKey('sweep-host-$tag'),
    home: Scaffold(
      body: Row(
        children: [
          SizedBox(
            key: const ValueKey('sweep-probe'),
            width: childWidth,
            height: 10,
          ),
        ],
      ),
    ),
  );
}

/// A host that fails the way a real one does: during build, so the error goes to
/// `FlutterError.onError` and `pumpWidget` returns as if nothing happened.
///
/// A missing fixture, a provider whose override was dropped and a null-asserted
/// localisation all arrive here.
Widget _hostThatThrowsWhileBuilding() {
  return MaterialApp(
    home: Builder(builder: (_) => throw StateError('no fixture')),
  );
}

OverflowSweepCell _cell({
  required Map<String, Object?> axes,
  required Locale locale,
  Size surfaceSize = const Size(400, 800),
  Widget Function()? build,
}) {
  return OverflowSweepCell(
    axes: axes,
    locale: locale,
    surfaceSize: surfaceSize,
    build: build ?? () => const SizedBox.shrink(),
  );
}

/// `extends`, not `implements`: [OverflowSurfaceFamily.judgeCell] and
/// [OverflowSurfaceFamily.enumerationGaps] have defaults, and inheriting them is
/// what lets the cases below assert what a family gets for free.
class _FakeFamily extends OverflowSurfaceFamily {
  _FakeFamily({
    required this.axisNames,
    List<OverflowSweepCell>? cells,
    Future<void> Function(WidgetTester, OverflowSweepCell)? onSettled,
    Future<String?> Function(OverflowSweepCell, OverflowCellVerdict)? onJudge,
    List<String> gaps = const [],
  })  : _cells = cells ?? const [],
        _onSettled = onSettled,
        _onJudge = onJudge,
        _gaps = gaps;

  final List<OverflowSweepCell> _cells;
  final Future<void> Function(WidgetTester, OverflowSweepCell)? _onSettled;
  final Future<String?> Function(OverflowSweepCell, OverflowCellVerdict)?
      _onJudge;
  final List<String> _gaps;

  /// Every cell the judge saw, clean ones included — the ratchet's liveness ledger
  /// depends on getting those, so a case has to be able to check it.
  final List<String> judged = [];

  @override
  String get name => 'fake';

  @override
  final List<String> axisNames;

  @override
  Iterable<OverflowSweepCell> enumerateCells() => _cells;

  @override
  Future<void> onCellSettled(
      WidgetTester tester, OverflowSweepCell cell) async {
    await _onSettled?.call(tester, cell);
  }

  @override
  Future<String?> judgeCell(
    WidgetTester tester,
    OverflowSweepCell cell,
    OverflowCellVerdict verdict,
  ) async {
    judged.add(verdict.cellId);
    final judge = _onJudge;
    if (judge == null) return super.judgeCell(tester, cell, verdict);
    return judge(cell, verdict);
  }

  @override
  List<String> enumerationGaps() => _gaps;
}
