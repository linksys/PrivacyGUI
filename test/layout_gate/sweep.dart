/// The layout gate's one sweep runner (#1342).
///
/// ## Why a declarative runner rather than a helper
///
/// Every sweep in the #1183 family does the same seven things per coordinate —
/// set the surface, pump a fresh subtree, settle it, ask the family whether the
/// result is *readable*, filter by tolerance, record the coordinate, aggregate
/// the verdict — and before this file each of them did all seven by hand. Twelve
/// of the fifteen differences `doc/testing/overflow_gate_architecture.md` §1.1
/// aligned are that duplication; [runOverflowSweep] is where they go.
///
/// It has to be a **top-level declarative function**, shaped like
/// `runViewGoldenTests(GoldenTestConfig)`: it *declares* tests, and is never
/// awaited inside one. Flutter reports each `RenderFlex`'s overflow **once per
/// render-object lifetime**, so a loop inside a single `testWidgets` silently
/// measures every cell after the first as clean unless something forces a fresh
/// subtree. Both existing frameworks dodged that — the card sweep with one test
/// per cell, the chrome sweep with a hand-written `cellKey` — and a dodge each
/// family has to remember is a dodge one of them will forget. Declaring the tests
/// here keeps the decision in the framework's hands (invariant 1 below).
///
/// ## What a family owns, and what it does not
///
/// A family answers exactly two questions: **which coordinates exist**
/// ([OverflowSurfaceFamily.enumerateCells]) and **how one coordinate becomes a
/// host widget** ([OverflowSweepCell.build]). Those are two of the three
/// essential differences of §2; the third — whether overflow is monotone in
/// width — is an *argument*, not code, and lives in the family's own doc comment
/// because the card family's axes rest on it and the chrome family's failure band
/// (601–767px, clean water either side) disproves it. Nothing here assumes
/// either.
///
/// ## The three invariants this file owns (§3.4)
///
/// 1. **Every cell host is wrapped in `KeyedSubtree(key: ValueKey(cell id))`** —
///    see above. It also upgrades "several pumps in one test" from a trap into a
///    safe operation, which the card family needs for its screenshot capture.
/// 2. **The surface is set and reset in one place** — through
///    [setLayoutSurface] (#1340), which registers the restore itself.
/// 3. **A per-cell exception is recorded as that cell's failure.** This is the
///    precondition that makes the locale inner loop safe: one locale throwing a
///    non-overflow exception must not take the other 25 down with it.
///
/// ## Grouping policy: fixed, not configurable
///
/// **Group by every axis except locale, and loop locale inside one test**
/// (decided 2026-08-20, §6). Locale is universally the highest-cardinality and
/// most aggregatable axis, and `top bar overflowed at 640px in 7 locale(s)` is
/// materially easier to act on than seven red tests that each have to be opened.
/// Invariant 3 is what removes the isolation cost that would otherwise make this
/// a trade.
///
/// Two things are therefore **required rather than defaulted**, and each closes a
/// hole the policy opens:
///
/// * **`expectedCellCount`.** After the regrouping, "deliberately regrouped" and
///   "accidentally stopped enumerating 800 cells" look identical in the report.
///   #1321 is the standing proof: a fixture whose lease expired in 2024 turned a
///   red gate green and nothing said so.
/// * **[OverflowSurfaceFamily.onCellSettled]**, which is an abstract member and
///   so cannot be omitted or defaulted. A sweep that only checks overflow can be
///   fully green while text is truncated to nothing — measured, four dashboard
///   cards pass at 191px rendering unreadably. Writing an empty body is allowed;
///   not noticing that you did is not.
///
/// ## What it deliberately does not do yet
///
/// No ratchet and no report. The chrome family needs neither, and #1343 — the
/// main card sweep, the only family carrying `known_overflows.json`, PNG dumps
/// and `OverflowReportItem` — is where those hooks take shape, with a real
/// consumer to shape them. An unused hook would be a guess with no way to be
/// wrong.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/overflow_baseline.dart';
import 'collector.dart';
import 'incident.dart';
import 'locale_tag.dart';
import 'surface.dart';

