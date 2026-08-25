import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden_test/golden_framework/overflow_record.dart';
import '../layout_gate/incident.dart';

/// Guards the record the golden runner writes for one overflow, and the swap
/// that made it stop parsing (#1339).
///
/// Until #1339 this file was `overflow_diagnostics_test.dart` and pinned a second
/// parser of Flutter's overflow message — **27 tests** (22 `test`, 5
/// `testWidgets`; a `test(`-only grep says 22 and is wrong), of which 15 the
/// shared oracle (`test/util/overflow_probe_test.dart`) already covered case for
/// case. Of the other 12: four moved to that oracle with the dump transforms they
/// exercise, three were ported to it because nothing there covered them (a
/// malformed `1.2.3` amount, a non-ASCII run directory, and a pub-cache path that
/// is itself percent-encoded — the ordering case), one was **superseded** by the
/// behaviour change (`keeps the first side` is now false on purpose, and its
/// replacement asserts the worst side), and the last four are the four below.
/// What is left here is the part that is genuinely this file's: **which keys the
/// record carries, in which order, and which are omitted** — plus the evidence
/// for the swap itself.
///
/// Lives under `test/test_scripts/` rather than beside the code it tests because
/// everything under `test/golden_test/` is excluded from `run_tests.sh`
/// (`--exclude-tags="golden||loc||ui"`), and a guard on an SDK implementation
/// detail is worthless if CI never runs it. It needs no golden baseline, no fonts
/// and no `AlchemistConfig` — only `pumpWidget` and a checked-in JSON file.
void main() {
  group('buildOverflowRecord', () {
    /// Triggers a real overflow and returns the record built from it.
    Future<Map<String, String>> recordFor(WidgetTester tester) async {
      final records = <Map<String, String>>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          records.add(buildOverflowRecord(
            goldenName: 'demo-data-phone480-fr',
            details: details,
            runDirectory: Directory.current.path,
          ));
          return;
        }
        original?.call(details);
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: const [
              SizedBox(
                width: 100,
                child: Row(children: [SizedBox(width: 150, height: 10)]),
              ),
            ],
          ),
        ),
      );
      FlutterError.onError = original;

      return records.single;
    }

    testWidgets('keeps the full diagnostics dump for the report', (
      tester,
    ) async {
      // The dump is the only lead on an overflow whose location did not resolve
      // — the ~120 admin cases where the badge was set but nothing was visible
      // in the image. Computing it and throwing it away left them undiagnosable
      // (#1197).
      final record = await recordFor(tester);

      expect(record['log'], contains('A RenderFlex overflowed'));
      expect(record['log'], contains('The relevant error-causing widget was'));
      expect(record['log'], contains('constraints:'),
          reason: 'the deep dump carries the RenderFlex constraints, which is '
              'what explains an overflow the one-line message does not');
    });

    testWidgets('strips absolute run paths out of the dump', (tester) async {
      // The dump embeds the run directory in every creation location. Left in,
      // a report generated on CI would carry the runner's workspace path, and
      // two machines would produce different bytes for the same overflow.
      final record = await recordFor(tester);

      expect(record['log'], isNot(contains(Directory.current.path)));
      expect(record['log'],
          contains('test/test_scripts/overflow_record_test.dart'));
    });

    testWidgets('records the amount and location alongside the dump', (
      tester,
    ) async {
      final record = await recordFor(tester);

      expect(record['golden'], 'demo-data-phone480-fr');
      expect(record['pixels'], '50');
      expect(record['side'], 'right');
      expect(record['widget'], 'Row');
      expect(record['file'], 'test/test_scripts/overflow_record_test.dart');
      expect(record['line'], isNotNull);
    });

    testWidgets('leaves no per-run object id in the dump', (tester) async {
      // Object ids are reallocated every run, so leaving them in made the same
      // overflow record different bytes each time and defeated the report's log
      // deduplication entirely: 24 records for one culprit stayed 24 distinct
      // logs (#1197).
      final record = await recordFor(tester);

      expect(record['log'], contains('RenderFlex relayoutBoundary'));
      expect(record['log'], isNot(matches(RegExp(r'#[0-9a-f]{5}\b'))));
    });

    testWidgets('writes its keys in the order the report is diffed in', (
      tester,
    ) async {
      // `overflow_warnings.json` is `jsonEncode` over this map, and successive
      // runs of it get diffed. Reordering the keys would rewrite every byte of a
      // file whose content did not change — which is exactly the signal #1339
      // used to verify itself, so it has to be pinned rather than assumed.
      final record = await recordFor(tester);

      expect(record.keys, [
        'golden',
        'message',
        'pixels',
        'side',
        'log',
        'widget',
        'file',
        'line',
      ]);
    });

    test(
        'omits the amount rather than reporting infinity for one it cannot read',
        () {
      // The advisory opt-out, from the outside. The shared parser's default for
      // an unreadable message is deliberately loud — `pixels` comes back as
      // infinity so the gate fails instead of reading clean — and this report
      // judges nothing, so it must omit the field the way the deleted parser's
      // empty map did. A `"pixels": "Infinity"` here would render as
      // `Infinitypx` on a badge and sort to the top of every report.
      final record = buildOverflowRecord(
        goldenName: 'admin-data-screen1080-de',
        details: FlutterErrorDetails(
          exception: FlutterError(
            'A RenderFlex overflowed by a whole bunch of pixels on the right.',
          ),
          library: 'rendering library',
        ),
        runDirectory: Directory.current.path,
      );

      expect(record.containsKey('pixels'), isFalse);
      expect(record.containsKey('side'), isFalse);
      expect(record['message'], contains('overflowed'));
      expect(record['log'], isNotNull,
          reason: 'an unreadable amount is the case where the raw dump is the '
              'only lead there is — dropping it too would leave nothing');
    });

    testWidgets('reports the worst side of a two-sided overflow, not the first',
        (tester) async {
      // The one behavioural difference #1339 makes to the golden report, pinned
      // against a real SDK string rather than a hand-written one. The corpus in
      // `test/fixtures/golden_overflow_warnings.json` cannot cover it — all 16 of
      // its records name exactly one side — so this is where it is checked.
      //
      // `ConstraintsTransformBox` is used because it is the shifted box that
      // carries `DebugOverflowIndicatorMixin` and can overflow on two axes at
      // once; `Stack` and `OverflowBox` report nothing at all (`RenderStack` and
      // `RenderConstrainedOverflowBox` have no mixin).
      final records = <Map<String, String>>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          records.add(buildOverflowRecord(
            goldenName: 'two-sided',
            details: details,
            runDirectory: Directory.current.path,
          ));
          return;
        }
        original?.call(details);
      };

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 100,
            height: 50,
            child: ConstraintsTransformBox(
              constraintsTransform: _tightly141x60,
              alignment: Alignment.topLeft,
              clipBehavior: Clip.none,
              child: SizedBox(width: 141, height: 60),
            ),
          ),
        ),
      );
      FlutterError.onError = original;

      final record = records.single;
      expect(record['message'], contains('pixels on the bottom and'),
          reason: 'if the SDK stops emitting two clauses in one message, this '
              'test is measuring nothing and the difference is unpinned');
      expect(record['pixels'], '41');
      expect(record['side'], 'right',
          reason: 'the deleted parser took the first clause and would have '
              'recorded 10.0px bottom — the sub-tolerance side of a 41px '
              'overflow');
    });
  });

  group('against a stored real report', () {
    // #1339's verification, offline. `test/fixtures/golden_overflow_warnings.json`
    // is a real `goldens/overflow_warnings.json` captured verbatim from a golden
    // run at screen1080 (the two committed coordinates produce no overflow at
    // all), written by the parser this ticket deleted. Byte-identity is
    // explicitly *not* the criterion: the criterion is that every difference is
    // attributed, record by record, to first-side → worst-side.
    //
    // What is checkable here and what is not, stated rather than blurred: the
    // amount and the side re-derive from the stored `message`, so those are
    // compared against the artifact directly. The location does **not** — the
    // stored `logs` are post-normalisation, so their creation locations no longer
    // carry the `file://` prefix the parser matches on, and re-absolutising them
    // would be building input rather than using the artifact. The location path
    // is pinned by the real pumps in the group above and by
    // `overflow_probe_test.dart`'s own real-overflow case instead.
    late Map<String, dynamic> report;

    setUpAll(() {
      report = jsonDecode(
        File('test/fixtures/golden_overflow_warnings.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    /// One `"<n> pixels on the <side>"` clause, spelled independently of the
    /// parser's own pattern on purpose: an oracle that reused it could not
    /// notice the parser misreading a clause, only that it read the same clause
    /// twice.
    final clause =
        RegExp(r'([0-9][0-9.]*(?:e-?[0-9]+)?) pixels on the ([a-z]+)');

    test('every record\'s amount and side re-derive, or are attributable', () {
      final records =
          List<Map<String, dynamic>>.from(report['records'] as List<dynamic>);
      expect(records, isNotEmpty, reason: 'a corpus of nothing proves nothing');

      var multiClause = 0;
      for (final record in records) {
        final message = record['message'] as String;
        final clauses = clause.allMatches(message).toList();
        expect(clauses, isNotEmpty,
            reason: 'a stored record whose message carries no clause at all '
                'would mean the fixture, not the parser, is wrong: $message');

        final incident = OverflowIncident.parse(message);
        if (incident.pixelsText == record['pixels'] &&
            incident.side == record['side']) {
          continue;
        }

        // The attribution rule, executable. A difference is sanctioned only when
        // the message named several sides, the stored pair is the *first* clause
        // and ours is the largest. Anything else fails here as a defect, which is
        // the whole point of the criterion.
        multiClause++;
        expect(clauses.length, greaterThan(1),
            reason: 'unattributable difference on "$message": stored '
                '${record['pixels']}/${record['side']}, parsed '
                '${incident.pixelsText}/${incident.side}');
        expect(record['pixels'], clauses.first.group(1));
        expect(record['side'], clauses.first.group(2));

        final worst = clauses.reduce((a, b) =>
            double.parse(b.group(1)!) > double.parse(a.group(1)!) ? b : a);
        expect(incident.pixelsText, worst.group(1));
        expect(incident.side, worst.group(2));
      }

      // Pinned as a count, not left implicit: this corpus contains no two-sided
      // overflow, so the branch above never runs and the *only* honest reading of
      // a green run here is "the swap changed nothing on 16 real records". If a
      // future capture does carry one, this number moves and whoever moves it has
      // to look at the attribution.
      expect(multiClause, 0,
          reason: 'the fixture\'s provenance records that all its messages are '
              'single-sided; the first-side → worst-side difference is pinned '
              'against a real SDK string in the group above');
    });

    test('the stored records\' key order is the one this file still writes',
        () {
      // The artifact's own key order, read out of the file rather than restated:
      // `jsonDecode` preserves insertion order, and `_writeOverflowReport`
      // produces it by removing `log` from the record and appending `logIndex`.
      final records =
          List<Map<String, dynamic>>.from(report['records'] as List<dynamic>);

      for (final record in records) {
        expect(record.keys, [
          'golden',
          'message',
          'pixels',
          'side',
          'widget',
          'file',
          'line',
          'logIndex',
        ]);
      }
    });

    test('the stored logs are a fixed point of the transforms', () {
      // Weaker than a re-derivation and worth being clear about: the logs were
      // already normalised when they were written, so this cannot show the new
      // transforms *produce* them. What it does show is that the new pair leaves
      // 6 real dumps — ~14KB of the SDK's own text, constraints, creator chains
      // and all — untouched, i.e. it introduces no mangling the old pair did not
      // have. A transform that, say, matched `Row:lib/x.dart:77:12` a second time
      // would fail here.
      final logs = List<String>.from(report['logs'] as List<dynamic>);
      expect(logs, hasLength(greaterThan(1)));

      for (final log in logs) {
        expect(
          stripOverflowObjectIds(
            normalizeOverflowDumpPaths(log,
                runDirectory: Directory.current.path),
          ),
          log,
        );
      }
    });
  });
}

/// A tight 141×60 constraint, whatever the parent offers.
///
/// A top-level function because `ConstraintsTransformBox`'s constructor is const
/// and a closure is not; naming it is also what lets the widget under test stay
/// `const`, which keeps the pump one tree with no rebuild.
BoxConstraints _tightly141x60(BoxConstraints _) =>
    const BoxConstraints.tightFor(width: 141, height: 60);
