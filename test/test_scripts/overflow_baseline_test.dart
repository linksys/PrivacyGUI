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
      final target = '${tempDir.path}/card.tsv';
      await run([
        'extract',
        '--reporter',
        reporterFile.path,
        '--sweep',
        'card',
        '--out',
        target
      ]);

      final (code, _, err) =
          await run(['diff', '--baseline', target, '--actual', target]);
      expect(code, 0, reason: err);
    });

    test('exits non-zero on any difference, and says what it was', () async {
      final baseline = '${tempDir.path}/card.tsv';
      await run([
        'extract',
        '--reporter',
        reporterFile.path,
        '--sweep',
        'card',
        '--out',
        baseline
      ]);

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
      final baseline = '${tempDir.path}/card.tsv';
      await run([
        'extract',
        '--reporter',
        reporterFile.path,
        '--sweep',
        'card',
        '--out',
        baseline
      ]);

      final (code, _, err) = await run([
        'diff',
        '--baseline',
        baseline,
        '--reporter',
        reporterFile.path,
      ]);
      expect(code, 0, reason: err);
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
  });
}