/// One measurable coordinate: enough to pump exactly one tree, plus a stable
/// identity for the dataset, the freshness key and the test name.
///
/// ## Why this is not `OverflowCell`
///
/// [OverflowCell] (`test/util/overflow_baseline.dart`) is the *dataset's*
/// coordinate — a sweep name and its axes, and nothing about how to render it —
/// and it is what #1337's committed baselines are keyed on. This type is the
/// runner's superset: the same coordinate plus the locale, the surface and the
/// builder. They are kept apart rather than merged because the baseline library
/// is imported by three sweeps that have not been ported yet, and because a
/// duplicate *definition* of one name is the one thing Dart will not tolerate
/// (`collector.dart`'s header records the same reasoning). [overflowSweepBaselineCell]
/// is the one-line bridge, so there is exactly one place the two can disagree.
class OverflowSweepCell {
  const OverflowSweepCell({
    required this.axes,
    required this.locale,
    required this.surfaceSize,
    required this.build,
  });

  /// The non-locale coordinate, in reading order.
  ///
  /// Insertion order is load-bearing: it becomes the cell id, which is what
  /// #1337's dataset joins on and what a porter greps. Locale is deliberately
  /// **not** in here — it is [locale], because the grouping policy has to be able
  /// to tell it apart from every other axis, and a magic axis name would be a
  /// second spelling of the same fact.
  final Map<String, Object?> axes;

  /// The locale this coordinate is measured in; the runner's inner loop.
  final Locale locale;

  /// The viewport the tree is laid out in, set through [setLayoutSurface].
  final Size surfaceSize;

  /// Builds the host. Called once per measurement, inside the collector.
  final Widget Function() build;
}

/// The three essential differences, and only those.
///
/// Implementations live centrally under `test/layout_gate/families/` (frozen with
/// the grouping decision): a family is the framework's other half, not a detail
/// of the suite that declares it, and `test/page/**` is where the *suites* live.
abstract class OverflowSurfaceFamily {
  /// `chrome.top_bar` / `card.width` — namespaces the dataset and the report.
  ///
  /// It is the `<baseline>.<group>` of [OverflowCell.sweep], so renaming it reads
  /// as every cell of that group disappearing and an equal number of new cells
  /// appearing. That is the correct verdict, and it is why the name is the
  /// family's rather than the suite's.
  String get name;

  /// The non-locale axis names, in the order [OverflowSweepCell.axes] carries
  /// them.
  ///
  /// Two jobs. The first name becomes the enclosing `group`, which is what keeps
  /// §5 contract 1 (`run_overflow_test.sh --name "$CARD_ID"`) resolvable by
  /// construction. All of them are the conformance check
  /// [overflowSweepEnumerationProblems] runs, so a family cannot quietly emit a
  /// differently-keyed cell.
  List<String> get axisNames;

  /// Every coordinate this family measures. Called once, at declaration time.
  Iterable<OverflowSweepCell> enumerateCells();

  /// Runs once the cell has settled, still inside the overflow collector.
  ///
  /// The readability slot, and abstract on purpose — see the library header. Free
  /// to pump again: invariant 1 makes that safe, and anything it raises is
  /// attributed to this cell.
  Future<void> onCellSettled(WidgetTester tester, OverflowSweepCell cell);
}

/// The dataset's coordinate for [cell]: the family's axes, then the locale.
///
/// Locale goes last because that is where all four committed baselines already
/// have it (`chrome.header|screen_px=1024|mode=editing|locale=ar`,
/// `card.width|card=connected_devices|width=min|px=191|tab=0|locale=ar`), and a
/// port that moved it would rename 3,587 rows to say the same thing.
OverflowCell overflowSweepBaselineCell(
  OverflowSurfaceFamily family,
  OverflowSweepCell cell,
) {
  return OverflowCell(family.name, {
    ...cell.axes,
    'locale': localeTag(cell.locale),
  });
}

/// The one identity: `family|axis=value|…|locale=tag`.
///
/// Used for the `KeyedSubtree` key *and* the baseline record, deliberately the
/// same string. Two identities would be two things a port can silently
/// re-spell — and re-keying a cell reads as its whole coverage lost, which
/// `overflow_baselines.md` §2 tells a porter to treat as the dangerous case.
String overflowSweepCellId(
  OverflowSurfaceFamily family,
  OverflowSweepCell cell,
) =>
    overflowBaselineCellId(overflowSweepBaselineCell(family, cell));

