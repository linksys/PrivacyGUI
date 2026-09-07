@Tags(['layout-gate'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'overflow_baseline.dart';
import 'overflow_probe.dart';

/// Guards the capture side of the sweep baselines (#1337).
///
/// The baseline is only worth what its emission is worth: every port downstream
/// of #1342 is verified by diffing a fresh capture against a committed one, so a
/// cell that stops being emitted, an axis that changes spelling, or a source
/// location that stops resolving all read as "the port changed the layout". The
/// tests below pin the three things a reader of a diff has to be able to trust —
/// the cell-id grammar, the record shape, and that the site really does resolve
/// out of Flutter's own error text rather than out of a fixture.
void main() {
  tearDown(() {
    debugOverflowBaselineCapture = null;
  });

  /// Collects everything [body] prints, which is how the emitter is observed:
  /// its whole contract is one line on stdout per measured cell, because
  /// `flutter test --reporter json` turns each `print` into a `print` event
  /// already attributed to the test that made it.
  List<String> capturePrints(void Function() body) {
    final lines = <String>[];
    runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) => lines.add(line),
      ),
    );
    return lines;
  }

  /// A diagnostics dump shaped like the one Flutter hands `FlutterError.onError`
  /// for a real overflow, trimmed to the two blocks the extraction reads. The
  /// end-to-end test below is what pins it against the live format.
  String dumpFor({
    required String message,
    String widget = 'Row',
    String file = 'lib/page/dashboard/views/components/usp_hero_row.dart',
    int line = 120,
  }) =>
      '══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞══\n'
      'The following assertion was thrown during layout:\n'
      '$message\n'
      '\n'
      'The relevant error-causing widget was:\n'
      '  $widget\n'
      '  $widget:file://${Directory.current.path}/$file:$line:18\n'
      '\n'
      'The specific RenderFlex in question is: RenderFlex#64715 OVERFLOWING:\n';

  group('cell ids', () {
    test('read as sweep then axes, in the order the sweep declared them', () {
      expect(
        overflowBaselineCellId(const OverflowCell('card.width', {
          'card': 'device_info',
          'width': 'min',
          'px': 191.4,
          'tab': 0,
          'locale': 'ar',
        })),
        'card.width|card=device_info|width=min|px=191.4|tab=0|locale=ar',
      );
    });

    test('keep a separator out of a value, so a row stays one row', () {
      // The chrome family names its header modes in prose ("viewing, local (3
      // actions)"), and nothing stops a future axis from carrying a pipe or a
      // tab. Either would split one TSV row into two and the diff would read as
      // a coverage change.
      expect(
        overflowBaselineCellId(const OverflowCell('chrome.header', {
          'mode': 'a|b\tc\nd',
        })),
        'chrome.header|mode=a_b_c_d',
      );
    });

    test('and a sweep id is not allowed to be empty', () {
      // A record with no sweep prefix cannot be routed to a baseline file, and
      // `extract` validates the prefix — failing here names the mistake at the
      // call site instead of as a rejected record 3,000 lines later.
      expect(() => overflowBaselineCellId(const OverflowCell('', {'a': 1})),
          throwsArgumentError);
      expect(() => overflowBaselineCellId(const OverflowCell('card.width', {})),
          throwsArgumentError);
    });
  });

  group('records', () {
    test('a clean cell is emitted, not omitted', () {
      // The whole of AC 5: a cell that was measured and found clean has to be
      // distinguishable from a cell nobody measured, or a dropped cell reads as
      // a pass.
      final line = overflowBaselineRecordLine(
        const OverflowCell('card.width', {'card': 'lan_info'}),
        const [],
        threw: false,
      );
      expect(jsonDecode(line), {
        'cell': 'card.width|card=lan_info',
        'threw': false,
        'incidents': <Object>[],
      });
    });

    test('an overflow carries its pixels, its side and its source location',
        () {
      // The resolved half of #1351's swap: the three source columns come off
      // [OverflowIncident] now, not out of a second call into the golden
      // framework's `parseOverflowSource`. `line` is therefore a JSON **number**
      // — that parser returned `Map<String, String>` and emitted `"120"`, the
      // incident carries an `int` and emits `120`. Written as an unquoted literal
      // here so the type is the assertion rather than a detail of it.
      final line = overflowBaselineRecordLine(
        const OverflowCell('card.width', {'card': 'network_health'}),
        [
          OverflowIncident.parse(
            'A RenderFlex overflowed by 41 pixels on the right.',
            fullLog: dumpFor(
              message: 'A RenderFlex overflowed by 41 pixels on the right.',
            ),
          ),
        ],
        threw: false,
      );
      expect(jsonDecode(line), {
        'cell': 'card.width|card=network_health',
        'threw': false,
        'incidents': [
          {
            'px': '41.0',
            'side': 'right',
            'significant': true,
            'widget': 'Row',
            'file': 'lib/page/dashboard/views/components/usp_hero_row.dart',
            'line': 120,
          },
        ],
      });
    });

    test(
        'a file with no line contributes neither, so no half a join key '
        'reaches the dataset', () {
      // Unreachable through [OverflowIncident.parse], which sets the three
      // together — but the const constructor is public, and the extractor builds
      // its `site` column as the bare path when `line` is absent. That row would
      // read as a resolved location that joins to nothing, which is the same
      // argument [OverflowIncident.site] makes for checking both halves. Before
      // #1351 the shape was structural: `parseOverflowSource` returned all three
      // keys or `{}`, never a subset. Keeping it structural is what this pins.
      final line = overflowBaselineRecordLine(
        const OverflowCell('card.width', {'card': 'dhcp_leases'}),
        const [
          OverflowIncident(
            pixels: 41.0,
            side: 'right',
            message: 'A RenderFlex overflowed by 41 pixels on the right.',
            file: 'lib/page/dhcp/leases_card.dart',
            widget: 'Row',
          ),
        ],
        threw: false,
      );
      expect(jsonDecode(line), {
        'cell': 'card.width|card=dhcp_leases',
        'threw': false,
        'incidents': [
          {'px': '41.0', 'side': 'right', 'significant': true, 'widget': 'Row'},
        ],
      });
    });

    test(
        'a sub-tolerance incident is recorded, and recorded as not significant',
        () {
      // The sweeps drop these before asserting, so the dataset is the only place
      // they are visible. Keeping them labelled is what makes a port that
      // loosened the filter distinguishable from a port that fixed a layout —
      // and the label is computed here, next to [kOverflowTolerancePx], so the
      // extractor never restates the number.
      final line = overflowBaselineRecordLine(
        const OverflowCell('card.width', {'card': 'lan_info'}),
        [
          OverflowIncident.parse(
            'A RenderFlex overflowed by 1.5 pixels on the bottom.',
            fullLog: 'A RenderFlex overflowed by 1.5 pixels on the bottom.',
          ),
        ],
        threw: false,
      );
      expect(jsonDecode(line), {
        'cell': 'card.width|card=lan_info',
        'threw': false,
        'incidents': [
          {'px': '1.5', 'side': 'bottom', 'significant': false},
        ],
      });
    });

    test('an unresolvable location still records the measurement', () {
      // The unresolved half of #1351's swap, and the reason the three keys are
      // omitted rather than emitted as nulls: [OverflowIncident.parse] resolves
      // no location when creation tracking cannot name the widget, exactly as
      // `parseOverflowSource` returned `{}`. Dropping the incident then would
      // turn a real overflow into a clean cell — so the site fields go absent and
      // the pixels stay.
      final line = overflowBaselineRecordLine(
        const OverflowCell('chrome.top_bar', {'width': 640}),
        [
          OverflowIncident.parse(
            'A RenderFlex overflowed by 7.5 pixels on the right.',
            fullLog: 'A RenderFlex overflowed by 7.5 pixels on the right.',
          ),
        ],
        threw: false,
      );
      expect(
        jsonDecode(line),
        {
          'cell': 'chrome.top_bar|width=640',
          'threw': false,
          'incidents': [
            {'px': '7.5', 'side': 'right', 'significant': true},
          ],
        },
        reason: 'an exact map match, so this also asserts the three keys are '
            'absent rather than present-and-null. The extractor would render '
            'either the same way, so the pin is on the record shape #1337 froze: '
            'a reader of a raw `#LAYOUT-CELL#` line can tell "no location" from '
            '"a location that came out empty" only if the keys are missing',
      );
    });

    test('an unparseable message reaches the dataset as infinity, not as 0',
        () {
      // [OverflowIncident.unparseablePixels] is infinity precisely so a message
      // shape Flutter changed cannot read as clean. The baseline must not round
      // that away.
      final line = overflowBaselineRecordLine(
        const OverflowCell('card.width', {'card': 'lan_info'}),
        [OverflowIncident.parse('A RenderFlex overflowed somehow.')],
        threw: false,
      );
      expect(jsonDecode(line), {
        'cell': 'card.width|card=lan_info',
        'threw': false,
        'incidents': [
          {'px': 'Infinity', 'side': 'unknown', 'significant': true},
        ],
      });
    });
  });

  group('emission', () {
    test('is off unless it is asked for', () {
      // The five sweeps run in the PR gate on every push. Emitting there would
      // put ~4,000 lines through the reporter for no reader.
      final lines = capturePrints(() {
        emitOverflowBaselineRecord(
          const OverflowCell('card.width', {'card': 'lan_info'}),
          const [],
          threw: false,
        );
      });
      expect(lines, isEmpty);
    });

    test('is one marked line per measured cell when it is', () {
      debugOverflowBaselineCapture = true;
      final lines = capturePrints(() {
        emitOverflowBaselineRecord(
          const OverflowCell('card.width', {'card': 'lan_info'}),
          const [],
          threw: false,
        );
      });
      expect(lines, hasLength(1));
      expect(lines.single, startsWith('$kOverflowBaselineMarker '));
      expect(
        jsonDecode(lines.single.substring(kOverflowBaselineMarker.length + 1)),
        {
          'cell': 'card.width|card=lan_info',
          'threw': false,
          'incidents': <Object>[],
        },
      );
    });

    test('says nothing for a probe that declared no cell', () {
      // Not every pump through the probe is a sweep coordinate: the popup file
      // uses it to reach a dialog's height, and the report generator re-pumps a
      // recommended geometry. Those measurements have no coordinate to be
      // diffed at, so they stay out of the dataset rather than arriving as
      // unlabelled rows.
      debugOverflowBaselineCapture = true;
      expect(
          capturePrints(
              () => emitOverflowBaselineRecord(null, const [], threw: false)),
          isEmpty);
    });
  });

  testWidgets('the site resolves out of Flutter\'s own error text',
      (tester) async {
    // The one test here that is not about our own formatting. Everything above
    // feeds the extraction a dump this file wrote; this one induces a real
    // overflow and asserts the location comes back — which is the assertion that
    // fails if an SDK upgrade moves the error-causing-widget block, instead of
    // 3,500 rows quietly losing their join column.
    debugOverflowBaselineCapture = true;
    final lines = <String>[];
    await runZoned(
      () async {
        await collectOverflow(
          tester,
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 50,
                child: Row(
                  children: const [
                    SizedBox(width: 100, height: 20),
                    SizedBox(width: 100, height: 20),
                  ],
                ),
              ),
            ),
          ),
          surfaceSize: const Size(300, 300),
          cell: const OverflowCell('probe.self', {'case': 'row overflows'}),
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) => lines.add(line),
      ),
    );

    expect(lines, hasLength(1),
        reason: 'one cell was measured, so one record is emitted');
    final record =
        jsonDecode(lines.single.substring(kOverflowBaselineMarker.length + 1))
            as Map;
    expect(record['cell'], 'probe.self|case=row overflows');
    final incident = (record['incidents'] as List).single as Map;
    expect(incident['px'], '150.0');
    expect(incident['side'], 'right');
    expect(incident['significant'], true);
    expect(incident['widget'], 'Row');
    expect(incident['file'], 'test/util/overflow_baseline_test.dart',
        reason: 'the path is relative to the run directory, so two machines '
            'record the same site — and it is normalised at collection time now, '
            'which is why the record builder no longer takes a runDirectory');
    expect(incident['line'], isA<int>(),
        reason: 'a JSON number, not a quoted string: #1351 replaced '
            'parseOverflowSource (Map<String, String>) with the incident\'s own '
            'int line, and this is the assertion that sees that move on a real '
            'overflow rather than on a fixture');
  });

  test('a pump that never finished is flagged, not recorded as clean',
      () async {
    // The other half of AC 5, one level in from a missing row. A tree that fails
    // to build lays nothing out, so it reports no overflow, so its record would be
    // byte-identical to a coordinate that fits — present in the dataset, therefore
    // not lost coverage, and empty, therefore a pass. The flag is what keeps
    // "nothing was measured here" from meaning "nothing was wrong here".
    debugOverflowBaselineCapture = true;
    final lines = <String>[];
    await runZoned(
      () async {
        await expectLater(
          runWithOverflowCollection(
            cell: const OverflowCell('probe.self', {'case': 'body throws'}),
            (sink) async => throw StateError('the fixture blew up'),
          ),
          throwsStateError,
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) => lines.add(line),
      ),
    );

    expect(lines, hasLength(1),
        reason: 'the record is still emitted — dropping it would read as lost '
            'coverage and send the reader after the wrong thing');
    expect(
      jsonDecode(lines.single.substring(kOverflowBaselineMarker.length + 1)),
      {
        'cell': 'probe.self|case=body throws',
        'threw': true,
        'incidents': <Object>[],
      },
    );
  });
}
