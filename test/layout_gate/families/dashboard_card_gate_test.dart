@Tags(['layout-gate'])
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../util/dashboard/dashboard_card_probe.dart';
import '../incident.dart';
import '../ratchet.dart';
import '../sweep.dart';
import 'dashboard_card_family.dart';
import 'dashboard_card_gate.dart';

/// The card gate's oracle (#1343).
///
/// Tagged `layout-gate` and **not** `overflow`: like `sweep_test.dart` and
/// `ratchet_test.dart` this is a framework self-test, not one of the four sweeps
/// the narrower selector runs.
///
/// What it exists to prove is the half of #1343 a baseline diff cannot see.
/// `./tool/overflow_baseline.sh check card` proves the port measures the same
/// 1,917 coordinates; it says nothing about what the gate *does* with a
/// measurement, because the fixture is empty and the sweep is green — every
/// interesting branch of [CardSweepGate.judge] is unreachable on real data today.
/// Before #1343 those branches were file-private globals inside a 1,898-cell
/// suite and could not be reached from a test at all; the cases below are what
/// that refactor bought.
///
/// Synthetic incidents rather than pumped ones, deliberately: an incident is
/// [OverflowIncident]'s public const constructor away, and standing up a card that
/// genuinely overflows would mean shipping a broken widget to test the reporter.
void main() {
  // A real coordinate, so nothing here depends on a hand-made geometry: the same
  // spec, width case and row count the width family enumerates.
  final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == 'device_info');
  final widthCase = widthCasesFor(spec).first;

  CardSweepCell cellFor(String tag) => CardSweepCell(
        axes: {
          'card': spec.id,
          'width': widthCase.label,
          'px': widthCase.widthKey,
          'tab': 0,
        },
        locale: Locale(tag),
        cardId: spec.id,
        widthCase: widthCase,
        rows: spec.getConstraints(DisplayMode.normal).minHeightRows,
        tab: 0,
        tabCount: 1,
      );

  OverflowCellVerdict verdictWith(List<OverflowIncident> significant) =>
      OverflowCellVerdict(
        cellId: 'card.width|card=device_info|width=min|px=191|tab=0|locale=de',
        incidents: significant,
        significant: significant,
      );

  OverflowIncident incidentAt(String file, int line, double pixels) =>
      OverflowIncident(
        pixels: pixels,
        side: 'right',
        message: 'A RenderFlex overflowed by $pixels pixels on the right.',
        file: file,
        line: line,
        widget: 'Row',
      );

  /// One deferred site, at 41px, in German only.
  ///
  /// Built per test rather than shared: `consultCell` records what it was handed,
  /// because that ledger is what the closing dead-entry verdict is computed from.
  /// A ratchet reused across tests would carry the previous test's observations
  /// into this one's verdict.
  OverflowRatchet leasedRatchet() => OverflowRatchet.fromJson({
        'tracking': {'lib/x.dart:9': 'legend fix #1145'},
        'allowlist': {
          'lib/x.dart:9': {
            'locales': ['de'],
            'maxOverflowPx': 41,
          },
        },
      });

  group('the verdict for one cell', () {
    testWidgets('a clean cell has none, and is still counted', (tester) async {
      // The reason the hook fires on clean cells at all: this count is what
      // decides whether the run covered enough for the dead-entry verdict.
      final gate = CardSweepGate();

      final detail = await gate.judge(
        tester,
        cellFor('de'),
        verdictWith(const []),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'unreachable',
      );

      expect(detail, isNull);
      expect(gate.measuredCells, 1);
    });

    testWidgets('an unexempted overflow fails, with the paste-ready entry',
        (tester) async {
      // The gate's default state: an empty fixture blocks everything, and the
      // failure has to hand over the exact `file:line` key and ceiling — the
      // example is derived from the measurement so it cannot drift from what the
      // parser accepts.
      final gate = CardSweepGate();

      final detail = await gate.judge(
        tester,
        cellFor('de'),
        verdictWith([incidentAt('lib/x.dart', 9, 41.0)]),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'device_info overflows: $d.',
      );

      expect(detail, isNotNull);
      expect(detail, startsWith('device_info overflows: +41.0px right'));
      expect(detail, contains(kKnownOverflowsFixturePath));
      expect(detail,
          contains('"lib/x.dart:9": {"locales": ["de"], "maxOverflowPx": 41}'));
    });

    testWidgets('a leased site is tolerated, and says so out loud',
        (tester) async {
      // The ratchet's whole purpose, and the branch that made a family verdict
      // hook necessary: the overflow is real and the gate stays green.
      //
      // The print is asserted, not just the null: a null on its own is
      // indistinguishable from a clean cell, and this line is the only place a
      // tolerated overflow is ever visible — with the allowance beside it, because
      // "+25.9px, allowed 26.0px" and "+2.5px, allowed 26.0px" read identically
      // without it and the first is one shaping difference from failing CI.
      final gate = CardSweepGate()..ratchet = leasedRatchet();
      final printed = <String>[];

      final detail = await runZoned(
        () => gate.judge(
          tester,
          cellFor('de'),
          verdictWith([incidentAt('lib/x.dart', 9, 41.0)]),
          subject: 'device_info @min 191px tab0',
          failure: (d) => 'unreachable',
        ),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => printed.add(line),
        ),
      );

      expect(detail, isNull);
      expect(printed, hasLength(1));
      expect(printed.single, startsWith('KNOWN OVERFLOW (allowlisted) '));
      expect(printed.single, contains('device_info @min 191px tab0 de: '));
      expect(printed.single, contains('+41.0px right at lib/x.dart:9'));
      expect(printed.single, contains('(allowed up to 41.0px'));
      expect(printed.single, endsWith('legend fix #1145'),
          reason:
              'the tracking note is per site, and is why this is tolerated');
    });

    testWidgets('the lease is per locale, so another locale still fails',
        (tester) async {
      final gate = CardSweepGate()..ratchet = leasedRatchet();

      final detail = await gate.judge(
        tester,
        cellFor('fi'),
        verdictWith([incidentAt('lib/x.dart', 9, 41.0)]),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'device_info overflows: $d.',
      );

      expect(detail, contains('+41.0px right'));
      expect(detail, contains('"locales": ["fi"]'));
    });

    testWidgets('a cell may be part leased and part blocked', (tester) async {
      // Only possible since the key became a source location: the failure quotes
      // the new site — that is the work — and says the coordinate carries more, so
      // a one-incident message is not read as the whole story.
      final gate = CardSweepGate()..ratchet = leasedRatchet();

      final detail = await gate.judge(
        tester,
        cellFor('de'),
        verdictWith([
          incidentAt('lib/x.dart', 9, 41.0),
          incidentAt('lib/y.dart', 4, 12.0),
        ]),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'device_info overflows: $d.',
      );

      expect(detail, contains('+12.0px right'));
      expect(detail, contains('(plus 1 already allowlisted here)'));
      expect(detail, contains('"lib/y.dart:4"'));
      expect(detail, isNot(contains('"lib/x.dart:9": {')),
          reason: 'the leased site needs no new entry pasted for it');
    });

    testWidgets('overflowing past the ceiling is its own advice',
        (tester) async {
      // "Add the tag" is wrong advice for an entry that already names it: whoever
      // holds the failure would open the fixture, find the tag, and conclude the
      // gate is broken. What changed is the size.
      final gate = CardSweepGate()..ratchet = leasedRatchet();

      final detail = await gate.judge(
        tester,
        cellFor('de'),
        verdictWith([incidentAt('lib/x.dart', 9, 80.0)]),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'device_info overflows: $d.',
      );

      expect(detail, contains('Already allowlisted for "de"'));
      // The ceiling is quoted with its shaping tolerance, so 41.0px-allowed
      // against a +42.5px measurement cannot read as a breach of what the entry
      // literally says.
      expect(
        detail,
        contains('allowed up to 41.0px (+2.0px shaping tolerance), measured '
            '+80.0px'),
      );
    });
  });

  group('coverage arithmetic', () {
    test('a full run has no gaps, so the dead-entry check is live', () {
      // The pair the whole ratchet ledger rests on. `declare` is what the families
      // report at enumeration; `judge` is what counts measurements. Equal means
      // nothing narrowed the run, which is the only state in which an unused
      // allowlist entry may be called dead.
      final gate = CardSweepGate()
        ..declare('card.width', 1638)
        ..declare('card.normal_band', 208)
        ..declare('card.profile', 52);

      expect(gate.declaredCells, 1898);
      expect(gate.coverageGaps(), [
        '0 of 1898 declared cells were measured (a --name / -c filter, or a cell '
            'that threw before measuring)',
      ]);
    });

    test('declaring twice does not double the count', () {
      // A family that enumerated twice would otherwise report 3,276 declared cells
      // against 1,638 measured — a coverage gap invented by bookkeeping, which
      // would silently disable the dead-entry verdict on a complete run.
      final gate = CardSweepGate()
        ..declare('card.width', 1638)
        ..declare('card.width', 1638);

      expect(gate.declaredCells, 1638);
    });

    testWidgets('a --name filter is a gap, and it is only visible at the end',
        (tester) async {
      // The narrowing the suite cannot see any other way: `--name` is applied by
      // the test runner, so the declaration is complete and the measurements are
      // not. It is deliberately absent from `enumerationGaps` — at count-test time
      // nothing has been measured yet, and treating that as a filter would skip
      // the pin on every run.
      final gate = CardSweepGate()..declare('card.width', 1638);
      await gate.judge(
        tester,
        cellFor('de'),
        verdictWith(const []),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'unreachable',
      );

      expect(gate.enumerationGaps(), isEmpty,
          reason: 'this run set no LOCALE and no MIN_SCREEN');
      expect(gate.coverageGaps().single, contains('1 of 1638'));
    });
  });

  group('the closing direction', () {
    testWidgets('a complete run reports the entry nothing needed',
        (tester) async {
      // The ratchet's second question, and the reason `judge` counts clean cells:
      // an exemption that no cell overflowed against is debt that was paid and
      // never written off, and the next real overflow at that line would be
      // waved through as this ticket's known debt.
      final gate = CardSweepGate()
        ..ratchet = leasedRatchet()
        ..declare('card.width', 1);
      await gate.judge(
        tester,
        cellFor('de'),
        verdictWith(const []),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'unreachable',
      );

      expect(gate.coverageGaps(), isEmpty, reason: '1 declared, 1 measured');
      final dead = await gate.close();
      expect(dead, isNotNull);
      expect(dead, contains('lib/x.dart:9'));
      expect(dead, contains('no gated cell overflowed there in this run'));
    });

    testWidgets(
        'a narrowed run takes no verdict, and says which one it skipped',
        (tester) async {
      // The guard that matters more than the check: the same measurements as
      // above, one declared cell short of complete. A partial run cannot tell "the
      // defect is fixed" from "that cell was never pumped", and calling a live
      // entry dead would send someone to delete a real exemption.
      final gate = CardSweepGate()
        ..ratchet = leasedRatchet()
        ..declare('card.width', 2);
      await gate.judge(
        tester,
        cellFor('de'),
        verdictWith(const []),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'unreachable',
      );

      final printed = <String>[];
      final dead = await runZoned(
        gate.close,
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => printed.add(line),
        ),
      );

      expect(dead, isNull);
      expect(printed, hasLength(1),
          reason: 'a skipped check is announced exactly once, at the end');
      expect(printed.single, contains('1 of 2 declared cells were measured'));
    });
  });
}
