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
  String get offsetDisplayText {
    final isNegative = utcOffsetMinutes < 0;
    final absMinutes = utcOffsetMinutes.abs();
    final hours = absMinutes ~/ 60;
    final minutes = absMinutes % 60;
    final sign = isNegative ? '-' : '+';
    return 'GMT$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

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
