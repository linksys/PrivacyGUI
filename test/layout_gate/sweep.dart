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
/// ## The ratchet and the report live in the family, behind one hook (#1343)
///
/// This file still knows nothing about `known_overflows.json`,
/// `OverflowReportItem` or PNG dumps, and that is deliberate: three of the four
/// sweeps carry none of them. What it grew at #1343 is a single seam —
/// [OverflowSurfaceFamily.judgeCell] — asked once per measured cell, whose answer
/// is that cell's failure line or `null` for "this one is fine". The card family
/// puts its allowlist consult, its report row, its screenshots and its
/// remediation prose behind it; every other family inherits the default, which is
/// the zero-tolerance verdict they already had.
///
/// **One hook, not three.** The ratchet consult, the report row and the dump all
/// happen at the same moment, over the same inputs, in the one family that has
/// them — so three hooks would be one decision spelled three times, and two of
/// them would have no caller. A second, per-*coordinate* hook (advice deduplicated
/// across the locales that failed at one site) was considered and left out for the
/// same reason: today's failure prints the same paragraph per locale, so leaving
/// that alone keeps the port's promise that nothing measured or printed changes
/// shape without a reason.
///
/// **What the hook cannot do is swallow a throw.** A cell whose tree did not
/// finish building is never handed to the family (invariant 3 owns it), and a
/// judge that throws is that cell's failure like any other — see
/// [measureOverflowCoordinate].
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
  /// `const` so a stateless family stays a `const` declaration — every chrome
  /// family is one. Named unnamed rather than omitted because the two hooks below
  /// have defaults, which makes this a class with a body and therefore a class
  /// whose constructor a subclass has to be able to call.
  const OverflowSurfaceFamily();

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

  /// What this cell's failure line should say, or `null` for "this one is fine".
  ///
  /// The default is the verdict the runner has always applied: any overflow past
  /// the tolerance fails, spelled by [OverflowCellVerdict.summary]. A family
  /// overrides it to own the decision — #1343's card family consults
  /// `known_overflows.json`, records an [OverflowReportItem], writes the PNG pair
  /// and returns its remediation paragraph — and the runner keeps knowing nothing
  /// about any of that.
  ///
  /// Called for **every measured cell, clean ones included**, because the
  /// interesting consumers need the clean ones too: the ratchet's liveness ledger
  /// is how an expired allowlist entry is found (#1321), and a family's own
  /// measured-cell counter is what its coverage gaps are computed from. A hook
  /// that only saw failures would have made both of those the runner's job.
  ///
  /// Never called for a cell that threw: there is no measurement to judge, and
  /// invariant 3 has already turned it into that cell's failure. Anything this
  /// raises becomes the cell's failure too — see [measureOverflowCoordinate].
  Future<String?> judgeCell(
    WidgetTester tester,
    OverflowSweepCell cell,
    OverflowCellVerdict verdict,
  ) async =>
      verdict.significant.isEmpty ? null : verdict.summary;

  /// Why this run enumerated fewer cells than the sweep pins, if it did.
  ///
  /// The escape hatch for `expectedCellCount`, and the answer to the question the
  /// pin's own doc left open. A family that lets the operator narrow its
  /// enumeration — the card sweep's `--dart-define=LOCALE`, which exists so a
  /// single-locale dump run takes seconds instead of an hour — cannot also satisfy
  /// a pin written for the whole sweep. Returning a non-empty list makes the count
  /// test *skip* with those reasons, rather than fail on every dump run (§5
  /// contract 3) or pass on a subset (which is the #1321 failure again).
  ///
  /// Empty by default: a family that cannot be narrowed has no gaps, and the pin
  /// is checked.
  List<String> enumerationGaps() => const [];
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
    this.tolerancePx = kOverflowTolerancePx,
    this.error,
  });

  /// [overflowSweepCellId] for the cell that produced this.
  final String cellId;

  /// Every overflow collected, sub-tolerance ones included — they are in the
  /// dataset, so that loosening the filter cannot look like fixing a layout.
  final List<OverflowIncident> incidents;

  /// The subset above the tolerance: the gate's verdict.
  final List<OverflowIncident> significant;

  /// The bar [significant] was filtered at, carried so a family that measures
  /// anything of its own judges it by the same one.
  ///
  /// [runOverflowSweep] takes `tolerancePx` as a parameter, so "the tolerance" is
  /// already not necessarily [kOverflowTolerancePx]. #1343's report row re-measures
  /// the card at its recommended size, and reading the constant there would have
  /// held that second measurement to a different bar than the cell beside it in the
  /// same row.
  final double tolerancePx;

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
      tolerancePx: tolerancePx,
    );
  } catch (error) {
    // INVARIANT 3. The collector has already emitted this cell's baseline record
    // flagged `threw`, so the dataset says "measured, and it did not finish"
    // rather than "measured, and it fits".
    return OverflowCellVerdict(
      cellId: id,
      incidents: const [],
      significant: const [],
      tolerancePx: tolerancePx,
      error: error,
    );
  }
}

