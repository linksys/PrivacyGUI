/// The report of a layout measurement run (#1802 P2), built from the
/// `tests.json` files the measuring jobs write, one per locale.
///
/// No Flutter imports, so `test_scripts/layout_measure_report.dart` runs it
/// under plain `dart`.
library;

import 'dart:convert';

import 'incident.dart';
import 'measure_record.dart';

/// One measured variant: its record, the suite it came from, and how long it
/// took.
class MeasuredVariant {
  final MeasureRecord record;

  /// The suite's path from `test/`, e.g. `test/page/x/x_view_test.dart`.
  final String suite;

  /// The variant's own test time, from its testStart to its testDone.
  final int ms;

  const MeasuredVariant(this.record, this.suite, this.ms);

  /// The sites of the overflows over the tolerance. An overflow with no site
  /// is keyed by its suite and widget, so it is still counted.
  Set<String> get sites => {for (final i in _overTolerance) _siteOf(i)};

  /// Each overflow as the case and locale it was found in, plus its site.
  /// Dropping a size loses the incidents that no other size found.
  Set<(String, String, String, String)> get _incidents => {
        for (final site in sites)
          (suite, record.caseName, record.locale, site),
      };

  Iterable<OverflowIncident> get _overTolerance =>
      record.incidents.where((i) => i.pixels > kOverflowTolerancePx);

  String _siteOf(OverflowIncident i) =>
      i.site ?? '(no location: ${i.widget ?? 'unknown widget'} in $suite)';
}

/// One row of the size table.
class SizeRow {
  /// The requested size, `905` or `1280x420`.
  final String size;
  final int variants;

  /// The variants with at least one overflow over the tolerance.
  final int overflowing;

  /// The variants whose case threw before it finished, so their incidents
  /// are only the ones found before the throw.
  final int threw;

  final Set<String> sites;

  /// The sites of the incidents no other size found, an incident being a
  /// site in one case and one locale.
  final Set<String> onlyHere;

  /// The variants' test times added up.
  final int ms;

  const SizeRow({
    required this.size,
    required this.variants,
    required this.overflowing,
    required this.threw,
    required this.sites,
    required this.onlyHere,
    required this.ms,
  });
}

/// Where one site overflowed.
class SiteRow {
  final String site;
  final Set<String> suites;
  final Set<String> sizes;
  final Set<String> locales;

  /// The largest overflow at this site; infinite when one was unreadable.
  final double worstPixels;

  const SiteRow({
    required this.site,
    required this.suites,
    required this.sizes,
    required this.locales,
    required this.worstPixels,
  });
}

/// One row of the page table: one suite.
class PageRow {
  final String suite;
  final int variants;
  final int overflowing;
  final Set<String> sites;

  /// The locales in which the page overflowed.
  final Set<String> locales;

  const PageRow({
    required this.suite,
    required this.variants,
    required this.overflowing,
    required this.sites,
    required this.locales,
  });
}

/// One row of the locale table.
class LocaleRow {
  final String locale;
  final int variants;
  final int overflowing;

  /// The variants' test times added up.
  final int ms;

  /// The wall time of the run that measured this locale, compiling and
  /// loading included, or null when no run measured it alone.
  final int? wallMs;

  const LocaleRow({
    required this.locale,
    required this.variants,
    required this.overflowing,
    required this.ms,
    required this.wallMs,
  });
}

/// A test that failed for a reason other than an overflow, which the
/// measuring tests collect instead of failing on.
class FailedTest {
  final String suite;
  final String test;

  /// The first line of the first error it reported.
  final String error;

  const FailedTest(this.suite, this.test, this.error);
}

class MeasureReport {
  final List<MeasuredVariant> variants;
  final List<FailedTest> failures;
  final Map<String, int> _wallMsByLocale;

  MeasureReport._(this.variants, this.failures, this._wallMsByLocale);

