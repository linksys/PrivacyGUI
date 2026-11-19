/// What one measured variant reports: a case at one locale and one size, and
/// the overflows found there (#1802 P2).
///
/// The measuring test prints it as one line, `measureRecordPrefix` plus JSON,
/// and the JSON reporter keeps that line in `tests.json` next to the test's
/// id. `measure_report.dart` reads it back. This file imports no Flutter, so
/// the report runs under plain `dart`.
library;

import 'incident.dart';

/// The start of a printed record, so a report can tell it from other output.
const String measureRecordPrefix = '[layout-measure] ';

class MeasureRecord {
  /// The `testLocalizations` name of the case.
  final String caseName;

  /// The locale, as a language tag, e.g. `zh-TW`.
  final String locale;

  /// The requested size this answers, `905` or `1280x420`. [height] is the
  /// case's own when the request gave none.
  final String size;

  final double width;
  final double height;

  /// Whether the case threw before it finished. Its incidents are then only
  /// the ones found before the throw.
  final bool threw;

  final List<OverflowIncident> incidents;

  const MeasureRecord({
    required this.caseName,
    required this.locale,
    required this.size,
    required this.width,
    required this.height,
    required this.threw,
    required this.incidents,
  });

  // JSON has no Infinity, so an unreadable amount is written as null.
  Map<String, Object?> toJson() => {
        'case': caseName,
        'locale': locale,
        'size': size,
        'width': width,
        'height': height,
        'threw': threw,
        'incidents': [
          for (final i in incidents)
            {
              'pixels': i.pixels.isFinite ? i.pixels : null,
              'side': i.side,
              'widget': i.widget,
              'site': i.site,
            },
        ],
      };

  factory MeasureRecord.fromJson(Map<String, Object?> json) => MeasureRecord(
        caseName: json['case'] as String,
        locale: json['locale'] as String,
        size: json['size'] as String,
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        threw: json['threw'] as bool,
        incidents: [
          for (final i in json['incidents'] as List)
            OverflowIncident(
              pixels: ((i as Map)['pixels'] as num?)?.toDouble() ??
                  OverflowIncident.unparseablePixels,
              side: i['side'] as String,
              widget: i['widget'] as String?,
              site: i['site'] as String?,
            ),
        ],
      );
}
