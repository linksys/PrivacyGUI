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

  const OverflowDetail({
    required this.message,
    required this.occurrences,
    this.widget,
    this.file,
    this.line,
    this.pixels,
    this.side,
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
      };
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
/// name.
///
/// Returns an empty map when the file is absent or malformed: a diagnostic
/// aside must never take a report generator down.
Map<String, List<OverflowDetail>> loadOverflowDetails({
  String path = 'goldens/overflow_warnings.json',
}) {
  final file = File(path);
  if (!file.existsSync()) return {};

  final List<dynamic> list;
  try {
    list = jsonDecode(file.readAsStringSync()) as List;
  } catch (_) {
    return {};
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

  return grouped.map((golden, sites) {
    final details = sites.values
        .map((site) => OverflowDetail(
              widget: site.record['widget'] as String?,
              file: site.record['file'] as String?,
              line: site.record['line'] as String?,
              pixels: site.record['pixels'] as String?,
              side: site.record['side'] as String?,
              message: site.record['message'] as String? ?? '',
              occurrences: site.count,
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
}