/// One axis as `name=value` — the spelling every readable name here is built
/// from, so the group name, the test name and the failure subject cannot drift.
String _axisAssignment(MapEntry<String, Object?> axis) =>
    '${axis.key}=${axis.value}';

/// The non-locale coordinate as prose: `screen_px=640 mode=editing`.
///
/// Space-separated rather than pipe-separated, because this one is read by people
/// — it is the grouping key and the subject of the aggregated failure.
///
/// **Display and grouping only; never parsed back.** [runOverflowSweep] takes the
/// group and test names from a cell's own axes rather than splitting this string,
/// because an axis value may contain spaces — `chrome.header`'s mode axis read
/// `mode=viewing, local (3 actions)` until #1356, and only its *id* was made
/// prose-free. Recovering structure from this by `split(' ')` would have named
/// the group after the first word of a value.
String overflowSweepCoordinateLabel(OverflowSweepCell cell) =>
    cell.axes.entries.map(_axisAssignment).join(' ');

/// Groups [cells] by their non-locale coordinate, preserving enumeration order.
///
/// This is the grouping policy of §6 as one function: every key becomes one
/// `testWidgets`, and its value is that test's locale loop. Enumeration order is
/// kept so the report reads in the order the family sweeps, whatever order the
/// family chose to nest its loops in.
Map<String, List<OverflowSweepCell>> groupOverflowSweepCells(
  Iterable<OverflowSweepCell> cells,
) {
  final grouped = <String, List<OverflowSweepCell>>{};
  for (final cell in cells) {
    grouped.putIfAbsent(overflowSweepCoordinateLabel(cell), () => []).add(cell);
  }
  return grouped;
}

/// The `group` and `testWidgets` names for one coordinate: the first axis names
/// the group, the rest name the test.
///
/// §5 contract 1 is this function. `tool/run_overflow_test.sh:199` passes
/// `--name "$CARD_ID"` — an unanchored substring match against the full test
/// name — so the first axis being the *enclosing group* is what keeps
/// `card=lan_info` resolvable by construction rather than by convention.
///
/// Built from the cell's axes rather than by splitting
/// [overflowSweepCoordinateLabel], because an axis value may contain spaces; see
/// there. Extracted rather than inlined into [runOverflowSweep] so the contract
/// is assertable from a test instead of only from a test *report*.
({String group, String test}) overflowSweepNames(OverflowSweepCell cell) {
  final assignments = cell.axes.entries.map(_axisAssignment).toList();
  return (
    // A family with no axes has no first axis. That is one of the problems the
    // count test reports, and it has to stay *declarable* for that report to run
    // at all — hence a placeholder rather than an exception at load.
    group: assignments.isEmpty ? '(no axes)' : assignments.first,
    test: [
      ...assignments.skip(1),
      'lays out cleanly in every locale',
    ].join(' '),
  );
}

