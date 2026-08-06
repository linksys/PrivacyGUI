import 'dart:convert';
import 'dart:io';

/// Loads and collapses the overflow records written by the golden runner, so
/// both report generators render the same detail from the same code (#1197).
///
/// Shared rather than duplicated because the collapsing rule is the part worth
/// keeping consistent: Flutter reports an overflow once per RenderObject, so a
/// card rendered per list item writes N identical records. Two generators
/// collapsing them differently would show two different counts for one run —
/// which is what happened before this file existed, where the gallery counted
/// distinct goldens and the verify report counted raw records.

/// One overflow site within a golden, with the number of times it was reported.
class OverflowDetail {
  /// The widget that overflowed, e.g. `Row`. Null when unresolved.
  final String? widget;

  /// Repo-relative source path, e.g. `lib/page/admin/views/x.dart`, or
  /// `<package>/lib/...` for a widget built inside a dependency. Null when
  /// unresolved.
  final String? file;

  /// Line within [file]. Null when unresolved.
  final String? line;

  /// Overflow amount as Flutter formatted it — may carry decimals.
  final String? pixels;

  /// Overflow direction: `right`, `bottom`, `left` or `top`.
  final String? side;

  /// Flutter's raw error message, always present.
  final String message;

  /// How many times this exact site was reported for this golden.
  final int occurrences;

  /// Index into [OverflowReport.logs] of this site's full diagnostics dump, or
  /// null for a record written before the dump was captured.
  final int? logIndex;

  const OverflowDetail({
    required this.message,
    required this.occurrences,
    this.widget,
    this.file,
    this.line,
    this.pixels,
    this.side,
    this.logIndex,
  });

  /// A one-line summary for the report badge.
  ///
  /// Uses the file's basename to stay readable in a narrow badge; [file] keeps
  /// the full path for the tooltip. Renders whatever resolved and omits the rest,
  /// so a record written by an older run — or one whose extraction partly failed
  /// — still says something rather than dropping out of the report. Empty only
  /// when nothing parsed at all, which the caller renders as the bare badge.
  String get label {
    final amount =
        pixels == null ? '' : '${pixels}px ${side ?? ''}'.trimRight();
    final count = occurrences > 1 ? ' (×$occurrences)' : '';
    if (file == null) return amount.isEmpty ? '' : '$amount$count';

    final basename = file!.split('/').last;
    final where = line == null ? basename : '$basename:$line';
    final suffix = amount.isEmpty ? '' : ' · $amount';
    return '${widget ?? 'Widget'} · $where$suffix$count';
  }

  /// Serializes the fields the report JavaScript reads.
  Map<String, dynamic> toJson() => {
        'label': label,
        'widget': widget,
        'file': file,
        'line': line,
        'pixels': pixels,
        'side': side,
        'message': message,
        'occurrences': occurrences,
        'logIndex': logIndex,
      };
}

/// Everything the reports need about one run's overflows.
///
/// The raw dumps live in [logs] and each site refers to one by index, rather
/// than every site carrying its own copy. One culprit typically appears in
/// every golden that renders it — a single card accounted for 6 goldens in a
/// real run — and a dump runs 2-4KB, so inlining it per site would multiply
/// the report size without adding information.
class OverflowReport {
  /// Collapsed overflow sites, keyed by golden name.
  final Map<String, List<OverflowDetail>> byGolden;

  /// Distinct diagnostics dumps, indexed by [OverflowDetail.logIndex].
  final List<String> logs;

  const OverflowReport({required this.byGolden, required this.logs});

  static const empty = OverflowReport(byGolden: {}, logs: []);
}

/// Identity of an overflow site, used to collapse duplicate reports.
///
/// The amount is part of the key: rows built from one widget can overflow by
/// different amounts per item, and both numbers are worth showing.
String _siteKey(Map<String, dynamic> record) => [
      record['widget'],
      record['file'],
      record['line'],
      record['pixels'],
      record['side'],
      // Falls back to the message so unresolved records with different text
      // don't collapse into one.
      record['file'] == null ? record['message'] : null,
      // Separated by an escaped NUL rather than a literal one: a literal byte
      // makes git treat this source file as binary.
    ].join('\u0000');

