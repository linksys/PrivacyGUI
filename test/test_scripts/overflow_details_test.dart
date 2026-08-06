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
  Map<String, List<OverflowDetail>> load(List<Map<String, String>> records) {
    final file = File('${tempDir.path}/overflow_warnings.json');
    file.writeAsStringSync(jsonEncode(records));
    return loadOverflowDetails(path: file.path);
  }

  Map<String, String> record({
    String golden = 'admin-data-phone480-de',
    String pixels = '74',
    String side = 'right',
    String widget = 'Row',
    String file = 'lib/page/firmware_update/views/firmware_update_card.dart',
    String line = '77',
  }) =>
      {
        'golden': golden,
        'message': 'A RenderFlex overflowed by $pixels pixels on the $side.',
        'pixels': pixels,
        'side': side,
        'widget': widget,
        'file': file,
        'line': line,
      };

  group('loadOverflowDetails', () {
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
        loadOverflowDetails(path: '${tempDir.path}/does_not_exist.json'),
        isEmpty,
      );
    });

    test('returns no details when the report file is malformed', () {
      // A truncated write must not take the whole report generator down.
      final file = File('${tempDir.path}/overflow_warnings.json');
      file.writeAsStringSync('[{"golden": "x",');

      expect(loadOverflowDetails(path: file.path), isEmpty);
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
}