/// Everything wrong with what [family] enumerates, as sentences.
///
/// The pinned cell count answers "did we stop enumerating"; these answer the
/// questions underneath it, each of which lets a count of 312 stand for less
/// than 312 measurements:
///
/// * **A cell that does not carry the declared axes**, or carries them in
///   another order. The id is the axes in insertion order, so either one renames
///   every cell of the sweep.
/// * **Two cells with one id.** The second overwrites the first's dataset row and
///   shares its freshness key, so it is measured in name only.
/// * **`locale` declared as an axis**, which would put it in the id twice.
/// * **No axes at all**, which leaves the grouping with nothing to name a group
///   after and §5 contract 1 with nothing to resolve `--name` against.
///
/// Returned rather than thrown: [runOverflowSweep] reports them from a test, so a
/// malformed family goes red in the one place a reader is looking instead of
/// aborting the whole suite at load with a stack trace.
///
/// [cells] is what the family already enumerated, passed in rather than
/// re-enumerated here, so [OverflowSurfaceFamily.enumerateCells] is called
/// exactly once per declaration as its contract says — 1,248 cells for chrome,
/// and #1343's family is seven times that.
List<String> overflowSweepEnumerationProblems(
  OverflowSurfaceFamily family,
  Iterable<OverflowSweepCell> cells,
) {
  final problems = <String>[];

  if (family.axisNames.isEmpty) {
    problems.add(
      '${family.name} declares no axes. Every axis except locale becomes the '
      'grouping, so a family needs at least one for its tests to have a group '
      'name.',
    );
  }
  if (family.axisNames.contains('locale')) {
    problems.add(
      '${family.name} declares "locale" as an axis. Locale is a field on the '
      'cell and the runner\'s inner loop; declaring it too would put it in the '
      'cell id twice.',
    );
  }

  final seen = <String>{};
  for (final cell in cells) {
    final id = overflowSweepCellId(family, cell);
    if (!seen.add(id)) {
      problems.add(
        'two cells share the id $id. One of them overwrites the other\'s '
        'baseline row and its freshness key, so it is counted but not measured.',
      );
    }
    final keys = cell.axes.keys.toList();
    if (!listEquals(keys, family.axisNames)) {
      problems.add(
        'cell $id carries axes [${keys.join(', ')}] where the family declares '
        '[${family.axisNames.join(', ')}]. The id is the axes in order, so a '
        'mismatch renames the coordinate.',
      );
    }
  }
  return problems;
}

/// The aggregated failure for one coordinate: the count, and every failing
/// locale.
///
/// Named locales rather than a count alone, because the count is what tells you
/// how bad it is and the names are what tell you where to look — #1328's band was
/// only visible because `en` cleared at 640px and `pl` needed 768px.
///
/// [threwCount] changes the verb. `overflowed at 640px in 1 locale(s)` would be a
/// lie about a cell whose tree never finished building, and the two are
/// remediated differently: an overflow is a layout to fix, a throw is a fixture
/// or a host to fix.
String overflowSweepFailureReason({
  required String familyName,
  required String coordinateLabel,
  required List<String> failures,
  required int threwCount,
}) {
  final verb = threwCount == 0 ? 'overflowed' : 'overflowed or threw';
  final threw = threwCount == 0 ? '' : ' ($threwCount threw)';
  return '$familyName $verb at $coordinateLabel in '
      '${failures.length} locale(s)$threw:\n${failures.join('\n')}';
}

/// What one cell measured.
class OverflowCellVerdict {
  const OverflowCellVerdict({
    required this.cellId,
    required this.incidents,
    required this.significant,
    this.error,
  });

  /// [overflowSweepCellId] for the cell that produced this.
  final String cellId;

  /// Every overflow collected, sub-tolerance ones included — they are in the
  /// dataset, so that loosening the filter cannot look like fixing a layout.
  final List<OverflowIncident> incidents;

  /// The subset above the tolerance: the gate's verdict.
  final List<OverflowIncident> significant;

  /// Non-null when the cell did not finish (invariant 3).
  final Object? error;

  bool get failed => error != null || significant.isNotEmpty;

  /// One line for the aggregated failure, without the locale prefix.
  String get summary => error != null ? 'threw $error' : significant.join(', ');
}

