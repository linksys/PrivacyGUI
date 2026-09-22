import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Presentation Layer Model for time settings.
class TimeSettingsUIModel extends Equatable with DiagnosticLoggable {
  final bool enable;
  final String status;
  final String currentLocalTime;
  final String localTimeZone;
  final String ntpServer1;
  final String ntpServer2;

  const TimeSettingsUIModel({
    required this.enable,
    required this.status,
    required this.currentLocalTime,
    required this.localTimeZone,
    required this.ntpServer1,
    required this.ntpServer2,
  });

  bool get isSynchronized => status == 'Synchronized';

  DateTime? get parsedLocalTime {
    if (currentLocalTime.isEmpty) return null;
    final match = RegExp(
      r'(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})'
      r'(?:Z|([+-])(\d{2}):(\d{2}))?',
    ).firstMatch(currentLocalTime);
    if (match == null) return null;

    var dt = DateTime(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
      int.parse(match[4]!),
      int.parse(match[5]!),
      int.parse(match[6]!),
    );

    // The captured offset is deliberately not applied (#1609). `dt` already
    // holds the device's wall clock, which is the only thing either consumer
    // wants: `formatDateTime` prints the fields, and `LocalTimeTicker` advances
    // them. The offset groups stay in the pattern so both `Z` and `+HH:MM`
    // forms keep parsing.
    //
    // What used to happen here was a round trip — subtract the reported offset
    // to reach UTC, then add back `matchTimezone(localTimeZone)!
    // .utcOffsetMinutes` — put in to repair a `CurrentLocalTime` whose offset
    // lagged behind a freshly written `LocalTimeZone`. It cost more than it
    // bought, in two directions. `utcOffsetMinutes` is standard time only, so
    // every DST-observing zone read an hour early for the whole of its DST
    // period; and an unmatched zone added nothing back at all, leaving the
    // clock on UTC — a full offset out, which on FLWRT 2.0 is 81 of the 89
    // zones the device itself offers.
    //
    // The premise is gone as well: the firmware evaluates the POSIX DST rule
    // itself, so the offset it reports is already the one in force (bench
    // M60TB-EU: `PST8PDT,M3.2.0/02:00,M11.1.0/02:00` reads back `-07:00` in
    // September, the instant it is set). And `timeDataProvider` fetches all six
    // `Device.Time.*` paths in one `Get` under a single `BridgeRequestThrottler`
    // cacheKey, so the offset and the zone are always the same snapshot — the
    // divergence cannot enter here to begin with.
    return dt;
  }

  String get formattedDateTime {
    final dt = parsedLocalTime;
    if (dt == null) {
      return currentLocalTime.isEmpty ? 'N/A' : currentLocalTime;
    }
    return formatDateTime(dt);
  }

  static String formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  String get diagnosticName => 'TimeSettingsUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'enable': enable,
        'status': status,
        'currentLocalTime': currentLocalTime,
        'localTimeZone': localTimeZone,
        'ntpServer1': ntpServer1,
        'ntpServer2': ntpServer2,
      };
}
