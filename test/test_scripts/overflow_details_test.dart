import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../test_scripts/overflow_details.dart';

/// Guards the shared loader both golden reports use to render overflow detail.
///
/// The collapsing behaviour is the reason this is shared rather than duplicated:
/// Flutter reports an overflow per RenderObject, so a list of N identical rows
/// writes N identical records. Two report generators diverging on how they
/// collapse them would show two different counts for the same run (#1197).
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('overflow_details_test');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  /// Writes [records] to a throwaway report file and loads it back.
  OverflowReport loadReport(List<Map<String, String>> records) {
    final file = File('${tempDir.path}/overflow_warnings.json');
    file.writeAsStringSync(jsonEncode(records));
    return loadOverflowReport(path: file.path);
  }

  /// Loads [records] and returns only the per-golden details.
  Map<String, List<OverflowDetail>> load(List<Map<String, String>> records) =>
      loadReport(records).byGolden;

  Map<String, String> record({
    String golden = 'admin-data-phone480-de',
    String pixels = '74',
    String side = 'right',
    String widget = 'Row',
    String file = 'lib/page/firmware_update/views/firmware_update_card.dart',
    String line = '77',
    String? log,
  }) =>
      {
        'golden': golden,
        'message': 'A RenderFlex overflowed by $pixels pixels on the $side.',
        'pixels': pixels,
        'side': side,
        'widget': widget,
        'file': file,
        'line': line,
        if (log != null) 'log': log,
      };

  group('loadOverflowReport – byGolden', () {
    test('groups details under the golden they belong to', () {
      final details = load([
        record(golden: 'admin-data-phone480-de'),
        record(golden: 'admin-data-desktop1280-de', pixels: '92'),
      ]);

      expect(details.keys,
          {'admin-data-phone480-de', 'admin-data-desktop1280-de'});
      expect(details['admin-data-phone480-de']!.single.pixels, '74');
      expect(details['admin-data-desktop1280-de']!.single.pixels, '92');
    });

    test('collapses identical records and counts the occurrences', () {
      // A card rendered once per list item reports the same overflow N times.
      final details = load([record(), record(), record()]);

      final site = details['admin-data-phone480-de']!.single;
      expect(site.occurrences, 3);
      expect(site.line, '77');
    });

    test('keeps distinct sites in the same golden separate', () {
      final details = load([
        record(line: '77'),
        record(line: '120', pixels: '12'),
        record(file: 'lib/page/admin/views/usp_admin_view.dart', line: '77'),
      ]);

      expect(details['admin-data-phone480-de'], hasLength(3));
      expect(
        details['admin-data-phone480-de']!.every((d) => d.occurrences == 1),
        isTrue,
      );
    });

    test('treats the same line overflowing by different amounts as distinct',
        () {
      // Rows built from one widget can overflow by different amounts per item;
      // both numbers are worth showing.
      final details = load([record(pixels: '74'), record(pixels: '92')]);

      expect(
        details['admin-data-phone480-de']!.map((d) => d.pixels),
        containsAll(['74', '92']),
      );
    });

    test('orders sites deterministically by file then line then amount', () {
      final details = load([
        record(file: 'lib/b.dart', line: '10'),
        record(file: 'lib/a.dart', line: '200'),
        record(file: 'lib/a.dart', line: '30'),
      ]);

      expect(
        details['admin-data-phone480-de']!.map((d) => '${d.file}:${d.line}'),
        ['lib/a.dart:30', 'lib/a.dart:200', 'lib/b.dart:10'],
      );
    });

    test('keeps a record whose location could not be resolved', () {
      // The extraction layer writes the raw message even when the diagnostics
      // dump carries no creation location, so the report must not drop it.
      final details = load([
        {
          'golden': 'admin-data-phone480-de',
          'message': 'A RenderFlex overflowed by 74 pixels on the right.',
        }
      ]);

      final site = details['admin-data-phone480-de']!.single;
      expect(site.file, isNull);
      expect(site.message, contains('74 pixels'));
    });

    test('keeps unresolved records with different messages separate', () {
      // With no location to key on, the message is the only thing telling two
      // distinct overflows apart.
      final details = load([
        {'golden': 'g', 'message': 'A RenderFlex overflowed left.'},
        {'golden': 'g', 'message': 'A RenderFlex overflowed right.'},
      ]);

      expect(details['g'], hasLength(2));
    });

    test('returns no details when the report file is absent', () {
      expect(
        loadOverflowReport(path: '${tempDir.path}/does_not_exist.json')
            .byGolden,
        isEmpty,
      );
    });

    test('returns no details when the report file is malformed', () {
      // A truncated write must not take the whole report generator down.
      final file = File('${tempDir.path}/overflow_warnings.json');
      file.writeAsStringSync('[{"golden": "x",');

      expect(loadOverflowReport(path: file.path).byGolden, isEmpty);
    });

    test('skips records carrying no golden name', () {
      final details = load([
        {'message': 'A RenderFlex overflowed by 74 pixels on the right.'},
        record(),
      ]);

      expect(details.keys, {'admin-data-phone480-de'});
    });
  });

  group('OverflowDetail.label', () {
    test('reads as widget, location and amount', () {
      final details = load([record()]);

      expect(
        details['admin-data-phone480-de']!.single.label,
        'Row · firmware_update_card.dart:77 · 74px right',
      );
    });

    test('appends the occurrence count when a site repeats', () {
      final details = load([record(), record()]);

      expect(details['admin-data-phone480-de']!.single.label, endsWith('(×2)'));
    });

    test('shows the amount alone when the location did not resolve', () {
      // Never the raw message: it is free-form text, and the badge is a compact
      // one-liner. The full message stays in the tooltip.
      final details = load([
        {
          'golden': 'admin-data-phone480-de',
          'message': 'A RenderFlex overflowed by 74 pixels on the right.',
          'pixels': '74',
          'side': 'right',
        }
      ]);

      expect(details['admin-data-phone480-de']!.single.label, '74px right');
    });

    test('omits the amount when only the location resolved', () {
      final details = load([
        {
          'golden': 'admin-data-phone480-de',
          'message': 'A RenderFlex overflowed.',
          'widget': 'Row',
          'file': 'lib/page/admin/views/usp_admin_view.dart',
          'line': '42',
        }
      ]);

      expect(details['admin-data-phone480-de']!.single.label,
          'Row · usp_admin_view.dart:42');
    });

    test('is empty when nothing resolved, so the badge stands alone', () {
      final details = load([
        {
          'golden': 'admin-data-phone480-de',
          'message': 'A RenderFlex overflowed.',
        }
      ]);

      expect(details['admin-data-phone480-de']!.single.label, isEmpty);
    });

    test('keeps the full path available for the tooltip', () {
      final details = load([record()]);

      expect(
        details['admin-data-phone480-de']!.single.file,
        'lib/page/firmware_update/views/firmware_update_card.dart',
      );
    });
  });

  group('toJson', () {
    test('carries the fields the report JavaScript renders', () {
      final json =
          load([record(), record()])['admin-data-phone480-de']!.single.toJson();

      expect(json['label'], isNotEmpty);
      expect(json['file'],
          'lib/page/firmware_update/views/firmware_update_card.dart');
      expect(json['line'], '77');
      expect(json['occurrences'], 2);
    });
  });

  group('raw log table', () {
    test('holds the log once and points the site at it by index', () {
      final report = loadReport([record(log: 'full dump A')]);

      final site = report.byGolden['admin-data-phone480-de']!.single;
      expect(site.logIndex, 0);
      expect(report.logs, ['full dump A']);
    });

    test('stores one entry for a log repeated across goldens', () {
      // A single culprit shows up in every golden that renders it — 6 goldens
      // for one card in a real run. Embedding the ~2-4KB dump per golden would
      // multiply into the report for no added information.
      final report = loadReport([
        record(golden: 'a', log: 'same dump'),
        record(golden: 'b', log: 'same dump'),
        record(golden: 'c', log: 'same dump'),
      ]);

      expect(report.logs, hasLength(1));
      expect(
        ['a', 'b', 'c'].map((g) => report.byGolden[g]!.single.logIndex),
        everyElement(0),
      );
    });

    test('keeps distinct logs apart', () {
      final report = loadReport([
        record(golden: 'a', log: 'dump A'),
        record(golden: 'b', log: 'dump B'),
      ]);

      expect(report.logs, hasLength(2));
      expect(
        report.byGolden['a']!.single.logIndex,
        isNot(report.byGolden['b']!.single.logIndex),
      );
    });

    test('reuses the first log when a site collapses duplicate records', () {
      // Sibling rows report the same overflow N times with near-identical
      // dumps. The site is one site, so it gets one button.
      final report = loadReport([
        record(log: 'dump for row 1'),
        record(log: 'dump for row 2'),
      ]);

      final site = report.byGolden['admin-data-phone480-de']!.single;
      expect(site.occurrences, 2);
      expect(report.logs[site.logIndex!], 'dump for row 1');
    });

    test('leaves logIndex null when the record carries no log', () {
      // Records written before the log was captured must still render.
      final report = loadReport([record()]);

      expect(
          report.byGolden['admin-data-phone480-de']!.single.logIndex, isNull);
      expect(report.logs, isEmpty);
    });

    test('offers a log even when nothing else about the site resolved', () {
      // This is the case the raw log exists for: the badge was set but no
      // location parsed, which is exactly when the dump is the only lead.
      final report = loadReport([
        {
          'golden': 'admin-data-phone480-de',
          'message': 'A RenderFlex overflowed.',
          'log': 'the only diagnostic left',
        }
      ]);

      final site = report.byGolden['admin-data-phone480-de']!.single;
      expect(site.label, isEmpty);
      expect(site.logIndex, 0);
      expect(report.logs.single, 'the only diagnostic left');
    });

    test('exposes the log index to the report JavaScript', () {
      final report = loadReport([record(log: 'dump')]);

      expect(
        report.byGolden['admin-data-phone480-de']!.single.toJson()['logIndex'],
        0,
      );
    });

    test('has no logs when the report file is absent', () {
      final report =
          loadOverflowReport(path: '${tempDir.path}/does_not_exist.json');

      expect(report.byGolden, isEmpty);
      expect(report.logs, isEmpty);
    });
  });

  group('deduplicated file format', () {
    /// Writes the object form the runner produces and loads it back.
    OverflowReport loadPacked(Map<String, dynamic> json) {
      final file = File('${tempDir.path}/overflow_warnings.json');
      file.writeAsStringSync(jsonEncode(json));
      return loadOverflowReport(path: file.path);
    }

    test('resolves a logIndex written by the runner', () {
      // The runner writes the log table itself so the file does not repeat a
      // 2-4KB dump per record — 76% of the file was duplicated log text, ~8MB
      // at full-run scale.
      final report = loadPacked({
        'logs': ['dump A', 'dump B'],
        'records': [
          {
            'golden': 'g1',
            'message': 'A RenderFlex overflowed by 50 pixels on the right.',
            'pixels': '50',
            'side': 'right',
            'file': 'lib/a.dart',
            'line': '10',
            'logIndex': 1,
          }
        ],
      });

      final site = report.byGolden['g1']!.single;
      expect(report.logs[site.logIndex!], 'dump B');
    });

    test('keeps only the logs the records actually reference', () {
      // Appending across test suites can leave a log whose records were cleared.
      // Carrying it into the report would inflate it with an entry nothing links
      // to.
      final report = loadPacked({
        'logs': ['referenced', 'orphaned'],
        'records': [
          {'golden': 'g1', 'message': 'overflowed', 'logIndex': 0}
        ],
      });

      expect(report.logs, ['referenced']);
      expect(report.byGolden['g1']!.single.logIndex, 0);
    });

    test('ignores a logIndex pointing outside the table', () {
      // A truncated or hand-edited file must degrade to "no log", not throw.
      final report = loadPacked({
        'logs': ['only one'],
        'records': [
          {'golden': 'g1', 'message': 'overflowed', 'logIndex': 7}
        ],
      });

      expect(report.byGolden['g1']!.single.logIndex, isNull);
    });

    test('resolves a logIndex that decoded as a double', () {
      // A hand-edited or re-serialized file can carry 1.0 where the runner wrote
      // 1; an `is int` test would silently drop the dump.
      final report = loadPacked({
        'logs': ['dump A', 'dump B'],
        'records': [
          {'golden': 'g1', 'message': 'overflowed', 'logIndex': 1.0}
        ],
      });

      final site = report.byGolden['g1']!.single;
      expect(report.logs[site.logIndex!], 'dump B');
    });

    test('survives a field whose type is not what the runner writes', () {
      // The loader promises the report generators an empty report over a throw.
      // The casts have to sit inside that guarantee, not outside it.
      final report = loadPacked({
        'logs': ['dump A'],
        'records': [
          {'golden': 'g1', 'message': 'overflowed', 'line': 42}
        ],
      });

      expect(report.byGolden, isEmpty);
      expect(report.logs, isEmpty);
    });

    test('keeps two records apart when neither resolved anything', () {
      // Joining the key fields renders a null as "null", so a record whose file
      // is literally the string "null" must not collapse into an unresolved one.
      final report = loadPacked({
        'records': [
          {'golden': 'g1', 'message': 'overflowed'},
          {
            'golden': 'g1',
            'message': 'overflowed',
            'file': 'null',
            'line': 'null',
            'widget': 'null',
            'pixels': 'null',
            'side': 'null',
          },
        ],
      });

      expect(report.byGolden['g1'], hasLength(2));
    });

    test('still reads the flat list an older run wrote', () {
      // Reports are generated from whatever file is on disk, including one left
      // by a run that predates the log table.
      final report = loadReport([record(log: 'inline dump')]);

      expect(report.logs, ['inline dump']);
      expect(report.byGolden['admin-data-phone480-de']!.single.logIndex, 0);
    });

    test('returns nothing for an object carrying no records', () {
      expect(
          loadPacked({
            'logs': ['orphaned']
          }).byGolden,
          isEmpty);
    });
  });
}