/// Measures exactly one cell, obeying all three invariants.
///
/// Public because it is the seam the framework's own oracle
/// (`sweep_test.dart`) tests against: a test cannot assert that another test
/// failed, so the per-cell verdict has to be observable from inside one. It is
/// also what a family reaches for if it ever needs a cell measured outside the
/// declared sweep.
///
/// Never throws for anything the cell did — invariant 3 — so the caller's loop
/// always reaches the next locale.
Future<OverflowCellVerdict> measureOverflowCell(
  WidgetTester tester, {
  required OverflowSurfaceFamily family,
  required OverflowSweepCell cell,
  double tolerancePx = kOverflowTolerancePx,
}) async {
  final baselineCell = overflowSweepBaselineCell(family, cell);
  final id = overflowBaselineCellId(baselineCell);
  try {
    final incidents = await runWithOverflowCollection(
      cell: baselineCell,
      (sink) async {
        await setLayoutSurface(tester, cell.surfaceSize);
        await tester.pumpWidget(
          // INVARIANT 1. Keyed on the cell's own identity, so re-pumping in the
          // same test replaces the subtree instead of updating it in place and
          // every cell gets its own render objects to report against.
          KeyedSubtree(key: ValueKey(id), child: cell.build()),
        );
        await settleIgnoringAnimations(tester);
        await family.onCellSettled(tester, cell);
        // INVARIANT 3, the half no `catch` can see. An error raised while
        // *building* a host is reported through `FlutterError.onError`, which
        // `collector.dart` forwards to the binding for anything that is not an
        // overflow — so `pumpWidget` returns normally, this cell's record is
        // written unflagged (reading measured-and-clean for a tree that never
        // built), and the binding fails the whole grouped test later with a bare
        // stack instead of the aggregated reason. Claiming it here makes it this
        // cell's failure like any other, and re-throwing is what tells the
        // collector to flag the row `threw`.
        final pending = tester.takeException();
        if (pending != null) throw pending;
        return sink;
      },
    );
    return OverflowCellVerdict(
      cellId: id,
      incidents: incidents,
      significant: incidents
          .where((i) => i.pixels > tolerancePx)
          .toList(growable: false),
    );
  } catch (error) {
    // INVARIANT 3. The collector has already emitted this cell's baseline record
    // flagged `threw`, so the dataset says "measured, and it did not finish"
    // rather than "measured, and it fits".
    return OverflowCellVerdict(
      cellId: id,
      incidents: const [],
      significant: const [],
      error: error,
    );
  }
}

/// Declares [family]'s sweep: one test per non-locale coordinate, plus the test
/// that pins how many cells there are.
///
/// Call at the top level of a suite's `main()`. Anything the family's hosts need
/// standing up first — fonts, GetIt singletons, platform channel stubs — belongs
/// in that suite's `setUpAll`, which wraps every test declared here.
///
/// [expectedCellCount] is the literal from the ticket, and required: see the
/// library header. A family that filters its own enumeration (the card sweep's
/// `--dart-define=LOCALE`) has to reckon with it — #1343's problem, and the
/// reason the count test's failure message says what to do either way.
void runOverflowSweep({
  required OverflowSurfaceFamily family,
  required int expectedCellCount,
  double tolerancePx = kOverflowTolerancePx,
}) {
  final cells = family.enumerateCells().toList(growable: false);
  final grouped = groupOverflowSweepCells(cells);

  group(family.name, () {
    test('enumerates $expectedCellCount cells', () {
      expect(
        cells.length,
        expectedCellCount,
        reason: 'the sweep enumerated ${cells.length} cells against the '
            '$expectedCellCount pinned here. Grouping hides this: '
            '${grouped.length} tests report the same green either way. If the '
            'axes changed deliberately, update the literal and re-capture the '
            'baseline (./tool/overflow_baseline.sh capture); if they did not, '
            'coverage was lost silently.',
      );
      expect(
        overflowSweepEnumerationProblems(family, cells),
        isEmpty,
        reason: 'the count above only means what it says while every cell has '
            'its own id and the declared axes',
      );
    });

    for (final entry in grouped.entries) {
      final cellsOfCoordinate = entry.value;
      // Named off the cell's own axes, not off `entry.key` — see
      // [overflowSweepNames].
      final names = overflowSweepNames(cellsOfCoordinate.first);

      group(names.group, () {
        testWidgets(names.test, (tester) async {
          final failures = <String>[];
          var threwCount = 0;

          for (final cell in cellsOfCoordinate) {
            final verdict = await measureOverflowCell(
              tester,
              family: family,
              cell: cell,
              tolerancePx: tolerancePx,
            );
            if (!verdict.failed) continue;
            if (verdict.error != null) threwCount++;
            failures.add('${localeTag(cell.locale)}: ${verdict.summary}');
          }

          expect(
            failures,
            isEmpty,
            reason: overflowSweepFailureReason(
              familyName: family.name,
              coordinateLabel: entry.key,
              failures: failures,
              threwCount: threwCount,
            ),
          );
        });
      });
    }
  });
}