/// What one coordinate's locale loop measured: the failing lines, and how many of
/// them were throws rather than overflows.
class OverflowCoordinateVerdict {
  const OverflowCoordinateVerdict({
    required this.failures,
    required this.threwCount,
  });

  /// One line per failing locale, each already prefixed with its tag.
  final List<String> failures;

  /// How many of [failures] are a cell that did not finish, or a judge that
  /// raised. Changes the verb of the aggregated failure, because an overflow and a
  /// broken host are remediated differently.
  final int threwCount;

  bool get failed => failures.isNotEmpty;
}

/// Measures one coordinate in every locale, asking [family] to judge each cell.
///
/// Public for the same reason [measureOverflowCell] is: a test cannot assert that
/// another test failed, and this is now where the two behaviours that matter live
/// — that a family's verdict can clear a cell the tolerance filter failed (the
/// ratchet, in the family that has one), and that one locale cannot take the other
/// 25 down whether it is the host or the judge that breaks.
Future<OverflowCoordinateVerdict> measureOverflowCoordinate(
  WidgetTester tester, {
  required OverflowSurfaceFamily family,
  required Iterable<OverflowSweepCell> cells,
  double tolerancePx = kOverflowTolerancePx,
}) async {
  final failures = <String>[];
  var threwCount = 0;

  for (final cell in cells) {
    final tag = localeTag(cell.locale);
    final verdict = await measureOverflowCell(
      tester,
      family: family,
      cell: cell,
      tolerancePx: tolerancePx,
    );

    if (verdict.error != null) {
      // Not handed to the family: a cell whose tree never finished has no
      // measurement to judge, and its dataset row is already flagged `threw`.
      // Skipping the judge is also what keeps a family's own bookkeeping honest —
      // this cell is not counted as measured, so it shows up as the coverage gap
      // it is instead of a silently judged blank.
      threwCount++;
      failures.add('$tag: ${verdict.summary}');
      continue;
    }

    try {
      final detail = await family.judgeCell(tester, cell, verdict);
      if (detail != null) failures.add('$tag: $detail');
    } catch (error) {
      // INVARIANT 3, one step later. The judge is where a family does its I/O —
      // #1343 writes two PNGs and a report row from here — so it is the step most
      // able to fail for a reason that has nothing to do with the next locale.
      threwCount++;
      failures.add('$tag: threw while judging: $error');
    }
  }

  return OverflowCoordinateVerdict(failures: failures, threwCount: threwCount);
}

/// What the count test says instead of pinning, when the run narrowed the
/// enumeration itself.
///
/// The pin is a claim about the *whole* sweep, so a deliberately filtered run
/// cannot make it: `-L de` enumerates 63 of the card sweep's 1,638 cells and would
/// fail the pin on every dump run the tooling exists for (§5 contract 3). Reported
/// as a skip rather than a silent pass because "the count was not checked" is a
/// fact about the run, and because the dead-entry direction is already skipped for
/// exactly this reason (`OverflowRatchet.coverageSkipNote`) — one vocabulary, one
/// place to look.
String overflowSweepCountSkipNote({
  required String familyName,
  required int enumerated,
  required int expectedCellCount,
  required List<String> gaps,
}) {
  return [
    '$familyName enumerated $enumerated cells, not the $expectedCellCount this '
        'sweep pins, because the run narrowed the enumeration itself:',
    for (final gap in gaps) '  * $gap',
    'The pin is a claim about the whole sweep, so it is not checked here. Run the '
        'sweep unfiltered before reading a green count as coverage.',
  ].join('\n');
}