  /// Reads [runs], each the events of one `tests.json`. Test and suite ids
  /// are only unique within one run.
  factory MeasureReport.fromRuns(
    Iterable<Iterable<Map<String, Object?>>> runs,
  ) {
    final variants = <MeasuredVariant>[];
    final failures = <FailedTest>[];
    final wallMsByLocale = <String, int>{};
    for (final events in runs) {
      final suites = <Object?, String>{};
      final suiteOfTest = <Object?, Object?>{};
      final names = <Object?, String>{};
      final starts = <Object?, int>{};
      final errors = <Object?, String>{};
      final thrown = <Object?, String>{};
      final records = <Object?, MeasureRecord>{};
      final runLocales = <String>{};
      int? runMs;
      String suiteOf(Object? testId) => suites[suiteOfTest[testId]] ?? '?';

      for (final event in events) {
        final testId = event['testID'];
        switch (event['type']) {
          case 'suite':
            final suite = event['suite'] as Map;
            suites[suite['id']] = _fromTest(suite['path'] as String);
          case 'testStart':
            final test = event['test'] as Map;
            suiteOfTest[test['id']] = test['suiteID'];
            names[test['id']] = test['name'] as String;
            starts[test['id']] = (event['time'] as num?)?.toInt() ?? 0;
          case 'error':
            errors.putIfAbsent(
                testId, () => (event['error'] as String).split('\n').first);
          case 'print':
            final message = event['message'] as String;
            if (_frameworkException(message) case final summary?) {
              thrown.putIfAbsent(testId, () => summary);
            }
            if (message.startsWith(measureRecordPrefix)) {
              records[testId] = MeasureRecord.fromJson(jsonDecode(
                      message.substring(measureRecordPrefix.length))
                  as Map<String, Object?>);
            }
          case 'testDone':
            final record = records[testId];
            if (record != null) {
              final end = (event['time'] as num?)?.toInt() ?? 0;
              variants.add(MeasuredVariant(
                  record, suiteOf(testId), end - (starts[testId] ?? end)));
              runLocales.add(record.locale);
            }
            if (event['result'] != 'success' && event['skipped'] != true) {
              final error = errors[testId];
              failures.add(FailedTest(
                suiteOf(testId),
                names[testId] ?? '?',
                (error == _seeLogsAbove ? thrown[testId] : null) ??
                    error ??
                    '(no error reported)',
              ));
            }
          case 'done':
            runMs = (event['time'] as num?)?.toInt();
        }
      }
      // A run's wall time belongs to a locale only when it measured that
      // locale alone, which is how the CI matrix splits them.
      if (runMs != null && runLocales.length == 1) {
        wallMsByLocale.update(runLocales.single, (ms) => ms + runMs!,
            ifAbsent: () => runMs!);
      }
    }
    return MeasureReport._(variants, failures, wallMsByLocale);
  }

  /// One row per requested size, narrowest first.
  List<SizeRow> get sizes {
    final bySize = _groupBy(variants, (v) => v.record.size);
    final incidentsBySize = {
      for (final MapEntry(key: size, value: measured) in bySize.entries)
        size: {for (final v in measured) ...v._incidents},
    };
    bool foundElsewhere((String, String, String, String) incident, String size) =>
        incidentsBySize.entries
            .any((other) => other.key != size && other.value.contains(incident));
    final rows = [
      for (final MapEntry(key: size, value: measured) in bySize.entries)
        SizeRow(
          size: size,
          variants: measured.length,
          overflowing: measured.where((v) => v.sites.isNotEmpty).length,
          threw: measured.where((v) => v.record.threw).length,
          sites: {for (final v in measured) ...v.sites},
          onlyHere: {
            for (final incident in incidentsBySize[size]!)
              if (!foundElsewhere(incident, size)) incident.$4,
          },
          ms: _sumMs(measured),
        ),
    ];
    return rows..sort((a, b) => _compareSizes(a.size, b.size));
  }

  /// One row per site that overflowed over the tolerance, worst first.
  List<SiteRow> get sites {
    final bySite = <String, List<(MeasuredVariant, OverflowIncident)>>{};
    for (final v in variants) {
      for (final i in v._overTolerance) {
        bySite.putIfAbsent(v._siteOf(i), () => []).add((v, i));
      }
    }
    final rows = [
      for (final MapEntry(key: site, value: found) in bySite.entries)
        SiteRow(
          site: site,
          suites: {for (final (v, _) in found) v.suite},
          sizes: {for (final (v, _) in found) v.record.size},
          locales: {for (final (v, _) in found) v.record.locale},
          worstPixels:
              found.map((f) => f.$2.pixels).reduce((a, b) => a > b ? a : b),
        ),
    ];
    return rows..sort((a, b) => b.worstPixels.compareTo(a.worstPixels));
  }

