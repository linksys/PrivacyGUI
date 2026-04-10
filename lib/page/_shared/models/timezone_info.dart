/// Time zone information model for timezone selection
class TimeZoneInfo {
  final String timeZoneID;
  final int utcOffsetMinutes;
  final bool observesDST;
  final String description;

  const TimeZoneInfo({
    required this.timeZoneID,
    required this.utcOffsetMinutes,
    required this.observesDST,
    required this.description,
  });

  /// Convert UTC offset minutes to hours and minutes display format
  String get offsetDisplayText {
    final isNegative = utcOffsetMinutes < 0;
    final absMinutes = utcOffsetMinutes.abs();
    final hours = absMinutes ~/ 60;
    final minutes = absMinutes % 60;

    final sign = isNegative ? '-' : '+';
    if (minutes == 0) {
      return 'GMT$sign$hours:00';
    } else {
      return 'GMT$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
  }

  /// Convert to POSIX timezone string format for USP
  String get posixTimeZone {
    // For standard UTC offset patterns (most common case)
    if (utcOffsetMinutes % 60 == 0) {
      // Simple hourly offset
      final hours = utcOffsetMinutes ~/ 60;
      if (hours == 0) {
        return 'UTC0';
      } else if (hours > 0) {
        // Positive offset = west of UTC (Hawaii, Pacific)
        return 'UTC$hours';
      } else {
        // Negative offset = east of UTC (Asia, Europe)
        return 'UTC${hours.abs()}';
      }
    } else {
      // Fractional offset (India +5:30, Nepal +5:45, etc.)
      final isNegative = utcOffsetMinutes < 0;
      final absMinutes = utcOffsetMinutes.abs();
      final hours = absMinutes ~/ 60;
      final minutes = absMinutes % 60;

      if (isNegative) {
        return 'UTC$hours:${minutes.toString().padLeft(2, '0')}';
      } else {
        return 'UTC-$hours:${minutes.toString().padLeft(2, '0')}';
      }
    }
  }

  @override
  String toString() => '$description ($offsetDisplayText)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeZoneInfo &&
          runtimeType == other.runtimeType &&
          timeZoneID == other.timeZoneID;

  @override
  int get hashCode => timeZoneID.hashCode;
}