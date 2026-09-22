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

/// Time zone information model for timezone selection.
class TimeZoneInfo {
  final String timeZoneID;
  final int utcOffsetMinutes;
  final bool observesDST;
  final String description;
  final String posixNoDST;
  final String posixWithDST;

  const TimeZoneInfo({
    required this.timeZoneID,
    required this.utcOffsetMinutes,
    required this.observesDST,
    required this.description,
    required this.posixNoDST,
    required this.posixWithDST,
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

  /// Returns the POSIX string based on whether DST is enabled.
  String posixFor({required bool dstEnabled}) {
    if (!observesDST) return posixNoDST;
    return dstEnabled ? posixWithDST : posixNoDST;
  }

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
