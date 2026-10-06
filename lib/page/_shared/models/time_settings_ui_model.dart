import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Presentation Layer Model for time settings.
class TimeSettingsUIModel extends Equatable with DiagnosticLoggable {
  final bool enable;
  final String status;
  final String currentLocalTime;
  final String localTimeZone;

  /// `Device.Time.X_LINKSYS_LocalTimeZoneName` — the IANA zone name 2.7.2 saved
  /// (#1609), read for the fallback resolution only.
  ///
  /// [timeZoneId] is the device's identity for the zone now; this is what the
  /// zone falls back to when the device cannot name it, as it usually cannot for
  /// a zone 2.7.2 saved by name. Empty on a factory-fresh box, on any router
  /// last written by 2.7.1 or earlier, and after a `SetTimeSettings`, all of
  /// which clear it. See `resolveCurrentTimezone`.
  final String localTimeZoneName;

  /// `Device.Time.X_LINKSYS_TimeZoneID` — the device's own reading of the
  /// current zone as a catalogue row's `TimeZoneID` (linksys/FWDEV#198).
  ///
  /// Null when the firmware does not carry the leaf, and `''` when the current
  /// POSIX string matches no catalogue row — which is what a zone written by
  /// IANA name (2.7.2's #1609 save path) usually reads. Both mean "fall back to
  /// our own resolution", not "nothing selected"; see `resolveCurrentTimezone`.
  final String? timeZoneId;

  /// `Device.Time.X_LINKSYS_AutoAdjustForDST`. Only meaningful alongside a
  /// non-empty [timeZoneId]: when no catalogue row matched, the firmware reads
  /// `false` even while DST is in effect.
  final bool? autoAdjustForDst;

  final String ntpServer1;
  final String ntpServer2;

  const TimeSettingsUIModel({
    required this.enable,
    required this.status,
    required this.currentLocalTime,
    required this.localTimeZone,
    this.localTimeZoneName = '',
    this.timeZoneId,
    this.autoAdjustForDst,
    required this.ntpServer1,
    required this.ntpServer2,
  });

  bool get isSynchronized => status == 'Synchronized';

  // `Z` is captured rather than merely matched so that "the device said UTC"
  // stays distinguishable from "the device sent no offset" — see
  // [reportedOffsetMinutes].
  static final _isoPattern = RegExp(
    r'(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})'
    r'(?:(Z)|([+-])(\d{2}):(\d{2}))?',
  );

  RegExpMatch? get _isoMatch => currentLocalTime.isEmpty
      ? null
      : _isoPattern.firstMatch(currentLocalTime);

  DateTime? get parsedLocalTime {
    final match = _isoMatch;
    if (match == null) return null;

    // The captured offset is deliberately not applied (#1609). The wall clock
    // below is the only thing either consumer wants: `formatDateTime` prints
    // the fields, and `LocalTimeTicker` advances them.
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
    // September, the instant it is set). And `CurrentLocalTime` and
    // `LocalTimeZone` are read in the same codegen `Get` under one
    // `BridgeRequestThrottler` cacheKey, so those two are always the same
    // snapshot and the offset cannot lag the POSIX string.
    //
    // [localTimeZoneName] is the exception and deliberately not part of that
    // claim: it comes from a second `Get` with its own cache entry, so it can be
    // a snapshot older or newer than this clock. That is why `resolveTimezone`
    // takes [reportedOffsetMinutes] and refuses a name the offset contradicts.
    return DateTime(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
      int.parse(match[4]!),
      int.parse(match[5]!),
      int.parse(match[6]!),
    );
  }

  /// The UTC offset the device reported alongside [currentLocalTime], in
  /// minutes, or null when the string carried none.
  ///
  /// This is the one true fact still available when [localTimeZone] is a POSIX
  /// string `kTimeZoneDefinitions` does not carry — which on FLWRT 2.0 is the
  /// common case rather than the exotic one. The factory value is a bare `UTC`,
  /// and 81 of the 89 zones the device publishes in
  /// `Device.Time.X_LINKSYS_SupportedZones` have no entry of ours. The cards
  /// render `GMT±HH:MM` from this instead of printing the raw POSIX string at
  /// the user (#1609).
  ///
  /// Unlike the clock, this is a property of the *string*, so it is DST-correct
  /// for free: the firmware has already applied the rule.
  int? get reportedOffsetMinutes {
    final match = _isoMatch;
    if (match == null) return null;
    if (match[7] != null) return 0;
    if (match[8] == null) return null;
    final sign = match[8] == '+' ? 1 : -1;
    return sign * (int.parse(match[9]!) * 60 + int.parse(match[10]!));
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
        'localTimeZoneName': localTimeZoneName,
        'timeZoneId': timeZoneId,
        'autoAdjustForDst': autoAdjustForDst,
        'ntpServer1': ntpServer1,
        'ntpServer2': ntpServer2,
      };
}
