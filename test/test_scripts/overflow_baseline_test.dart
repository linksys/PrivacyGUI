import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../test_scripts/overflow_baseline.dart';
import '../layout_gate/incident.dart';
import '../util/overflow_baseline.dart' as emitter;

/// Guards the extract-and-diff half of the sweep baselines (#1337).
///
/// Every port in epic #1335 is signed off by one claim — *the failure set is
/// identical, cell by cell* — and this file is what that claim rests on. So the
/// tests here are mostly about the ways a comparison can lie: a cell that stopped
/// being measured reading as a pass, a run that half-compiled reading as a small
/// clean dataset, two coordinates colliding on one id so one of them vanishes,
/// the same run rendering differently twice. #1321 is the standing reminder of the
/// cost — a stale fixture turned a red gate green and no diff was watching.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('overflow_baseline_test');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  /// One `#LAYOUT-CELL#` line as the sweeps print it.
  String marked(
    String cell,
    List<Map<String, Object?>> incidents, {
    bool threw = false,
  }) =>
      '$overflowBaselineMarker '
      '${jsonEncode({'cell': cell, 'threw': threw, 'incidents': incidents})}';

  /// One incident as the emitter puts it in a record.
  ///
  /// Hand-mirrored rather than routed through [emitter.overflowBaselineRecordLine]
  /// because the tests below hand this script pre-built cell *ids*, not
  /// [emitter.OverflowCell]s, and reconstructing the axes of ~25 of them would
  /// obscure what each test is about. A hand mirror only ever agrees with
  /// whatever it was written against, though — this one carried `line` as a
  /// `String?` and so stayed green straight through #1351's swap of
  /// `parseOverflowSource` (`Map<String, String>`) for [OverflowIncident] (`line`
  /// is an `int`), a format change in the one dataset this file is named after.
  /// So `line` is typed as the emitter types it, and the group 'the record shape'
  /// pins the keys, the types and the row they render to through the real
  /// emitter.
  Map<String, Object?> incident({
    required String px,
    required String side,
    required bool significant,
    String? widget,
    String? file,
    int? line,
  }) =>
      {
        'px': px,
        'side': side,
        'significant': significant,
        if (widget != null) 'widget': widget,
        if (file != null) 'file': file,
        if (line != null) 'line': line,
      };

  /// Renders a `--reporter json` stream carrying [messages] as `print` events,
  /// which is the only channel the sweeps use to hand records over.
  String reporter(
    List<String> messages, {
    bool success = true,
    bool finished = true,
    List<Map<String, Object?>> extraEvents = const [],
  }) {
    final events = <Map<String, Object?>>[
      {'protocolVersion': '0.1.1', 'pid': 1, 'type': 'start', 'time': 0},
      {
        'suite': {'id': 0, 'platform': 'vm', 'path': 'test/sweep_test.dart'},
        'type': 'suite',
        'time': 0,
      },
      {
        'test': {'id': 1, 'name': 'a sweep test', 'suiteID': 0, 'groupIDs': []},
        'type': 'testStart',
        'time': 1,
      },
      for (final message in messages)
        {
          'testID': 1,
          'messageType': 'print',
          'message': message,
          'type': 'print',
          'time': 2,
        },
      ...extraEvents,
      {'testID': 1, 'result': 'success', 'type': 'testDone', 'time': 3},
      if (finished) {'success': success, 'type': 'done', 'time': 4},
    ];
    // Trailing newline included: that is what the reporter writes, and the
    // extractor has to tolerate the blank final line rather than read it as a
    // malformed event.
    return '${events.map(jsonEncode).join('\n')}\n';
  }

  group('the marker', () {
    test('is the same string the sweeps print', () {
      // The emitter runs under flutter_test and the extractor runs under bare
      // `dart run`, so the constant cannot be shared — this is the assertion that
      // makes a drift between them fail here instead of as an empty dataset that
      // reads as "no overflows anywhere".
      expect(overflowBaselineMarker, emitter.kOverflowBaselineMarker);
    });
  });

  group('the record shape', () {
    /// One record as the emitter actually builds it, marked as the sweeps print
    /// it. The whole point is that nothing about the incident's keys or their
    /// types is restated here.
    String emitted(
      String sweep,
      Map<String, Object?> axes,
      List<OverflowIncident> incidents, {
      bool threw = false,
    }) {
      final payload = emitter.overflowBaselineRecordLine(
        emitter.OverflowCell(sweep, axes),
        incidents,
        threw: threw,
      );
      return '${emitter.kOverflowBaselineMarker} $payload';
    }

    /// A resolved incident, built through the const constructor rather than
    /// through a diagnostics dump so the *types* are visible in the test: `line`
    /// is an `int`, which is exactly what #1351 changed.
    const resolved = OverflowIncident(
      pixels: 41.0,
      side: 'right',
      message: 'A RenderFlex overflowed by 41 pixels on the right.',
      fullLog: 'A RenderFlex overflowed by 41 pixels on the right.',
      file: 'lib/page/dashboard/views/components/a.dart',
      line: 120,
      widget: 'Row',
    );

    test('names the keys and the types this script reads, through the emitter',
        () {
      // The other half of the marker's problem, and #1351's AC 4. `incident(...)`
      // above hand-mirrors these keys, so it agrees with whatever it was written
      // against: it stayed green when the source columns moved from
      // `parseOverflowSource` (a `Map<String, String>`, so `"line":"120"`) to
      // [OverflowIncident] (an `int`, so `"line":120`). A format change in this
      // dataset has to fail here rather than surface later as a baseline diff, so
      // the key set and every value type are pinned against the real builder.
      final record = jsonDecode(
          emitted('card.width', {'card': 'lan_info'}, const [resolved])
              .substring(overflowBaselineMarker.length + 1)) as Map;

      expect(record.keys, ['cell', 'threw', 'incidents'],
          reason: '_decodeRecord reads exactly these three');
      expect(record['threw'], isA<bool>(),
          reason: 'a non-bool is refused outright — it would read as clean');

      final fields = (record['incidents'] as List).single as Map;
      expect(
          fields.keys, ['px', 'side', 'significant', 'widget', 'file', 'line'],
          reason: 'a key added here that this script does not read is silently '
              'dropped, and a key removed reaches the TSV as "-", which is '
              'indistinguishable from a location that never resolved');
      expect(fields['px'], isA<String>(),
          reason: 'a string, not a number: the unparseable case is '
              'double.infinity, which JSON has no literal for and jsonEncode '
              'refuses outright');
      expect(fields['side'], isA<String>());
      expect(fields['significant'], isA<bool>(),
          reason: 'computed beside kOverflowTolerancePx; anything else is '
              'refused, because defaulting it would mislabel every incident');
      expect(fields['widget'], isA<String>());
      expect(fields['file'], isA<String>());
      expect(fields['line'], isA<int>(),
          reason:
              'a JSON number since #1351 — the one type in this record that '
              'changed, and the reason this test exists');
    });

    test('renders an int line into the site column exactly as a string would',
        () {
      // Why #1351 is a no-op against the four frozen baselines even for a future
      // overflow row, not only for today's all-`clean` ones: `_field` renders
      // every column through `'$value'`, so `120` and `"120"` both reach `site`
      // as `120`. The type change is invisible past the JSON, which is what the
      // record's format comment claims — asserted rather than argued.
      final fromInt = extractBaseline(
          reporter([
            emitted('card.width', {'card': 'a'}, const [resolved])
          ]),
          sweep: 'card');
      final fromString = extractBaseline(
        reporter([
          marked('card.width|card=a', [
            incident(
              px: '41.0',
              side: 'right',
              significant: true,
              widget: 'Row',
              file: 'lib/page/dashboard/views/components/a.dart',
              line: 120,
            ),
          ]),
        ]),
        sweep: 'card',
      );

      expect(
          fromInt.rows.single,
          'card.width|card=a\toverflow\t41.0\tright\t'
          'lib/page/dashboard/views/components/a.dart:120\tRow');
      expect(fromInt.rows, fromString.rows);
    });

    test('leaves the site columns absent when the location did not resolve',
        () {
      // The other branch of the swap. Omitted keys, not explicit nulls — a reader
      // of a raw `#LAYOUT-CELL#` line can then tell "no location" from "a
      // location that came out empty".
      final line = emitted('chrome.top_bar', {
        'screen_px': 640
      }, [
        OverflowIncident.parse(
            'A RenderFlex overflowed by 7.5 pixels on the right.'),
      ]);

      final record =
          jsonDecode(line.substring(overflowBaselineMarker.length + 1)) as Map;
      expect((record['incidents'] as List).single as Map,
          {'px': '7.5', 'side': 'right', 'significant': true});

      expect(extractBaseline(reporter([line]), sweep: 'chrome').rows.single,
          'chrome.top_bar|screen_px=640\toverflow\t7.5\tright\t-\t-');
    });
  });

  group('the cell id grammar', () {
    // The emitter joins the sweep and its axes with `|`; this script splits the
    // group back off with `split('|').first` and then routes on the text before the
    // dot. Two halves of one grammar in files that cannot import each other — and a
    // drift between them fails quietly, by routing records to a baseline they do not
    // belong to or to none at all. So the round trip is asserted through the real
    // builder rather than through a hand-written id that agrees with both.
    test('survives the trip from the emitter into a dataset', () {
      final id = emitter.overflowBaselineCellId(
        const emitter.OverflowCell('card.width', {
          'card': 'lan_info',
          'px': '191',
          'tab': 0,
          'locale': 'de',
        }),
      );

      final extracted =
          extractBaseline(reporter([marked(id, const [])]), sweep: 'card');

      expect(extracted.rows.single, startsWith('$id\t'));
      expect(extracted.groups, ['card.width'],
          reason:
              'the group is read back off the id the emitter built, so this '
              'fails if either side changes the separator');
    });

    test('routes on the id, so a foreign sweep is refused and not merged', () {
      final id = emitter.overflowBaselineCellId(
        const emitter.OverflowCell('chrome.header', {'screen_px': '800'}),
      );

      expect(
        () => extractBaseline(reporter([marked(id, const [])]), sweep: 'card'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('chrome.header'))),
      );
    });
  });

  group('extract', () {
    test('renders one sorted row per measurement, clean cells included', () {
      final extracted = extractBaseline(
        reporter([
          marked('card.width|card=lan_info|width=max|locale=ar', [
            incident(
              px: '41.0',
              side: 'right',
              significant: true,
              widget: 'Row',
              file: 'lib/page/dashboard/views/components/a.dart',
              line: 120,
            ),
          ]),
          marked('card.width|card=lan_info|width=min|locale=ar', const []),
        ]),
        sweep: 'card',
      );

      expect(extracted.rows, [
        'card.width|card=lan_info|width=max|locale=ar\toverflow\t41.0\tright\t'
            'lib/page/dashboard/views/components/a.dart:120\tRow',
        'card.width|card=lan_info|width=min|locale=ar\tclean\t-\t-\t-\t-',
      ]);
      expect(extracted.cells, 2);
      expect(extracted.incidents, 1);
      expect(extracted.overflows, 1);
    });

    test('orders rows by content, not by the order the run emitted them', () {
      // AC 1 is byte-identical output across runs. Test order is already not
      // guaranteed to be stable — the ported framework deliberately regroups, and
      // `flutter test` may shard — so the dataset cannot inherit it.
      String render(List<String> records) => extractBaseline(
            reporter(records),
            sweep: 'card',
          ).rows.join('\n');

      final a = marked('card.width|card=b', const []);
      final b = marked('card.width|card=a', const []);
      expect(render([a, b]), render([b, a]));
      expect(
          render([a, b]),
          'card.width|card=a\tclean\t-\t-\t-\t-\n'
          'card.width|card=b\tclean\t-\t-\t-\t-');
    });

    test('keeps a sub-tolerance incident, labelled as noise', () {
      // The sweeps filter these out before asserting, so the dataset is the only
      // place they are visible. A port that loosened the filter has to look
      // different from a port that fixed the layout.
      final extracted = extractBaseline(
        reporter([
          marked('card.width|card=lan_info', [
            incident(px: '1.5', side: 'bottom', significant: false),
          ]),
        ]),
        sweep: 'card',
      );

      expect(extracted.rows.single,
          'card.width|card=lan_info\tnoise\t1.5\tbottom\t-\t-');
      expect(extracted.incidents, 1);
      expect(extracted.overflows, 0,
          reason: 'noise is not what the gate fails on');
    });

    test('records every incident of a cell, so a count change is visible', () {
      // Flutter reports an overflow once per RenderObject, so a card rendered per
      // list item reports N times (#1197). Collapsing them here would hide a port
      // that changed how many rows a card builds.
      final extracted = extractBaseline(
        reporter([
          marked('card.width|card=lan_info', [
            incident(px: '8.0', side: 'right', significant: true),
            incident(px: '8.0', side: 'right', significant: true),
          ]),
        ]),
        sweep: 'card',
      );

      expect(extracted.rows, hasLength(2));
      expect(extracted.rows.first, extracted.rows.last);
      expect(extracted.incidents, 2);
    });

    test('reads the marked line out of a multi-line print', () {
      // A `print` event carries whatever the test printed in one call, and cards
      // under test log freely. Only marked lines are records; the rest is noise.
      final extracted = extractBaseline(
        reporter([
          'allowlist notice: nothing tracked\n'
              '${marked('card.width|card=lan_info', const [])}\n'
              'wrote 1 png',
          'a line with no marker at all',
        ]),
        sweep: 'card',
      );

      expect(extracted.rows, hasLength(1));
    });

    test('records the suite relative to the run directory', () {
      // The reporter names suites absolutely and the header gets committed, so an
      // unnormalized path would write whoever captured it's home directory into
      // the repo.
      final absolute = reporter([marked('card.width|card=a', const [])])
          .replaceAll('"path":"test/sweep_test.dart"',
              '"path":"${Directory.current.path}/test/sweep_test.dart"');

      expect(extractBaseline(absolute, sweep: 'card').suites,
          ['test/sweep_test.dart']);
    });

    test('takes every group of the sweep it was asked for', () {
      final extracted = extractBaseline(
        reporter([
          marked('card.width|card=a', const []),
          marked('card.normal_band|card=a', const []),
          marked('card.profile|card=a', const []),
        ]),
        sweep: 'card',
      );

      expect(extracted.rows, hasLength(3));
      expect(
          extracted.groups, ['card.normal_band', 'card.profile', 'card.width']);
    });

    test('refuses a run that emitted records of another sweep', () {
      // Pointing `--sweep chrome` at the card suite's reporter file would
      // otherwise write a chrome baseline holding whatever few chrome-ish records
      // happened to be there, and every later diff would compare that fragment.
      expect(
        () => extractBaseline(
          reporter([
            marked('card.width|card=a', const []),
            marked('chrome.top_bar|width=640', const []),
          ]),
          sweep: 'card',
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('chrome.top_bar'), contains('card')))),
      );
    });

    test('refuses a run that emitted nothing for the sweep', () {
      // The capture is opt-in, so the likeliest way to get an empty dataset is a
      // missing `OVERFLOW_BASELINE=1` — and an empty baseline would then pass
      // every future diff.
      expect(
        () => extractBaseline(reporter(const []), sweep: 'card'),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'message', contains('no baseline records'))),
      );
    });

    test('refuses two records that claim the same cell', () {
      // Two coordinates colliding on one id means the axes do not identify the
      // measurement: one of the two would silently win, and the diff would then
      // compare a dataset that is missing a cell it thinks it has.
      expect(
        () => extractBaseline(
          reporter([
            marked('card.width|card=a', const []),
            marked('card.width|card=a', [
              incident(px: '9.0', side: 'right', significant: true),
            ]),
          ]),
          sweep: 'card',
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('twice'), contains('card.width|card=a')))),
      );
    });

    test('refuses a suite that failed to load', () {
      // A compile error means a whole suite contributed no cells at all. Without
      // this the extraction would happily write a truncated baseline, and the
      // missing cells would land on whoever ran the next diff.
      expect(
        () => extractBaseline(
          reporter(
            [marked('card.width|card=a', const [])],
            success: false,
            extraEvents: [
              {
                'test': {
                  'id': 9,
                  'name': 'loading test/page/dashboard/cards/x_test.dart',
                  'suiteID': 0,
                  'groupIDs': <Object>[],
                },
                'type': 'testStart',
                'time': 2,
              },
              {
                'testID': 9,
                'error': "Error: Couldn't resolve the package 'foo'",
                'stackTrace': '',
                'isFailure': false,
                'type': 'error',
                'time': 2,
              },
            ],
          ),
          sweep: 'card',
        ),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('failed to load'))),
      );
    });

    test('keeps a run whose tests failed — a red sweep is a valid baseline',
        () {
      // The point of the baseline is to freeze today's failures, which are real
      // and unfixed (#1240). A non-zero exit from the sweep is expected input.
      final extracted = extractBaseline(
        reporter(
          [
            marked('card.width|card=a', [
              incident(px: '41.0', side: 'right', significant: true),
            ]),
          ],
          success: false,
          extraEvents: [
            {
              'testID': 1,
              'error': 'Expected: no overflow',
              'stackTrace': '',
              'isFailure': true,
              'type': 'error',
              'time': 2,
            },
          ],
        ),
        sweep: 'card',
      );

      expect(extracted.overflows, 1);
    });

    test('refuses a reporter file that stops mid-run', () {
      // No `done` event means the process was killed or timed out, so the tail of
      // the dataset is missing — indistinguishable, once written, from cells that
      // laid out cleanly.
      expect(
        () => extractBaseline(
          reporter([marked('card.width|card=a', const [])], finished: false),
          sweep: 'card',
        ),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('did not finish'))),
      );
    });

    test('records a pump that never finished as unmeasured, not as clean', () {
      // A tree that failed to build reports no overflow, so without the flag its
      // record is byte-identical to a coordinate that fits: the cell is present, so
      // the diff does not call it lost, and it is empty, so it reads as a pass.
      final extracted = extractBaseline(
        reporter([
          marked('card.width|card=lan_info|width=max', const [], threw: true),
          marked('card.width|card=lan_info|width=min', const []),
        ]),
        sweep: 'card',
      );

      expect(extracted.rows, [
        'card.width|card=lan_info|width=max\terror\t-\t-\t-\t-',
        'card.width|card=lan_info|width=min\tclean\t-\t-\t-\t-',
      ]);
      expect(extracted.errors, 1);
      expect(extracted.cells, 2,
          reason:
              'it was enumerated, so it is a cell — just not a measured one');
    });

    test('keeps what a failed pump managed to measure before it died', () {
      // The incidents collected before the throw are real measurements and stay.
      // The `error` row is added beside them rather than replacing them, because a
      // cell with no rows at all is one the diff reports as never enumerated.
      final extracted = extractBaseline(
        reporter([
          marked(
              'card.width|card=lan_info|width=max',
              [
                incident(px: '41.0', side: 'right', significant: true),
              ],
              threw: true),
        ]),
        sweep: 'card',
      );

      expect(extracted.rows, [
        'card.width|card=lan_info|width=max\terror\t-\t-\t-\t-',
        'card.width|card=lan_info|width=max\toverflow\t41.0\tright\t-\t-',
      ]);
      expect(extracted.errors, 1);
      expect(extracted.overflows, 1);
    });

    test('refuses a record with no "threw" flag', () {
      // Same reasoning as the significance verdict below: defaulting it to false
      // would let an emitter that forgot the field mean "this coordinate was fine",
      // which is the one reading the dataset exists to make impossible.
      expect(
        () => extractBaseline(
          reporter([
            '$overflowBaselineMarker '
                '${jsonEncode({'cell': 'card.width|card=a', 'incidents': []})}',
          ]),
          sweep: 'card',
        ),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('threw'))),
      );
    });

    test('refuses a record with no significance verdict', () {
      // The verdict is computed next to `kOverflowTolerancePx` on the emitter
      // side. A record without one comes from an emitter that was ported wrong,
      // and defaulting it either way would misreport every incident in the run.
      expect(
        () => extractBaseline(
          reporter([
            marked('card.width|card=a', [
              {'px': '41.0', 'side': 'right'},
            ]),
          ]),
          sweep: 'card',
        ),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('significant'))),
      );
    });

    test('refuses a stream with a NUL hole in it', () {
      // Not hypothetical: `--file-reporter json:<file>` interleaves its writes and
      // leaves a 16KB run of NULs, and the first capture taken for this ticket lost
      // 22 of 75 cells to one. Nothing about the result looked wrong — it was a
      // smaller, entirely clean dataset. Refusing the stream is the only way that
      // does not end as a committed lie.
      final holed = reporter([marked('card.width|card=a', const [])])
          .replaceFirst(
              '"type":"suite"', '"type":${'\u0000'}${'\u0000'}"suite"');

      expect(
        () => extractBaseline(holed, sweep: 'card'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('NUL'))),
      );
    });

    test('refuses a stream cut off mid-event', () {
      // The other shape of the same problem: an event that starts and never
      // finishes means everything after it is gone.
      final cut = '${reporter([marked('card.width|card=a', const [])])}'
          '{"testID":9,"messageType":"print","mess';

      expect(
        () => extractBaseline(cut, sweep: 'card'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('truncated'))),
      );
    });

    test('ignores the flutter tool\'s own banner lines', () {
      // stdout carries the tool's plugin warnings alongside the events, so
      // non-event lines have to be skipped — which is why the two checks above
      // trigger on a line that *starts* like an event rather than on any
      // unparseable line.
      final withBanner =
          'The following plugins do not support Swift Package Manager for ios:\n'
          '  - printing\n'
          '${reporter([marked('card.width|card=a', const [])])}';

      expect(extractBaseline(withBanner, sweep: 'card').cells, 1);
    });

    test('refuses a record that is not readable as one', () {
      expect(
        () => extractBaseline(
          reporter(['$overflowBaselineMarker {this is not json']),
          sweep: 'card',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('the rendered file', () {
    ExtractedBaseline extracted() => extractBaseline(
          reporter([
            marked('card.width|card=a', [
              incident(px: '41.0', side: 'right', significant: true),
            ]),
            marked('card.width|card=b', const []),
          ]),
          sweep: 'card',
        );

    test('states the commit it was taken at, and the shape of what follows',
        () {
      final text = renderBaseline(extracted(),
          suite: 'test/page/dashboard/cards/x_test.dart', commit: 'abc1234');

      expect(
          text, startsWith('# overflow-baseline $overflowBaselineVersion\n'));
      expect(text, contains('# sweep card\n'));
      expect(text, contains('# commit abc1234\n'));
      expect(text, contains('# suite test/page/dashboard/cards/x_test.dart\n'));
      expect(text, contains('# cells 2\n'));
      expect(text, contains('# incidents 1\n'));
      expect(text, contains('# overflows 1\n'));
      expect(text, contains('# unmeasured 0\n'));
      expect(text, endsWith('\n'), reason: 'a text file ends in a newline');
    });

    test('is byte-identical for the same measurements', () {
      final a = renderBaseline(extracted(), suite: 's', commit: 'abc1234');
      final b = renderBaseline(extracted(), suite: 's', commit: 'abc1234');
      expect(a, b);
    });

    test('round-trips back into the same cells', () {
      final file = BaselineFile.parse(
          renderBaseline(extracted(), suite: 's', commit: 'abc1234'));
      expect(file.sweep, 'card');
      expect(file.commit, 'abc1234');
      expect(file.cells.keys, ['card.width|card=a', 'card.width|card=b']);
    });
  });

  group('diff', () {
    BaselineFile baselineOf(Map<String, List<Map<String, Object?>>> cells,
            {String sweep = 'card', String commit = 'aaaaaaa'}) =>
        BaselineFile.parse(renderBaseline(
          extractBaseline(
            reporter([
              for (final entry in cells.entries) marked(entry.key, entry.value),
            ]),
            sweep: sweep,
          ),
          suite: 's',
          commit: commit,
        ));

    final overflowing = [
      incident(
        px: '41.0',
        side: 'right',
        significant: true,
        widget: 'Row',
        file: 'lib/a.dart',
        line: 10,
      ),
    ];

    test('is clean when both sides measured the same thing', () {
      final diff = diffBaselines(
        baseline: baselineOf({
          'card.width|card=a': overflowing,
          'card.width|card=b': const [],
        }, commit: 'aaaaaaa'),
        actual: baselineOf({
          'card.width|card=a': overflowing,
          'card.width|card=b': const [],
        }, commit: 'bbbbbbb'),
      );

      expect(diff.isClean, isTrue,
          reason: 'the commit header differs and must not count as a change');
      expect(diff.report(), contains('2 cells'));
    });

    test('reports a cell that stopped being measured, and does not pass', () {
      // AC 5, and the single most dangerous failure mode: a port that quietly
      // drops a coordinate produces a run with fewer failures, which reads like
      // progress.
      final diff = diffBaselines(
        baseline: baselineOf({
          'card.width|card=a': overflowing,
          'card.width|card=b': const [],
        }),
        actual: baselineOf({'card.width|card=a': overflowing}),
      );

      expect(diff.isClean, isFalse);
      expect(diff.lostCells, ['card.width|card=b']);
      expect(diff.report(), contains('no longer measured'));
    });

    test('reports a cell nobody measured before', () {
      final diff = diffBaselines(
        baseline: baselineOf({'card.width|card=a': overflowing}),
        actual: baselineOf({
          'card.width|card=a': overflowing,
          'card.width|card=c': const [],
        }),
      );

      expect(diff.isClean, isFalse);
      expect(diff.newCells, ['card.width|card=c']);
    });

    test('reports a measurement that changed, with both readings', () {
      final diff = diffBaselines(
        baseline: baselineOf({'card.width|card=a': overflowing}),
        actual: baselineOf({'card.width|card=a': const []}),
      );

      expect(diff.isClean, isFalse);
      expect(diff.changedCells.single.cell, 'card.width|card=a');
      final report = diff.report();
      expect(report, contains('- '), reason: 'the baseline reading is shown');
      expect(report, contains('+ '), reason: 'the fresh reading is shown');
      expect(report, contains('41.0'));
      expect(report, contains('clean'));
    });

    test('calls out a cell whose pump died, rather than only that it changed',
        () {
      // It lands in the "changed" bucket because the coordinate is still
      // enumerated, but nothing was measured there — which is easy to skim past in
      // a list of before/after rows, so the report says it in words.
      final actual = BaselineFile.parse(renderBaseline(
        extractBaseline(
          reporter([marked('card.width|card=a', const [], threw: true)]),
          sweep: 'card',
        ),
        suite: 's',
        commit: 'bbbbbbb',
      ));

      final diff = diffBaselines(
        baseline: baselineOf({'card.width|card=a': const []}),
        actual: actual,
      );

      expect(diff.isClean, isFalse);
      expect(diff.lostCells, isEmpty, reason: 'the cell is still there');
      expect(diff.report(), contains('now "$verdictError"'));
      expect(diff.report(), contains('not measured this run'));
    });

    test('leads with lost coverage, because it is the one that reads as a pass',
        () {
      final diff = diffBaselines(
        baseline: baselineOf({
          'card.width|card=a': overflowing,
          'card.width|card=b': overflowing,
        }),
        actual: baselineOf({
          'card.width|card=a': const [],
          'card.width|card=c': const [],
        }),
      );

      final report = diff.report();
      expect(report.indexOf('no longer measured'),
          lessThan(report.indexOf('changed')));
      expect(report.indexOf('changed'), lessThan(report.indexOf('new')));
    });

    test('refuses to compare two different sweeps', () {
      // Comparing the chrome baseline against a card run would report every cell
      // as lost and every cell as new, which looks like a catastrophic port
      // rather than the wrong file path it is.
      expect(
        () => diffBaselines(
          baseline: baselineOf({'card.width|card=a': const []}),
          actual: baselineOf({'chrome.top_bar|width=640': const []},
              sweep: 'chrome'),
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('card'), contains('chrome')))),
      );
    });

    test('refuses a baseline written by a different format', () {
      // The dataset's meaning is in its columns. A file from a future format read
      // with today's parser would diff on layout rather than on layout.
      expect(
        () => BaselineFile.parse('# overflow-baseline 99\n# sweep card\n'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('format'))),
      );
    });

    test('refuses a file with no header at all', () {
      expect(() => BaselineFile.parse('card.width|card=a\tclean\t-\t-\t-\t-\n'),
          throwsA(isA<FormatException>()));
    });
  });

  group('render', () {
    /// A committed baseline, built through the extractor and the renderer so the
    /// report under test is read out of the same bytes the repo holds.
    BaselineFile fileOf(
      List<String> records, {
      String sweep = 'page',
      String commit = '69079cb0',
      String suite = 'test/page/_shared/page_surface_overflow_test.dart',
      String source = 'test/fixtures/overflow_baselines/page.tsv',
    }) =>
        BaselineFile.parse(
          renderBaseline(
            extractBaseline(reporter(records), sweep: sweep),
            suite: suite,
            commit: commit,
          ),
          source: source,
        );

    String markdown(List<String> records, {String commit = '69079cb0'}) =>
        renderReportMarkdown(
            BaselineReport.of(fileOf(records, commit: commit)));

    final overflowing = [
      incident(
        px: '41.0',
        side: 'right',
        significant: true,
        widget: 'Row',
        file: 'lib/a.dart',
        line: 10,
      ),
    ];

    test('says which commit the rows measure, and that it is not this tree',
        () {
      // The one way this report can mislead: every other artefact in the gate is
      // produced by running the code, so it describes the tree it ran against.
      // This one is rendered from a file that was committed at some earlier sha,
      // and a green report read as a statement about today would be exactly the
      // #1321 failure in a new wrapper.
      final text =
          markdown([marked('page.dhcp|screen_px=320|locale=ar', const [])]);

      expect(text, contains('69079cb0'));
      expect(text, contains('test/fixtures/overflow_baselines/page.tsv'));
      expect(
          text, contains('test/page/_shared/page_surface_overflow_test.dart'));
      expect(text, contains('not of the working tree'));
      expect(text, contains('capture page'),
          reason: 'the reader is told the one command that refreshes it');
    });

    test('repeats the -dirty stamp as a caveat, not only as a suffix', () {
      // `-dirty` in a header is a disclaimer a reader has to know to look for.
      // In a report it is prose, because the whole document is otherwise a
      // claim about a nameable commit.
      final text = markdown(
        [marked('page.dhcp|screen_px=320|locale=ar', const [])],
        commit: '69079cb0-dirty',
      );

      expect(text, contains('69079cb0-dirty'));
      expect(text, contains('will not reproduce'));
    });

    test('reports an all-clean sweep as coverage, not as an empty report', () {
      // The five committed baselines are all clean today, so this is the normal
      // case and it must not render as "nothing found". What the dataset proves
      // is that N coordinates were pumped and measured — the same reason a clean
      // cell is a row here rather than an absence.
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', const []),
        marked('page.dhcp|screen_px=320|locale=de', const []),
        marked('page.dhcp|screen_px=601|locale=ar', const []),
      ]);

      expect(text, contains('| Coordinates measured | 3 |'));
      expect(text, contains('| Clean | 3 |'));
      expect(text, contains('coverage claim'));
      expect(text, contains('all 3 coordinates measured clean'));
    });

    test('counts each group of the sweep on its own line', () {
      // A sweep's baseline holds every family that shares its id — `page.dhcp`
      // and `page.wifi_settings` here, six groups in the card file — and a total
      // alone cannot say which page a lost cell came from.
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', overflowing),
        marked('page.wifi_settings|screen_px=320|locale=ar', const []),
        marked('page.wifi_settings|screen_px=601|locale=ar', const []),
      ]);

      expect(text, contains('| page.dhcp | 1 | 0 | 0 | 1 | 0 |'));
      expect(text, contains('| page.wifi_settings | 2 | 2 | 0 | 0 | 0 |'));
    });

    test('counts an axis over the cells that carry it, and says how many', () {
      // Not every group of a sweep varies on every axis: three of the card
      // sweep's six groups enumerate no locale at all, and `popup.exempt`
      // enumerates none either. An axis table that printed only its own totals
      // would read as full coverage of an axis two thirds of the cells never
      // visit, so the denominator is the whole sweep.
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', const []),
        marked('page.exempt|screen_px=320', const []),
      ]);

      expect(text, contains('### `locale` — 1 value over 1 of 2 coordinates'));
      expect(
          text, contains('### `screen_px` — 1 value over 2 of 2 coordinates'));
    });

    test('sorts an axis numerically when every value is a number', () {
      // `screen_px=1241` sorted as text lands between 1 and 320, and this axis is
      // read as a range: the whole point of the width list is which widths were
      // visited, in order.
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', const []),
        marked('page.dhcp|screen_px=601|locale=ar', const []),
        marked('page.dhcp|screen_px=1241|locale=ar', const []),
      ]);

      expect(text.indexOf('| 320 |'), lessThan(text.indexOf('| 601 |')));
      expect(text.indexOf('| 601 |'), lessThan(text.indexOf('| 1241 |')));
    });

    test('lists every row that is not clean, keyed the way the allowlist is',
        () {
      // The `site` column is the `file:line` key `known_overflows.json` uses
      // (#1341), and the failure message a sweep prints is the other place it
      // appears. A report that rendered the location any other way would send a
      // reader to reconstruct a key the ratchet then refuses.
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', overflowing),
        marked('page.dhcp|screen_px=601|locale=ar', const []),
      ]);

      expect(text, contains('known_overflows.json'));
      expect(
          text,
          contains(r'| page.dhcp\|screen_px=320\|locale=ar | overflow | 41.0 | '
              r'right | lib/a.dart:10 | Row |'));
    });

    test('labels a sub-tolerance row as noise rather than as a failure', () {
      // These are recorded and not asserted on, so a report that listed them
      // beside overflows without saying so would read as a red sweep.
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', [
          incident(px: '1.5', side: 'bottom', significant: false),
        ]),
      ]);

      expect(text, contains('| Noise'));
      expect(text, contains('tolerance'));
      expect(text, contains('| noise | 1.5 | bottom |'));
    });

    test('says a cell whose pump never finished measured nothing', () {
      // The dataset's own central distinction, one layer out: an `error` row
      // collected no incidents, so a report that only tabulated verdicts would
      // let it read as a coordinate that fits.
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', const [], threw: true),
      ]);

      expect(text, contains('| Unmeasured'));
      expect(text, contains('measured nothing'));
      expect(text, contains('| error |'));
    });

    test('groups incidents by site, the most affected first', () {
      // One site overflows at many coordinates — that is why #1341 re-keyed the
      // fixture by location — so the count that matters when reading a red sweep
      // is per site, not per cell.
      final onB = [
        incident(
          px: '7.0',
          side: 'right',
          significant: true,
          widget: 'Column',
          file: 'lib/b.dart',
          line: 20,
        ),
      ];
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', overflowing),
        marked('page.dhcp|screen_px=601|locale=ar', onB),
        marked('page.dhcp|screen_px=905|locale=ar', onB),
      ]);

      expect(text.indexOf('lib/b.dart:20 | 2'),
          lessThan(text.indexOf('lib/a.dart:10 | 1')));
    });

    test('says an unresolved location can never be exempted', () {
      // A null site is not a key, and `"*"` on every allowlist entry still will
      // not cover it (`OverflowRatchet`). A row rendered as a bare `-` in a table
      // of copyable keys would not say that.
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', [
          incident(px: '9.0', side: 'right', significant: true),
        ]),
      ]);

      expect(text, contains('(unresolved)'));
      expect(text, contains('cannot be allowlisted'));
    });

    test('reports a header that disagrees with the rows instead of trusting it',
        () {
      // The counts in the header were written by the extractor at capture time;
      // the rows are the measurement. A file where they differ has been edited by
      // hand, and a report that printed the header's numbers would launder that
      // into a document nobody can tell apart from a real capture.
      final report = BaselineReport.of(BaselineFile.parse(
        '# overflow-baseline $overflowBaselineVersion\n'
        '# sweep page\n'
        '# cells 9\n'
        '# incidents 0\n'
        '# overflows 0\n'
        '# unmeasured 0\n'
        '# columns cell\tverdict\tpx\tside\tsite\twidget\n'
        'page.dhcp|screen_px=320|locale=ar\tclean\t-\t-\t-\t-\n',
        source: 'hand-edited.tsv',
      ));

      expect(report.headerDisagreements, hasLength(1));
      expect(report.headerDisagreements.single,
          allOf(contains('cells'), contains('9'), contains('1')));
      expect(renderReportMarkdown(report), contains('disagrees with its rows'));
      expect(report.cells, 1, reason: 'the rows are what is reported');
    });

    test('does not print a re-capture command it cannot name a sweep for', () {
      // The provenance paragraph tells the reader the one command that refreshes
      // the dataset, and the sweep name comes out of a header. A file without
      // that header would otherwise be handed `capture (unnamed)`, which is not a
      // command — worse than no advice, because it looks like one.
      final report = BaselineReport.of(BaselineFile.parse(
        '# overflow-baseline $overflowBaselineVersion\n'
        '# columns cell\tverdict\tpx\tside\tsite\twidget\n'
        'page.dhcp|screen_px=320|locale=ar\tclean\t-\t-\t-\t-\n',
        source: 'headerless.tsv',
      ));
      final text = renderReportMarkdown(report);

      expect(text, isNot(contains('capture (unnamed)')));
      expect(text, contains('which sweep wrote it'));
      expect(text, contains('carries no `commit` header'),
          reason: 'and the missing commit is stated rather than implied');
    });

    test('gives an unknown verdict a column of its own in every table', () {
      // A verdict from a newer emitter must not vanish. It is already counted
      // apart in the summary; without the same column on the coverage tables it
      // would sit inside `coordinates` and in none of the verdict columns, so
      // every row of those tables would silently fail to add up.
      final report = BaselineReport.of(BaselineFile.parse(
        '# overflow-baseline $overflowBaselineVersion\n'
        '# sweep page\n'
        '# columns cell\tverdict\tpx\tside\tsite\twidget\n'
        'page.dhcp|screen_px=320|locale=ar\tclipped\t-\t-\t-\t-\n'
        'page.dhcp|screen_px=601|locale=ar\tclean\t-\t-\t-\t-\n',
        source: 'newer-emitter.tsv',
      ));
      final text = renderReportMarkdown(report);

      expect(report.unrecognised, 1);
      expect(report.groups.single.unrecognised, 1);
      expect(text, contains('| Unrecognised verdict | 1 |'));
      expect(text, contains('| page.dhcp | 2 | 1 | 0 | 0 | 0 | 1 |'),
          reason: 'coordinates, clean, noise, overflow, unmeasured, then it');
      expect(text, contains('| unrecognised |'),
          reason: 'the column is only there when the dataset holds one');
      expect(text, contains('`$verdictClean`'),
          reason: 'and the four it does know are named, so the gap is legible');
    });

    test('renders the same bytes twice, so two reports can be diffed', () {
      // The dataset deliberately carries nothing volatile — no timestamps, no run
      // ids, no durations — and a report that stamped the time it was rendered
      // would put all of that back and make two reports differ on every line that
      // did not change.
      final records = [
        marked('page.dhcp|screen_px=320|locale=ar', overflowing),
        marked('page.dhcp|screen_px=601|locale=ar', const []),
      ];
      final first = BaselineReport.of(fileOf(records));
      final second = BaselineReport.of(fileOf(records));

      expect(renderReportMarkdown(first), renderReportMarkdown(second));
      expect(renderReportHtml(first), renderReportHtml(second));
    });

    test('escapes a value that would otherwise split a Markdown row', () {
      // Every cell id contains `|` — it is the axis separator — and a widget name
      // reaches the TSV with only tabs and newlines stripped. Unescaped, one row
      // of a table would silently gain columns and the reader would see a
      // mangled key.
      final text = markdown([
        marked('page.dhcp|screen_px=320|locale=ar', [
          incident(
            px: '41.0',
            side: 'right',
            significant: true,
            widget: 'Row|Column',
            file: 'lib/a.dart',
            line: 10,
          ),
        ]),
      ]);

      expect(text, contains(r'Row\|Column'));
      expect(text, contains(r'page.dhcp\|screen_px=320\|locale=ar'));
    });

    test('renders HTML as one self-contained document that escapes its data',
        () {
      // Opened straight out of `build/`, so no stylesheet to fetch and no
      // server; and the data is not markup — a widget name with angle brackets
      // must reach the page as text.
      final html = renderReportHtml(BaselineReport.of(fileOf([
        marked('page.dhcp|screen_px=320|locale=ar', [
          incident(
            px: '41.0',
            side: 'right',
            significant: true,
            widget: 'Row<Foo>',
            file: 'lib/a.dart',
            line: 10,
          ),
        ]),
      ])));

      expect(html, startsWith('<!DOCTYPE html>'));
      expect(html, contains('<style>'));
      expect(html, contains('Row&lt;Foo&gt;'));
      expect(html, isNot(contains('Row<Foo>')));
      expect(html, contains('69079cb0'));
      expect(html, contains('lib/a.dart:10'));
    });

    test('states the same numbers in both formats', () {
      // Two renderers over one model, so a count cannot be right in Markdown and
      // wrong in HTML — the failure a second hand-written renderer invites.
      final report = BaselineReport.of(fileOf([
        marked('page.dhcp|screen_px=320|locale=ar', overflowing),
        marked('page.dhcp|screen_px=601|locale=ar', const []),
      ]));

      for (final text in [
        renderReportMarkdown(report),
        renderReportHtml(report),
      ]) {
        expect(text, contains('page'));
        expect(text, contains('lib/a.dart:10'));
        expect(text, contains('2'), reason: 'two coordinates');
      }
      expect(report.cells, 2);
      expect(report.overflows, 1);
    });
  });

  group("render's screenshot gallery", () {
    /// The manifest `test/layout_gate/screenshot.dart` writes, as text.
    String manifest(Map<String, String> rows,
            {String format = 'overflow-screenshots 1'}) =>
        ['# $format', ...rows.entries.map((e) => '${e.key}\t${e.value}')]
            .join('\n');

    BaselineReport reportOf(
      List<String> records, {
      ScreenshotIndex shots = ScreenshotIndex.none,
    }) =>
        BaselineReport.of(
          BaselineFile.parse(
            renderBaseline(
              extractBaseline(reporter(records), sweep: 'page'),
              suite: 'test/page/_shared/page_surface_overflow_test.dart',
              commit: '69079cb0',
            ),
            source: 'test/fixtures/overflow_baselines/page.tsv',
          ),
          shots: shots,
        );

    test('is absent from a report that has no images', () {
      // The normal case, and the reason this is a section rather than a column:
      // four of the five sweeps will be rendered with no manifest at all, and an
      // empty gallery would read as "photographed and found nothing to show".
      final text = renderReportMarkdown(
          reportOf([marked('page.dhcp|screen_px=320|locale=ar', const [])]));

      expect(text, isNot(contains('Screenshots')));
      expect(ScreenshotIndex.none.images, isEmpty);
    });

    test('links every photographed cell, in cell-id order', () {
      // Sorted by cell id, not by the manifest's own order: the manifest is
      // append-ordered, so it holds the order the sweep happened to enumerate in,
      // and two runs of the same shoot would otherwise render two documents that
      // differ on every line of the gallery.
      final shots = ScreenshotIndex.parse(
        manifest({
          'page.dhcp|screen_px=601|locale=ar': 'b.png',
          'page.dhcp|screen_px=320|locale=ar': 'a.png',
        }),
        source: 'index.tsv',
        href: '../shots/page',
      );
      final text = renderReportMarkdown(
        reportOf([
          marked('page.dhcp|screen_px=320|locale=ar', const []),
          marked('page.dhcp|screen_px=601|locale=ar', const []),
        ], shots: shots),
      );

      expect(text, contains('## Screenshots'));
      expect(text, contains('../shots/page/a.png'));
      expect(text.indexOf('a.png'), lessThan(text.indexOf('b.png')));
      expect(text, contains('2 of the 2 coordinates'),
          reason:
              'a gallery is a subset of the dataset, and says which subset');
    });

    test('states the href relative to the report, not the shoot', () {
      // The manifest lives beside the images in `build/…/shots/<sweep>/` and the
      // report is written to `build/…/report/<sweep>.md`, so an href copied from
      // either path alone resolves to nothing in a browser. The one thing a reader
      // does with this document is click.
      final shots = ScreenshotIndex.parse(
        manifest({'page.dhcp|screen_px=320|locale=ar': 'a.png'}),
        source: 'index.tsv',
        href: '../shots/page',
      );

      expect(shots.images['page.dhcp|screen_px=320|locale=ar'],
          '../shots/page/a.png');
      expect(
        screenshotHref(
          fromFile: 'build/overflow_baseline/report/page.md',
          toDir: 'build/overflow_baseline/shots/page',
        ),
        '../shots/page',
      );
    });

    test('shows a thumbnail in HTML that opens the full image', () {
      // The whole point of the feature: the reader is comparing two widths of one
      // card by eye, so the images have to be on one page at a size that fits
      // several, and one click from full size.
      final html = renderReportHtml(
        reportOf([
          marked('page.dhcp|screen_px=320|locale=ar', const []),
        ],
            shots: ScreenshotIndex.parse(
              manifest({'page.dhcp|screen_px=320|locale=ar': 'a.png'}),
              source: 'index.tsv',
              href: '../shots/page',
            )),
      );

      expect(html, contains('<a href="../shots/page/a.png"'));
      expect(html, contains('loading="lazy"'),
          reason: 'a shoot of a whole sweep is thousands of images');
      expect(
          html, contains('page.dhcp|screen_px=320|locale=ar'.split('|').last));
    });

    test('will not link an image for a coordinate the dataset does not hold',
        () {
      // The two halves come from two runs, and nothing forces them to be the same
      // run. A gallery that linked an id the rows do not carry would be showing a
      // picture of a coordinate this document says nothing about — the same class
      // of mistake as trusting a header over its rows, so it is reported the same
      // way: recount from the rows, and say what did not reconcile.
      final shots = ScreenshotIndex.parse(
        manifest({
          'page.dhcp|screen_px=320|locale=ar': 'a.png',
          'page.dhcp|screen_px=999|locale=ar': 'gone.png',
        }),
        source: 'index.tsv',
        href: '../shots/page',
      );
      final report = reportOf(
        [marked('page.dhcp|screen_px=320|locale=ar', const [])],
        shots: shots,
      );
      final text = renderReportMarkdown(report);

      expect(text, contains('../shots/page/a.png'));
      expect(text, isNot(contains('gone.png')));
      expect(report.shotWarnings, hasLength(1));
      expect(report.shotWarnings.single,
          allOf(contains('1'), contains('page.dhcp|screen_px=999|locale=ar')));
      expect(text, contains('a different run'));
    });

    test('reads no images out of a manifest it does not recognise', () {
      // Versioned for the same reason the dataset is: the writer is
      // `test/layout_gate/screenshot.dart` and the reader is this script, and
      // nothing makes them ship together forever. A row shape this cannot read
      // must not be guessed at — an image linked under the wrong cell id is worse
      // than no gallery.
      final shots = ScreenshotIndex.parse(
        manifest({'page.dhcp|screen_px=320|locale=ar': 'a.png'},
            format: 'overflow-screenshots 99'),
        source: 'index.tsv',
        href: '../shots/page',
      );

      expect(shots.images, isEmpty);
      expect(shots.warnings.single,
          allOf(contains('index.tsv'), contains('overflow-screenshots 99')));
    });

    test('skips a row that is not a cell id and a name', () {
      // A truncated append — the manifest is written a row at a time, so a killed
      // shoot really can leave a half-written line.
      final shots = ScreenshotIndex.parse(
        '# overflow-screenshots 1\n'
        'page.dhcp|screen_px=320|locale=ar\ta.png\n'
        'page.dhcp|screen_px=601|locale=a',
        source: 'index.tsv',
        href: 'shots',
      );

      expect(shots.images, hasLength(1));
      expect(shots.warnings.single, contains('1 row'));
    });
  });

  group('the command', () {
    late File reporterFile;

    setUp(() {
      reporterFile = File('${tempDir.path}/report.json')
        ..writeAsStringSync(reporter([
          marked('card.width|card=a', [
            incident(px: '41.0', side: 'right', significant: true),
          ]),
          marked('card.width|card=b', const []),
        ]));
    });

    Future<(int, String, String)> run(List<String> args) async {
      final out = StringBuffer();
      final err = StringBuffer();
      final code = await runOverflowBaseline(args, out: out, err: err);
      return (code, out.toString(), err.toString());
    }

    /// A committed baseline, made the way one really is: by extracting it.
    /// `diff` and `render` both need one as *input*, and hand-writing the TSV
    /// instead would let them pass against a shape `extract` never emits.
    Future<String> capture() async {
      final path = '${tempDir.path}/card.tsv';
      await run([
        'extract',
        '--reporter',
        reporterFile.path,
        '--sweep',
        'card',
        '--out',
        path
      ]);
      return path;
    }

    test('extracts to a file and reports what it captured', () async {
      final target = '${tempDir.path}/card.tsv';
      final (code, out, err) = await run([
        'extract',
        '--reporter',
        reporterFile.path,
        '--sweep',
        'card',
        '--commit',
        'abc1234',
        '--out',
        target,
      ]);

      expect(code, 0, reason: err);
      expect(File(target).readAsStringSync(), contains('# commit abc1234'));
      expect(out, contains('2 cells'));
    });

    test('exits 0 when a fresh run matches the committed baseline', () async {
      final target = await capture();

      final (code, _, err) =
          await run(['diff', '--baseline', target, '--actual', target]);
      expect(code, 0, reason: err);
    });

    test('exits non-zero on any difference, and says what it was', () async {
      final baseline = await capture();

      final freshReporter = File('${tempDir.path}/report2.json')
        ..writeAsStringSync(reporter([
          marked('card.width|card=a', const []),
          marked('card.width|card=b', const []),
        ]));
      final fresh = '${tempDir.path}/fresh.tsv';
      await run([
        'extract',
        '--reporter',
        freshReporter.path,
        '--sweep',
        'card',
        '--out',
        fresh
      ]);

      final (code, out, _) =
          await run(['diff', '--baseline', baseline, '--actual', fresh]);
      expect(code, 1);
      expect(out, contains('card.width|card=a'));
    });

    test('diffs a reporter file directly, so a check needs one command',
        () async {
      // `check` is what the port tickets run: capture, extract, compare, in one
      // step, against the committed file.
      final baseline = await capture();

      final (code, _, err) = await run([
        'diff',
        '--baseline',
        baseline,
        '--reporter',
        reporterFile.path,
      ]);
      expect(code, 0, reason: err);
    });

    test('renders a committed baseline into Markdown on stdout', () async {
      // No test run: the input is the file the repo holds, which is what makes a
      // report cheap enough to ask for at review time.
      final baseline = await capture();

      final (code, out, err) = await run(['render', '--baseline', baseline]);
      expect(code, 0, reason: err);
      expect(out, contains('# Overflow baseline report — card'));
      expect(out, contains('| Coordinates measured | 2 |'));
    });

    test('writes the report to a file and says where it went', () async {
      final baseline = await capture();
      final target = '${tempDir.path}/report/card.html';

      final (code, out, err) = await run([
        'render',
        '--baseline',
        baseline,
        '--format',
        'html',
        '--out',
        target,
      ]);
      expect(code, 0, reason: err);
      expect(File(target).readAsStringSync(), startsWith('<!DOCTYPE html>'));
      expect(out, contains(target));
      expect(out, contains('2 cells'),
          reason: 'the same one-line summary `extract` prints');
    });

    test('exits 2 on a format it cannot write, naming the ones it can',
        () async {
      final baseline = await capture();

      final (code, _, err) =
          await run(['render', '--baseline', baseline, '--format', 'pdf']);
      expect(code, 2);
      expect(err, allOf(contains('pdf'), contains('md'), contains('html')));
    });

    test('exits 1 when the baseline disagrees with its own header', () async {
      // Same exit code as a diff that differs, and for the same reason: two
      // readings of one dataset do not match, so nothing here should be quoted
      // until someone has looked.
      final hand = File('${tempDir.path}/hand.tsv')
        ..writeAsStringSync('# overflow-baseline $overflowBaselineVersion\n'
            '# sweep card\n'
            '# cells 99\n'
            '# columns cell\tverdict\tpx\tside\tsite\twidget\n'
            'card.width|card=a\tclean\t-\t-\t-\t-\n');

      final (code, out, err) = await run(['render', '--baseline', hand.path]);
      expect(code, 1);
      expect(out, contains('disagrees with its rows'),
          reason: 'the document says so too, since that is what gets read');
      expect(err, contains('99'));
    });

    test('exits 2 with usage on a command it does not have', () async {
      final (code, _, err) = await run(['frobnicate']);
      expect(code, 2);
      expect(err, contains('usage'));
    });

    test('exits 2 when a required option is missing', () async {
      final (code, _, err) = await run(['extract', '--sweep', 'card']);
      expect(code, 2);
      expect(err, contains('--reporter'));
    });

    test('exits 2 rather than throwing when the input is unusable', () async {
      final (code, _, err) = await run([
        'extract',
        '--reporter',
        '${tempDir.path}/nope.json',
        '--sweep',
        'card',
      ]);
      expect(code, 2);
      expect(err, contains('nope.json'));
    });

    test('answers a request for the usage text as a success, on stdout',
        () async {
      // The option parser rejects anything it does not know, so `-h` used to be
      // reported as an unexpected argument — printing this text as an *error*,
      // on stderr, with exit 2, to someone who had asked for it. All three
      // spellings, and after the command as well as instead of it, because
      // tool/overflow_baseline.sh takes them in both positions.
      for (final args in [
        ['help'],
        ['-h'],
        ['--help'],
        ['extract', '--help'],
      ]) {
        final (code, out, err) = await run(args);
        expect(code, 0, reason: '"${args.join(' ')}" exited $code: $err');
        expect(out, contains('usage'),
            reason: '"${args.join(' ')}" wrote nothing to stdout');
        expect(err, isEmpty, reason: 'asking for help is not an error');
      }
    });

    test('a baseline naming no sweep is sent for re-capture, not for --sweep',
        () async {
      // `--sweep` was accepted here as a fallback and could never work: it is
      // consulted only when the baseline names no sweep, and the diff then
      // refuses that exact mismatch ("(none)" vs "card"). So the message has to
      // ask for the one thing that fixes it.
      final headerless = File('${tempDir.path}/headerless.tsv')
        ..writeAsStringSync('# overflow-baseline $overflowBaselineVersion\n'
            'card.width|card=a\tclean\t-\t-\t-\t-\n');

      final (code, _, err) = await run([
        'diff',
        '--baseline',
        headerless.path,
        '--reporter',
        reporterFile.path,
        '--sweep',
        'card',
      ]);
      expect(code, 2);
      expect(err, contains('# sweep'));
      expect(err, contains('capture'));
    });
  });

  group('the -dirty stamp', () {
    test('measures the same paths as the shell wrapper', () {
      // Two implementations of one stamp: `tool/overflow_baseline.sh` computes it
      // and passes --commit, and this script computes it for a direct
      // `dart run … extract`. A stamp that were honest only through the wrapper
      // would be the misleading half by default, so the lists are held equal
      // here rather than by a comment asking for it.
      final shell = File('tool/overflow_baseline.sh').readAsStringSync();
      final declaration =
          RegExp(r'^MEASURED_PATHS=\(([^)]*)\)$', multiLine: true)
              .firstMatch(shell);
      expect(declaration, isNotNull,
          reason: 'tool/overflow_baseline.sh no longer declares '
              'MEASURED_PATHS=(...) — find what replaced it and re-point this '
              'test, because nothing else checks the two agree');
      expect(
        declaration!.group(1)!.trim().split(RegExp(r'\s+')),
        kBaselineMeasuredPaths,
      );
    });

    test('names only paths that git can actually report on', () {
      // A gitignored path in the pathspec reads as coverage and provides none:
      // `git status --porcelain -- <ignored>` is silent, so the stamp would stay
      // clean through any change to it. pubspec.lock is the live example — it is
      // ignored in this repo, which is why it is not on the list.
      for (final path in kBaselineMeasuredPaths) {
        final ignored = Process.runSync('git', ['check-ignore', path]);
        expect(ignored.exitCode, isNot(0),
            reason: '"$path" is gitignored, so listing it as measured claims a '
                'dirty check that cannot fire');
      }
    });
  });
}
