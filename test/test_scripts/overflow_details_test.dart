import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../test_scripts/overflow_details.dart';
import '../layout_gate/incident.dart';

/// Guards the shared loader both golden reports use to render overflow detail.
///
/// The collapsing behaviour is the reason this is shared rather than duplicated:
/// Flutter reports an overflow per RenderObject, so a list of N identical rows
/// writes N identical records. Two report generators diverging on how they
/// collapse them would show two different counts for the same run (#1197).
///
/// Since #1346 it also guards the loader's *normalisation*, which exists because
/// `goldens/overflow_warnings.json` is not a reproducible file — see the
/// `normalization` group.

/// The real `goldens/overflow_warnings.json` checked in for #1339, decoded.
///
/// Used here as the normalisation input rather than a hand-written one because
/// the property under test is about a file the runner actually produced: 16
/// records over 4 locales, sharing 6 dumps between them, with `logIndex` values
/// assigned in arrival order. Its provenance block forbids regenerating it.
Map<String, dynamic> readCapturedReport() => jsonDecode(
      File('test/fixtures/golden_overflow_warnings.json').readAsStringSync(),
    ) as Map<String, dynamic>;

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

    test('offers one log for a site that collapsed duplicate records', () {
      // Sibling rows report the same overflow N times with near-identical
      // dumps. The site is one site, so it gets one button — see the
      // `normalization` group for which of the N dumps ends up behind it.
      final report = loadReport([
        record(log: 'dump for row 1'),
        record(log: 'dump for row 2'),
      ]);

      final site = report.byGolden['admin-data-phone480-de']!.single;
      expect(site.occurrences, 2);
      expect(report.logs, hasLength(1));
      expect(site.logIndex, 0);
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

  group('normalization', () {
    // The loader's input is not a reproducible file, and this group is the
    // consequence (#1346). `golden_runner`'s `_writeOverflowReport` appends
    // read-modify-write, once per locale, so for unchanged code:
    //
    // * record order is suite-completion order, which varies between runs;
    // * `logIndex` is an insertion counter, so a shift in order changes what an
    //   index means.
    //
    // Neither is worth fixing in the runner — it is the advisory scout, and its
    // early return is deliberate. So the report layer normalises at read time
    // instead: resolve every `logIndex` back to its dump, key sites on their
    // source location, and order both the rows and the dump table by content.
    // What comes out is then a function of the run, not of the write order.
    late Map<String, dynamic> captured;

    setUpAll(() => captured = readCapturedReport());

    /// Writes the runner's object form and loads it back.
    OverflowReport loadJson(Map<String, dynamic> json) {
      final file = File('${tempDir.path}/overflow_warnings.json');
      file.writeAsStringSync(jsonEncode(json));
      return loadOverflowReport(path: file.path);
    }

    /// Everything the loader hands its two report generators, as one string.
    ///
    /// Encoded rather than compared field by field because `jsonEncode` preserves
    /// insertion order: this notices a reordered golden, a reordered site and a
    /// shifted `logIndex` — the three things that actually move — where a set or
    /// an unordered comparison would read all three as equal.
    String canonical(OverflowReport report) => jsonEncode({
          'byGolden': {
            for (final entry in report.byGolden.entries)
              entry.key: [for (final site in entry.value) site.toJson()],
          },
          'logs': report.logs,
        });

    /// Rewrites [json]'s records into [order] and reverses its dump table,
    /// repointing every `logIndex` at the dump it named before.
    ///
    /// Both halves are needed. Reordering the records alone leaves each index
    /// meaning what it meant, so a loader that simply trusted the numbers would
    /// still look correct; reversing the table is what makes index 0 a different
    /// dump. Together they are the two ways a second run of unchanged code
    /// differs from the first.
    Map<String, dynamic> permute(Map<String, dynamic> json, List<int> order) {
      final records = List<Map<String, dynamic>>.from(json['records'] as List);
      final logs = List<String>.from(json['logs'] as List);
      return {
        'records': [
          for (final index in order)
            {
              ...records[index],
              if (records[index]['logIndex'] != null)
                'logIndex':
                    logs.length - 1 - (records[index]['logIndex'] as int),
            },
        ],
        'logs': logs.reversed.toList(),
      };
    }

    test('a real report reads the same with its records reversed', () {
      final order =
          List.generate((captured['records'] as List).length, (i) => i);

      expect(canonical(loadJson(permute(captured, order.reversed.toList()))),
          canonical(loadJson(captured)));
    });

    test('...and the same under a shuffle that renumbers every logIndex', () {
      final identity =
          List.generate((captured['records'] as List).length, (i) => i);
      // Seeded so a failure is reproducible, and checked so a shuffle that
      // happened to return the input order cannot pass by asserting nothing.
      final order = identity.toList()..shuffle(Random(1346));
      expect(order, isNot(identity));

      expect(canonical(loadJson(permute(captured, order))),
          canonical(loadJson(captured)));
    });

    test('orders goldens by name rather than by first appearance', () {
      // Stated absolutely, not only as "the same both ways": a symmetric
      // comparison passes just as happily on two identically-wrong orders, and
      // this order is what the dump table below is interned in.
      final keys = loadJson(captured).byGolden.keys.toList();

      expect(keys, keys.toList()..sort());
    });

    test('interns the dump table in the order the rows reference it', () {
      // `logs` is addressed by `logIndex`, so its order is part of the report.
      // Following the sorted rows is what makes it independent of the file's.
      final report = loadJson(captured);
      final referenced = [
        for (final sites in report.byGolden.values)
          for (final site in sites) site.logIndex,
      ].whereType<int>().toList();

      expect(referenced, isNotEmpty);
      // First use of each dump ascends: a table built in row order can only hand
      // out an index it has not handed out before.
      var highest = -1;
      for (final index in referenced) {
        expect(index, lessThanOrEqualTo(highest + 1));
        highest = max(highest, index);
      }
      expect(highest, report.logs.length - 1);
    });

    test('orders two sites that differ only in side', () {
      // The comparator has to be total over surviving sites, not merely
      // agreeable: `sort` leaves ties in input order, so any pair the key tells
      // apart but the comparator does not is a row order that follows the file.
      final records = [
        record(side: 'right', pixels: '20'),
        record(side: 'bottom', pixels: '20'),
      ];

      expect(
        load(records)['admin-data-phone480-de']!.map((d) => d.side),
        ['bottom', 'right'],
      );
      expect(canonical(loadReport(records.reversed.toList())),
          canonical(loadReport(records)));
    });

    test('orders two sites that differ only in widget', () {
      final records = [
        record(widget: 'Row'),
        record(widget: 'Column'),
      ];

      expect(
        load(records)['admin-data-phone480-de']!.map((d) => d.widget),
        ['Column', 'Row'],
      );
      expect(canonical(loadReport(records.reversed.toList())),
          canonical(loadReport(records)));
    });

    test('orders two unresolved sites by the only text they have', () {
      // With no location, the message is both what keeps them apart and the only
      // thing left to order them by.
      final records = [
        {'golden': 'g', 'message': 'A RenderFlex overflowed right.'},
        {'golden': 'g', 'message': 'A RenderFlex overflowed left.'},
      ];

      expect(
        load(records)['g']!.map((d) => d.message),
        ['A RenderFlex overflowed left.', 'A RenderFlex overflowed right.'],
      );
    });

    test('picks the same one of a collapsed site\'s dumps either way round',
        () {
      // A site key drops nothing but the message once a location resolved, so N
      // records collapsing into one row still carry N dumps — and only one of
      // them gets the row's button. Choosing "whichever arrived first" made that
      // a function of suite-completion order.
      final records = [record(log: 'dump B'), record(log: 'dump A')];

      expect(loadReport(records).logs, ['dump A']);
      expect(loadReport(records.reversed.toList()).logs, ['dump A']);
    });

    test('prefers a dump over none when collapsing a site', () {
      // Not arbitrary, unlike the choice between two dumps: for a row nothing
      // else resolved the dump is the only lead there is, so a dumpless duplicate
      // must not take the button away.
      final records = [
        record(log: 'the only diagnostic left'),
        record(),
      ];

      for (final order in [records, records.reversed.toList()]) {
        final report = loadReport(order);
        expect(report.logs, ['the only diagnostic left']);
        expect(report.byGolden['admin-data-phone480-de']!.single.logIndex, 0);
      }
    });

    test('picks the same message for a site two records spell differently', () {
      // The message is not part of the key once a location resolved: one
      // overflow, two SDK spellings, one row. Which spelling the row shows still
      // has to be the same every run.
      final records = [
        {...record(), 'message': 'B — overflowed by 74 pixels on the right.'},
        {...record(), 'message': 'A — overflowed by 74 pixels on the right.'},
      ];

      for (final order in [records, records.reversed.toList()]) {
        expect(
          load(order)['admin-data-phone480-de']!.single.message,
          startsWith('A —'),
        );
      }
    });

    test('orders a line the runner could not have written', () {
      // Lines compare numerically so '30' precedes '200', which makes every
      // non-numeric line compare equal to every other. A hand-edited file is the
      // only source of one, and it must still come out in one fixed order.
      final records = [
        record(line: 'unknown'),
        record(line: 'elsewhere'),
      ];

      expect(
        load(records)['admin-data-phone480-de']!.map((d) => d.line),
        ['elsewhere', 'unknown'],
      );
    });
  });

  group('hasOverflow', () {
    // `combine_results.dart:178` sets a row's `hasOverflow` from
    // `sites.isNotEmpty`, and that flag is the *only* thing golden CI's triage
    // agent keys its overflow diff on (`triage-agent/collector.py:190-191` in
    // linksys/PrivacyGUI-golden-ci, which never reads `overflowSites` at all).
    //
    // So collapsing may merge sites within a row and must never empty one: a row
    // whose overflows all failed to resolve — the ~120 admin cases of #1197 —
    // would otherwise leave the agent's set and be published as *fixed* while
    // still overflowing (#1346).
    test('a golden whose only site is unresolved still has one', () {
      final details = load([
        {'golden': 'g', 'message': 'A RenderFlex overflowed.'},
      ]);

      expect(details['g'], hasLength(1));
      expect(details['g']!.single.file, isNull);
      expect(details['g']!.single.site, isNull,
          reason: 'the row carries no join key, which is exactly the case that '
              'must not become no row');
    });

    test('a golden mixing an unresolved site with a resolved one keeps both',
        () {
      final details = load([
        record(),
        {
          'golden': 'admin-data-phone480-de',
          'message': 'A RenderFlex overflowed.'
        },
      ]);

      expect(details['admin-data-phone480-de'], hasLength(2));
    });

    test('every golden named by a real record survives the collapse', () {
      final captured = readCapturedReport();
      final named = {
        for (final entry in captured['records'] as List)
          (entry as Map)['golden'] as String,
      };
      final file = File('${tempDir.path}/overflow_warnings.json');
      file.writeAsStringSync(jsonEncode(captured));

      final byGolden = loadOverflowReport(path: file.path).byGolden;

      expect(byGolden.keys.toSet(), named);
      expect(byGolden.values.map((sites) => sites.length),
          everyElement(greaterThan(0)));
    });
  });

  group('site', () {
    // The whole point of #1346: the gate's rows and the scout's rows name the
    // same overflow with the same string, so the two reports join with no manual
    // reconciliation. Both spellings come from `overflowSiteKey` in
    // `test/layout_gate/incident.dart`, and these tests are what would notice if
    // one side grew its own copy.
    test('spells a resolved location the way the gate spells it', () {
      final detail = load([record()])['admin-data-phone480-de']!.single;

      expect(detail.site,
          'lib/page/firmware_update/views/firmware_update_card.dart:77');
      expect(
        detail.site,
        OverflowIncident(
          pixels: 74,
          side: 'right',
          message: 'A RenderFlex overflowed by 74 pixels on the right.',
          file: detail.file,
          line: int.parse(detail.line!),
        ).site,
      );
    });

    test('withholds a key when the location did not resolve', () {
      expect(
        load([
          {'golden': 'g', 'message': 'A RenderFlex overflowed.'},
        ])['g']!
            .single
            .site,
        isNull,
      );
    });

    test('withholds a key for an absolute path, as the gate does', () {
      // A path the normaliser could not reduce carries someone's home directory
      // or a runner's workspace, so it names a different site on every machine.
      // The gate withholds it rather than committing it; a report that did not
      // would offer a join key that joins to nothing.
      final detail = load([
        record(file: '/Users/someone/checkout/lib/page/admin/views/x.dart'),
      ])['admin-data-phone480-de']!
          .single;

      expect(detail.site, isNull);
      expect(detail.file, isNotNull,
          reason: 'the path is still the only lead a person reading the row '
              'has; it is the *key* that is withheld');
    });

    test('reaches the report JSON, so the join is a column and not a lookup',
        () {
      expect(
          load([record()])['admin-data-phone480-de']!.single.toJson()['site'],
          'lib/page/firmware_update/views/firmware_update_card.dart:77');
    });

    test('collapses a real report onto its source locations', () {
      // The design claim, executable rather than asserted. Sixteen rows over
      // four locales are two places in the source — the same two that #1368's 53
      // rows were resolved to by hand on 2026-08-24, which is the measurement
      // this ticket asks to be recorded.
      final file = File('${tempDir.path}/overflow_warnings.json');
      file.writeAsStringSync(jsonEncode(readCapturedReport()));

      final rows = <String, int>{};
      for (final sites in loadOverflowReport(path: file.path).byGolden.values) {
        for (final site in sites) {
          rows[site.site!] = (rows[site.site!] ?? 0) + 1;
        }
      }

      expect(rows, {
        'lib/page/firmware_update/views/firmware_update_card.dart:77': 12,
        'lib/page/dashboard/views/usp_sliver_dashboard_view.dart:414': 4,
      });
    });
  });

  group('the script boundary', () {
    test('the shared key definition stays runnable outside flutter test', () {
      // #1346 gave `test_scripts/overflow_details.dart` an import into the test
      // tree, which is the price of one definition of the join key. That import
      // carries a constraint nothing else in this suite would notice being
      // broken: golden CI runs the report generators with `dart run`, not
      // `flutter test`, so a `package:flutter_test` import anywhere in their
      // graph stops report generation in the other repo — while every test here
      // keeps passing, because under `flutter test` that package resolves fine.
      //
      // Checked as a property of the file rather than by shelling out to `dart
      // run`, so the failure names the cause instead of an exit code.
      final source =
          File('test/layout_gate/incident.dart').readAsLinesSync().where(
                (line) =>
                    line.startsWith('import ') || line.startsWith('export '),
              );

      expect(source, isNotEmpty,
          reason: 'a file with no imports at all would mean this test is '
              'reading the wrong path and checking nothing');
      for (final line in source) {
        expect(line, contains("'dart:"),
            reason: 'incident.dart is reached by `dart run` through '
                'test_scripts/overflow_details.dart, so it may only depend on '
                'the SDK: $line');
      }
    });
  });
}