/// Reads `goldens/overflow_warnings.json` and groups collapsed sites by golden
/// name, keeping only the per-golden detail.
///
/// Prefer [loadOverflowReport] when the raw dumps are needed too.
Map<String, List<OverflowDetail>> loadOverflowDetails({
  String path = 'goldens/overflow_warnings.json',
}) =>
    loadOverflowReport(path: path).byGolden;

/// Reads `goldens/overflow_warnings.json` into collapsed sites plus the table
/// of distinct raw dumps they point into.
///
/// Returns [OverflowReport.empty] when the file is absent or malformed: a
/// diagnostic aside must never take a report generator down.
OverflowReport loadOverflowReport({
  String path = 'goldens/overflow_warnings.json',
}) {
  final file = File(path);
  if (!file.existsSync()) return OverflowReport.empty;

  final List<dynamic> list;
  final List<dynamic> writtenLogs;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map) {
      // Current format: the runner writes the log table itself so the file does
      // not repeat a 2-4KB dump per record.
      list = decoded['records'] as List? ?? const [];
      writtenLogs = decoded['logs'] as List? ?? const [];
    } else {
      // A run predating the log table wrote a flat list carrying the dump inline
      // under 'log'. Reports are generated from whatever is on disk, so both
      // shapes have to load.
      list = decoded as List;
      writtenLogs = const [];
    }
  } catch (_) {
    return OverflowReport.empty;
  }

  // golden name -> site key -> (first record seen, count)
  final grouped =
      <String, Map<String, ({Map<String, dynamic> record, int count})>>{};

  for (final entry in list) {
    if (entry is! Map) continue;
    final record = entry.cast<String, dynamic>();
    final golden = record['golden'] as String?;
    if (golden == null || golden.isEmpty) continue;

    final sites = grouped.putIfAbsent(golden, () => {});
    final key = _siteKey(record);
    final existing = sites[key];
    sites[key] = existing == null
        ? (record: record, count: 1)
        : (record: existing.record, count: existing.count + 1);
  }

  // Rebuilt rather than passed through, so the report carries only the logs its
  // records reference. Appending across suites can leave an orphaned entry, and
  // a flat-list file has no table at all.
  final logs = <String>[];
  final logIndexes = <String, int>{};

  /// Interns [log] and returns its index, or null when there is nothing to show.
  int? indexOfLog(Object? log) {
    if (log is! String || log.isEmpty) return null;
    return logIndexes.putIfAbsent(log, () {
      logs.add(log);
      return logs.length - 1;
    });
  }

  /// Resolves a record's log, from either file format.
  ///
  /// An index outside the table degrades to "no log": a truncated or
  /// hand-edited file must not take the generator down.
  int? logForRecord(Map<String, dynamic> record) {
    final index = record['logIndex'];
    if (index is int) {
      return index >= 0 && index < writtenLogs.length
          ? indexOfLog(writtenLogs[index])
          : null;
    }
    return indexOfLog(record['log']);
  }

  final byGolden = grouped.map((golden, sites) {
    final details = sites.values
        .map((site) => OverflowDetail(
              widget: site.record['widget'] as String?,
              file: site.record['file'] as String?,
              line: site.record['line'] as String?,
              pixels: site.record['pixels'] as String?,
              side: site.record['side'] as String?,
              message: site.record['message'] as String? ?? '',
              occurrences: site.count,
              // The first record's dump represents the collapsed site: sibling
              // rows differ only in their own geometry, and one site gets one
              // button.
              logIndex: logForRecord(site.record),
            ))
        .toList();

    // Sort so a report regenerated from the same data reads the same way. Line
    // numbers compare numerically — '30' must precede '200'.
    details.sort((a, b) {
      final byFile = (a.file ?? '').compareTo(b.file ?? '');
      if (byFile != 0) return byFile;
      final byLine = (int.tryParse(a.line ?? '') ?? 0)
          .compareTo(int.tryParse(b.line ?? '') ?? 0);
      if (byLine != 0) return byLine;
      return (double.tryParse(a.pixels ?? '') ?? 0)
          .compareTo(double.tryParse(b.pixels ?? '') ?? 0);
    });

    return MapEntry(golden, details);
  });

  return OverflowReport(byGolden: byGolden, logs: logs);
}