/// What the count test does with the run it is given.
enum OverflowSweepCountAction {
  /// No narrowing was declared, so the literal is checked.
  pin,

  /// The run narrowed its own enumeration; report it instead of pinning a subset.
  skip,

  /// The narrowing left nothing to measure — see [overflowSweepEmptyRunFailure].
  failEmpty,
}

/// Whether this run may pin its cell count, must skip, or is not a run at all.
///
/// Pulled out of the count test as a pure function because the test cannot be
/// observed: [runOverflowSweep] declares it at top level, and no test can assert
/// that another test skipped. The decision is the part worth proving, so it is the
/// part that is reachable.
///
/// [failEmpty] is the branch a narrowed run made possible. A gap explains measuring
/// *less* than the pin; it never explains measuring nothing. `LOCALE=zz` matches no
/// shipped locale, every card family multiplies out to zero cells, and all three
/// pins would then skip with a perfectly accurate note — leaving a green suite that
/// rendered nothing at all. A filter that matched nothing is an operator typo, and
/// the one thing a gate must never do is pass silently over zero measurements.
OverflowSweepCountAction overflowSweepCountAction({
  required int enumerated,
  required int expectedCellCount,
  required List<String> gaps,
}) {
  if (enumerated == 0 && expectedCellCount > 0) {
    return OverflowSweepCountAction.failEmpty;
  }
  return gaps.isEmpty
      ? OverflowSweepCountAction.pin
      : OverflowSweepCountAction.skip;
}

/// The failure for a run whose narrowing matched nothing.
///
/// Quotes the gaps because they are the evidence: each one names the define that
/// did it, which is where the typo is.
String overflowSweepEmptyRunFailure({
  required String familyName,
  required int expectedCellCount,
  required List<String> gaps,
}) {
  return [
    '$familyName enumerated no cells at all, against the $expectedCellCount this '
        'sweep pins.',
    if (gaps.isNotEmpty) 'The run narrowed itself:',
    for (final gap in gaps) '  * $gap',
    'A narrowing explains measuring less than the pin, never measuring nothing: a '
        'filter that matched nothing would leave every pin skipped and this sweep '
        'green over zero measurements. Check the value you passed (a locale tag '
        'the app does not ship, or a MIN_SCREEN above every width).',
  ].join('\n');
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
/// `--dart-define=LOCALE`) answers it through
/// [OverflowSurfaceFamily.enumerationGaps]: it says how it narrowed the run, and
/// the count test reports the narrowing instead of pinning a subset — unless the
/// narrowing left nothing to enumerate, which is a failure and not a gap. See
/// [overflowSweepCountAction].
void runOverflowSweep({
  required OverflowSurfaceFamily family,
  required int expectedCellCount,
  double tolerancePx = kOverflowTolerancePx,
}) {
  final cells = family.enumerateCells().toList(growable: false);
  final grouped = groupOverflowSweepCells(cells);

  group(family.name, () {
    test('enumerates $expectedCellCount cells', () {
      final gaps = family.enumerationGaps();
      switch (overflowSweepCountAction(
        enumerated: cells.length,
        expectedCellCount: expectedCellCount,
        gaps: gaps,
      )) {
        case OverflowSweepCountAction.pin:
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
        case OverflowSweepCountAction.skip:
          markTestSkipped(
            overflowSweepCountSkipNote(
              familyName: family.name,
              enumerated: cells.length,
              expectedCellCount: expectedCellCount,
              gaps: gaps,
            ),
          );
        case OverflowSweepCountAction.failEmpty:
          fail(overflowSweepEmptyRunFailure(
            familyName: family.name,
            expectedCellCount: expectedCellCount,
            gaps: gaps,
          ));
      }
      // Checked either way. A narrowed run still enumerates *some* cells, and a
      // malformed id is malformed in 63 cells as surely as in 1,638 — this is the
      // half of the count test a dump run can still prove.
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
          final verdict = await measureOverflowCoordinate(
            tester,
            family: family,
            cells: cellsOfCoordinate,
            tolerancePx: tolerancePx,
          );

          expect(
            verdict.failures,
            isEmpty,
            reason: overflowSweepFailureReason(
              familyName: family.name,
              coordinateLabel: entry.key,
              failures: verdict.failures,
              threwCount: verdict.threwCount,
            ),
          );
        });
      });
    }
  });
}