  /// One row per suite, alphabetically.
  List<PageRow> get pages {
    final bySuite = _groupBy(variants, (v) => v.suite);
    return [
      for (final suite in bySuite.keys.toList()..sort())
        PageRow(
          suite: suite,
          variants: bySuite[suite]!.length,
          overflowing: bySuite[suite]!.where((v) => v.sites.isNotEmpty).length,
          sites: {for (final v in bySuite[suite]!) ...v.sites},
          locales: {
            for (final v in bySuite[suite]!)
              if (v.sites.isNotEmpty) v.record.locale,
          },
        ),
    ];
  }

  /// One row per locale, alphabetically.
  List<LocaleRow> get locales {
    final byLocale = _groupBy(variants, (v) => v.record.locale);
    return [
      for (final locale in byLocale.keys.toList()..sort())
        LocaleRow(
          locale: locale,
          variants: byLocale[locale]!.length,
          overflowing:
              byLocale[locale]!.where((v) => v.sites.isNotEmpty).length,
          ms: _sumMs(byLocale[locale]!),
          wallMs: _wallMsByLocale[locale],
        ),
    ];
  }

  /// The report as Markdown, for the step summary and the issue comment.
  String toMarkdown() {
    final sizeRows = sizes;
    final siteRows = sites;
    final localeRows = locales;
    final over = 'Over ${_px(kOverflowTolerancePx)}';
    String localesOf(Set<String> found) => found.length == localeRows.length
        ? 'all ${found.length}'
        : (found.toList()..sort()).join(', ');
    String sorted(Set<String> values, [String Function(String)? format]) =>
        (values.toList()..sort(_compareSizesOrText))
            .map(format ?? (v) => v)
            .join(', ');

    final out = StringBuffer()
      ..writeln('## Layout measurement')
      ..writeln()
      ..writeln('${localeRows.length} locales · ${sizeRows.length} sizes · '
          '${variants.length} variants · '
          '${variants.where((v) => v.sites.isNotEmpty).length} '
          '${over.toLowerCase()} · ${siteRows.length} sites · '
          '${failures.length} failed for another reason')
      ..writeln()
      ..writeln('### By size')
      ..writeln()
      ..writeln('"Only this size" counts the sites of overflows that no other '
          'size found in the same case and locale. "Threw" variants stopped '
          'early, so their overflows are a lower bound. Test time adds up '
          "each variant's own time: it leaves out compiling and loading, and "
          "the first size of each suite also carries that suite's warm-up. "
          'Wall time is per locale, below.')
      ..writeln()
      ..writeln('| Size | Variants | $over | Sites | Only this size | Threw '
          '| Test time |')
      ..writeln('|---|--:|--:|--:|--:|--:|--:|');
    for (final s in sizeRows) {
      out.writeln('| ${s.size} | ${s.variants} | ${s.overflowing} | '
          '${s.sites.length} | ${s.onlyHere.length} | ${s.threw} | '
          '${_time(s.ms)} |');
    }
    out
      ..writeln()
      ..writeln('### Sites')
      ..writeln()
      ..writeln('| Site | Worst | Sizes | Locales | Suites |')
      ..writeln('|---|--:|---|---|---|');
    for (final s in siteRows) {
      final worst =
          s.worstPixels.isFinite ? '${s.worstPixels.round()} px' : 'unreadable';
      out.writeln('| `${_cell(s.site)}` | $worst | '
          '${sorted(s.sizes)} | ${localesOf(s.locales)} | '
          '${sorted(s.suites, (v) => '`$v`')} |');
    }
    out
      ..writeln()
      ..writeln('### By page')
      ..writeln()
      ..writeln('| Suite | Variants | $over | Sites | Locales that overflow |')
      ..writeln('|---|--:|--:|--:|---|');
    for (final p in pages) {
      out.writeln('| `${_cell(p.suite)}` | ${p.variants} | ${p.overflowing} | '
          '${p.sites.length} | '
          '${p.locales.isEmpty ? '–' : localesOf(p.locales)} |');
    }
    out
      ..writeln()
      ..writeln('### By locale')
      ..writeln()
      ..writeln('| Locale | Variants | $over | Test time | Wall time |')
      ..writeln('|---|--:|--:|--:|--:|');
    for (final l in localeRows) {
      out.writeln('| ${l.locale} | ${l.variants} | ${l.overflowing} | '
          '${_time(l.ms)} | ${l.wallMs == null ? '–' : _time(l.wallMs!)} |');
    }
    out
      ..writeln()
      ..writeln('### Failed for another reason')
      ..writeln();
    if (failures.isEmpty) {
      out.writeln('None.');
    } else {
      out
        ..writeln('| Suite | Test | Error |')
        ..writeln('|---|---|---|');
      for (final f in failures) {
        out.writeln('| `${_cell(f.suite)}` | ${_cell(f.test)} | '
            '${_cell(f.error)} |');
      }
    }
    return out.toString();
  }
}

