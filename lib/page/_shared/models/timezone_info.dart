/// Formats a UTC offset in minutes as `GMT±HH:MM`.
///
/// Top-level rather than a member of [TimeZoneInfo] because the cards need it
/// for an offset that has no [TimeZoneInfo] at all — the one the device reported
/// alongside its clock, which is all we can say about a zone our table does not
/// carry (#1609). Not localized on purpose: the output is a numeric offset and a
/// unit abbreviation used verbatim in every locale we ship, the same reasoning
/// that keeps `offsetDisplayText` out of the ARB files.
String formatGmtOffset(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final abs = minutes.abs();
  final hh = (abs ~/ 60).toString().padLeft(2, '0');
  final mm = (abs % 60).toString().padLeft(2, '0');
  return 'GMT$sign$hh:$mm';
}

/// A zone choice as `SetTimeSettings` saves it (linksys/FWDEV#198): a catalogue
/// row's `TimeZoneID`, sent verbatim, and the daylight-savings setting that goes
/// with it.
///
/// One value rather than two parameters because the firmware saves them
/// together — neither is ever sent without the other.
typedef TimeZoneSelection = ({String id, bool autoAdjustForDst});

/// Time zone information model for timezone selection.
class TimeZoneInfo {
  final String timeZoneID;
  final int utcOffsetMinutes;
  final bool observesDST;
  final String description;

  /// Legacy POSIX forms, kept for *reading* only (#1609), and set only on the
  /// built-in [kTimeZoneDefinitions] entries.
  ///
  /// These are what releases up to 2.7.1 wrote, so routers in the field still
  /// hold them and [matchTimezone] must go on recognising them. Nothing writes a
  /// POSIX string any more: a zone is saved by [timeZoneID] through
  /// `SetTimeSettings` (linksys/FWDEV#198). A device catalogue row has none —
  /// the fallback resolution matches against the built-in table, and
  /// `resolveCurrentTimezone` then hands back the catalogue row with the same
  /// [timeZoneID].
  final String? posixNoDST;
  final String? posixWithDST;

  /// The IANA zone 2.7.2 wrote to `Device.Time.X_LINKSYS_LocalTimeZoneName`,
  /// kept for *reading* only (#1609), and set only on the built-in entries — or
  /// null on the three of those with no faithful one.
  ///
  /// A router last saved by 2.7.2 holds the name, and the device usually cannot
  /// resolve the POSIX string it derived from it to a catalogue row — 26 of the
  /// 36 names read back an empty `X_LINKSYS_TimeZoneID` (linksys/usp_framework#72).
  /// So the fallback resolution (`resolveTimezone`) still reads a zone back by
  /// this name.
  ///
  /// The three without one are the entries whose own offset or DST flag
  /// disagrees with the tz database. See `kTimeZoneDefinitions` for which and
  /// why.
  final String? ianaName;

  const TimeZoneInfo({
    required this.timeZoneID,
    required this.utcOffsetMinutes,
    required this.observesDST,
    required this.description,
    this.posixNoDST,
    this.posixWithDST,
    this.ianaName,
  });

  /// Human-readable name without the leading "(GMT±HH:MM) " prefix.
  /// e.g. "(GMT+08:00) Singapore, Taiwan, Russia" → "Singapore, Taiwan, Russia"
  String get friendlyName {
    final match = RegExp(r'^\(GMT[^)]*\)\s*').firstMatch(description);
    if (match != null) {
      return description.substring(match.end);
    }
    return description;
  }

  /// Display format: "GMT±HH:MM"
  String get offsetDisplayText => formatGmtOffset(utcOffsetMinutes);

  @override
  String toString() => '$friendlyName ($offsetDisplayText)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeZoneInfo &&
          runtimeType == other.runtimeType &&
          timeZoneID == other.timeZoneID;

  @override
  int get hashCode => timeZoneID.hashCode;
}
