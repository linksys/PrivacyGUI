import 'dart:convert';
import 'dart:io';

import '../test/layout_gate/incident.dart' show overflowSiteKey;

/// Loads and collapses the overflow records written by the golden runner, so
/// both report generators render the same detail from the same code (#1197).
///
/// Shared rather than duplicated because the collapsing rule is the part worth
/// keeping consistent: Flutter reports an overflow once per RenderObject, so a
/// card rendered per list item writes N identical records. Two generators
/// collapsing them differently would show two different counts for one run —
/// which is what happened before this file existed, where the gallery counted
/// distinct goldens and the verify report counted raw records.
///
/// ## This loader normalises; it does not trust its input (#1346)
///
/// `goldens/overflow_warnings.json` is not a reproducible file.
/// `golden_runner`'s `_writeOverflowReport` appends read-merge-append-write, once
/// per locale, so two runs of unchanged code differ in two ways: record order is
/// suite-completion order, and `logIndex` is an insertion counter, so a shift in
/// order changes what an index means.
///
/// Neither is fixed upstream, deliberately. The runner is the advisory *scout* —
/// it records and returns rather than failing, which is the right setting for it
/// and the wrong one for the gate (`doc/testing/overflow_gate_architecture.md`
/// §8). So the normalisation happens here, at read time: every `logIndex` is
/// resolved back to its dump and re-interned, sites are keyed on their source
/// location, and both the rows and the dump table are ordered by content. What
/// leaves this file is then a function of the run, not of the write order — which
/// is what lets the published report be diffed day over day.
///
/// One invariant constrains all of it: **collapsing must never empty a
/// non-empty row.** `combine_results.dart` sets each row's `hasOverflow` from
/// `sites.isNotEmpty`, and that flag alone is what golden CI's triage agent keys
/// its overflow diff on (`triage-agent/collector.py:190-191`, which does not read
/// [OverflowDetail] at all). Dropping a record whose location did not resolve
/// would publish a still-overflowing golden as fixed.

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

  /// The `file:line` this row joins to the layout gate's rows on, or null when
  /// this row cannot participate in that join (#1346).
  ///
  /// Delegated to [overflowSiteKey] rather than spelled here, so the two reports
  /// cannot drift apart on what counts as a key: the gate's `site` column
  /// (`test/util/overflow_baseline.dart`) and its `known_overflows.json` keys come
  /// out of the same function. Its three null cases — no file, no line, and a
  /// path that is not machine-independent — are documented there.
  ///
  /// A null is a row that has to be read rather than joined, not a row that does
  /// not count. Nothing downstream may filter on this: see the library comment on
  /// why an empty row is the one outcome collapsing must never produce.
  String? get site => overflowSiteKey(file, int.tryParse(line ?? ''));

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
  ///
  /// [site] is carried as a column rather than left to be recomputed from [file]
  /// and [line] downstream: recomputing it is where a second spelling of the join
  /// key would come from, and one of the consumers is JavaScript, which could not
  /// call [overflowSiteKey] even if it wanted to.
  Map<String, dynamic> toJson() => {
        'label': label,
        'widget': widget,
        'file': file,
        'line': line,
        'site': site,
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

  /// Why this report is empty for a reason other than "nothing overflowed", or
  /// null when the file was read as written.
  ///
  /// The one thing the collapsing invariant above could not cover. A parse or read
  /// failure degrades to an empty report — a diagnostic aside must never take a
  /// report generator down — and an empty report makes `combine_results.dart` write
  /// `hasOverflow: false` on **every** golden in the run. That is the invariant's
  /// own failure mode applied to all rows at once, and golden CI's triage agent
  /// keys on nothing else, so a run full of overflows publishes as all-fixed.
  ///
  /// Recorded rather than fixed, because degrading is still right: the file is
  /// written by an unlocked, unatomic read-modify-write from concurrent suites
  /// (`golden_runner.dart`'s `_writeOverflowReport`), so a truncated one is a
  /// tolerable state and a failing report generator is not. What was missing is any
  /// way to tell "no overflows" from "could not read the overflows" — an absent
  /// file is genuinely the former (the runner writes nothing when it collected
  /// nothing), a malformed one is the latter, and they used to produce identical
  /// output. Also printed to stderr where it is set.
  final String? unreadable;

  const OverflowReport({
    required this.byGolden,
    required this.logs,
    this.unreadable,
  });

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

/// One site mid-collapse: the record that represents it, that record's resolved
/// diagnostics dump, and how many records have folded into it so far.
typedef _Collapsed = ({
  Map<String, dynamic> record,
  String? dump,
  int count,
});

/// Folds [found] into the site [collapsed] already stands for.
///
/// The count is the sum. Which record *represents* the site is then decided by
/// content, because two records sharing a site key can still differ in what a
/// reader sees: [_siteKey] drops the message once a location resolved — two
/// spellings of one overflow are one site — and every record carries its own
/// dump. Keeping "whichever arrived first" made the collapsed row's message, and
/// the dump behind its button, a function of suite-completion order (#1346).
///
/// Never the count: a fold is one row in, one row out, so this cannot empty a
/// non-empty golden. That is the invariant the library comment is about.
_Collapsed _mergeSite(_Collapsed collapsed, _Collapsed found) {
  final keep = _representsBetter(collapsed, found) ? collapsed : found;
  return (
    record: keep.record,
    dump: keep.dump,
    count: collapsed.count + found.count,
  );
}

/// Whether [a] is the better of two records standing for one site.
///
/// Having a dump beats not having one — for a site nothing else resolved, it is
/// the only lead there is, and one site gets one button. Beyond that the choice
/// is arbitrary and only has to be the same choice every run, so it falls to the
/// smaller dump and then the smaller message.
bool _representsBetter(_Collapsed a, _Collapsed b) {
  if ((a.dump == null) != (b.dump == null)) return a.dump != null;
  final byDump = _compareText(a.dump, b.dump);
  if (byDump != 0) return byDump < 0;
  return _compareText(a.record['message'], b.record['message']) <= 0;
}

/// Orders two collapsed sites of one golden, so their order is a function of
/// what they are rather than of when they were written (#1346).
///
/// Total over anything [_siteKey] tells apart, and that is the requirement rather
/// than a nicety: `List.sort` leaves ties in input order, so every pair the key
/// separates but the comparator does not is a pair whose order still follows the
/// file. Each of the key's components therefore appears here — file, line,
/// amount, side, widget, and the message the key falls back to when nothing
/// resolved.
///
/// File, line then amount because that is the order a person reads a report in:
/// which file, where in it, how bad. The rest are tie-breakers and their relative
/// order carries no meaning.
int _compareSites(Map<String, dynamic> a, Map<String, dynamic> b) {
  var result = _compareText(a['file'], b['file']);
  if (result != 0) return result;
  result = _compareNumeric(a['line'], b['line']);
  if (result != 0) return result;
  result = _compareNumeric(a['pixels'], b['pixels']);
  if (result != 0) return result;
  result = _compareText(a['side'], b['side']);
  if (result != 0) return result;
  result = _compareText(a['widget'], b['widget']);
  if (result != 0) return result;
  return _compareText(a['message'], b['message']);
}

/// Compares two optional string fields, treating anything absent as empty.
///
/// Absent sorts first, which collects the rows that resolved nothing at the top
/// of their golden rather than scattering them through it — those are the rows
/// whose only lead is the raw dump, so they are the ones worth finding.
int _compareText(Object? a, Object? b) =>
    (a is String ? a : '').compareTo(b is String ? b : '');

/// Compares two numeric-looking fields by value, falling back to their text.
///
/// By value because '30' must precede '200' rather than sort as text. The
/// fallback is what keeps the order total: every parse failure collapses to 0, so
/// without it two unparseable values would tie. The runner writes only digits,
/// but a hand-edited file is exactly the input this loader promises not to
/// misread.
int _compareNumeric(Object? a, Object? b) {
  final textA = a is String ? a : '';
  final textB = b is String ? b : '';
  final byValue =
      (double.tryParse(textA) ?? 0).compareTo(double.tryParse(textB) ?? 0);
  return byValue != 0 ? byValue : textA.compareTo(textB);
}

/// Reads `goldens/overflow_warnings.json` into collapsed sites plus the table
/// of distinct raw dumps they point into.
///
/// Returns an empty report when the file is absent or malformed: a diagnostic
/// aside must never take a report generator down.
///
/// The two empties are not the same empty. An absent file means the run collected
/// no overflows — `_writeOverflowReport` returns early rather than writing `[]`. A
/// malformed one means the overflows are unknown, and that report carries
/// [OverflowReport.unreadable] so a downstream generator can say so instead of
/// publishing every golden as clean.
OverflowReport loadOverflowReport({
  String path = 'goldens/overflow_warnings.json',
}) {
  final file = File(path);
  if (!file.existsSync()) return OverflowReport.empty;

  // Guards the whole parse, not just the decode: every field read below casts a
  // value the runner wrote, so a type-mismatched one would otherwise escape as a
  // TypeError and take the report generator down — the opposite of what this
  // function promises.
  try {
    return _parseReport(jsonDecode(file.readAsStringSync()));
  } catch (error) {
    final reason = '$path exists but could not be read as an overflow report '
        '($error), so no golden in this run can be called clean on the strength '
        'of it';
    // Loud, because the silence was the defect. Whatever consumes the report may
    // or may not render `unreadable`; a line on stderr reaches whoever ran it
    // either way.
    stderr.writeln('[OVERFLOW REPORT] $reason');
    return OverflowReport(
        byGolden: const {}, logs: const [], unreadable: reason);
  }
}

/// Collapses one decoded report file into sites plus the logs they index.
OverflowReport _parseReport(Object? decoded) {
  final List<dynamic> list;
  final List<dynamic> writtenLogs;
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

  /// Resolves a record's diagnostics dump, from either file format.
  ///
  /// An index outside the table degrades to "no dump": a truncated or
  /// hand-edited file must not take the generator down. Read as [num] rather
  /// than [int] so a re-serialized file carrying `1.0` still resolves.
  ///
  /// Resolving to the text here, instead of carrying the number downstream, is
  /// the first half of the normalisation. `logIndex` counts insertions into a
  /// file that is appended to once per locale, so the number means nothing apart
  /// from the table it was written beside — and a report that passed it through
  /// would inherit that (#1346).
  String? dumpOf(Map<String, dynamic> record) {
    final index = (record['logIndex'] as num?)?.toInt();
    final log = index == null
        ? record['log']
        : (index >= 0 && index < writtenLogs.length
            ? writtenLogs[index]
            : null);
    return log is String && log.isNotEmpty ? log : null;
  }

  // golden name -> site key -> the collapsed site
  final grouped = <String, Map<String, _Collapsed>>{};

  for (final entry in list) {
    if (entry is! Map) continue;
    final record = entry.cast<String, dynamic>();
    final golden = record['golden'] as String?;
    if (golden == null || golden.isEmpty) continue;

    final sites = grouped.putIfAbsent(golden, () => {});
    final key = _siteKey(record);
    final existing = sites[key];
    final found = (record: record, dump: dumpOf(record), count: 1);
    sites[key] = existing == null ? found : _mergeSite(existing, found);
  }

  // Rebuilt rather than passed through, so the report carries only the dumps its
  // rows reference, in the order they reference them. Appending across suites can
  // leave an orphaned entry, and a flat-list file has no table at all.
  final logs = <String>[];
  final logIndexes = <String, int>{};

  /// Interns [dump] and returns its index, or null when there is nothing to show.
  int? indexOfDump(String? dump) {
    if (dump == null) return null;
    return logIndexes.putIfAbsent(dump, () {
      logs.add(dump);
      return logs.length - 1;
    });
  }

  // Goldens in name order, sites in site order, and only then the dumps interned
  // — in that sequence, because each step is what makes the next reproducible.
  // `logs` is addressed by index, so interning in arrival order would leave the
  // numbering, and every `logIndex` naming it, a function of exactly the write
  // order this file exists to normalise away (#1346).
  final byGolden = <String, List<OverflowDetail>>{};
  for (final golden in grouped.keys.toList()..sort()) {
    final sites = grouped[golden]!.values.toList()
      ..sort((a, b) => _compareSites(a.record, b.record));
    byGolden[golden] = [
      for (final site in sites)
        OverflowDetail(
          widget: site.record['widget'] as String?,
          file: site.record['file'] as String?,
          line: site.record['line'] as String?,
          pixels: site.record['pixels'] as String?,
          side: site.record['side'] as String?,
          message: site.record['message'] as String? ?? '',
          occurrences: site.count,
          logIndex: indexOfDump(site.dump),
        ),
    ];
  }

  return OverflowReport(byGolden: byGolden, logs: logs);
}