Map<String, List<MeasuredVariant>> _groupBy(
  Iterable<MeasuredVariant> variants,
  String Function(MeasuredVariant) key,
) {
  final groups = <String, List<MeasuredVariant>>{};
  for (final v in variants) {
    groups.putIfAbsent(key(v), () => []).add(v);
  }
  return groups;
}

int _sumMs(Iterable<MeasuredVariant> variants) =>
    variants.fold(0, (sum, v) => sum + v.ms);

/// What `testWidgets` reports as the error when the test framework caught an
/// exception. The exception itself was printed before it.
const _seeLogsAbove = 'Test failed. See exception logs above.';

/// The first line of the explanation in a printed "EXCEPTION CAUGHT BY
/// FLUTTER TEST FRAMEWORK" block, or null when [message] is not one.
String? _frameworkException(String message) {
  if (!message.contains('EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK')) {
    return null;
  }
  final lines = message.split('\n');
  final heading = lines.indexWhere((l) => l.contains('was thrown running'));
  if (heading == -1) return null;
  return lines
      .skip(heading + 1)
      .map((l) => l.trim())
      .firstWhere((l) => l.isNotEmpty, orElse: () => '');
}

/// A pipe would end the table cell, and a line break the table row.
String _cell(String text) =>
    text.replaceAll('|', r'\|').replaceAll(RegExp(r'\s*\n\s*'), ' ');

/// `2px`, `431px`: no `.0` on a whole number.
String _px(double pixels) =>
    '${pixels == pixels.roundToDouble() ? pixels.round() : pixels}px';

String _time(int ms) {
  final seconds = ms / 1000;
  if (seconds < 60) return '${seconds.toStringAsFixed(1)} s';
  return '${seconds ~/ 60}m ${(seconds % 60).round()}s';
}

/// A requested size: `905`, or `1280x420`.
final _sizePattern = RegExp(r'^(\d+)(?:x(\d+))?$');

int _compareSizesOrText(String a, String b) =>
    _sizePattern.hasMatch(a) && _sizePattern.hasMatch(b)
        ? _compareSizes(a, b)
        : a.compareTo(b);

/// Narrowest first; at one width, a bare width before a width with a height.
int _compareSizes(String a, String b) {
  (int, int) parts(String size) {
    final match = _sizePattern.firstMatch(size)!;
    return (int.parse(match.group(1)!), int.tryParse(match.group(2) ?? '') ?? 0);
  }

  final (aw, ah) = parts(a);
  final (bw, bh) = parts(b);
  return aw != bw ? aw.compareTo(bw) : ah.compareTo(bh);
}

/// `/home/runner/work/PrivacyGUI/PrivacyGUI/test/page/x_test.dart` becomes
/// `test/page/x_test.dart`, the same on every machine.
String _fromTest(String path) {
  final start = path.indexOf('/test/');
  return start == -1 ? path : path.substring(start + 1);
}
