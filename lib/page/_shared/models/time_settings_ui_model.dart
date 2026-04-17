import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';

/// Presentation Layer Model for time settings.
class TimeSettingsUIModel extends Equatable {
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

  /// Formatted date/time for display, converted from UTC to local time
  /// using the configured timezone offset.
  String get formattedDateTime {
    if (currentLocalTime.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(currentLocalTime);
      final utc = dt.isUtc ? dt : dt.toUtc();
      final localDt = _applyTimezoneOffset(utc);
      return '${localDt.year}-${localDt.month.toString().padLeft(2, '0')}-'
          '${localDt.day.toString().padLeft(2, '0')} '
          '${localDt.hour.toString().padLeft(2, '0')}:'
          '${localDt.minute.toString().padLeft(2, '0')}:'
          '${localDt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return currentLocalTime;
    }
  }

  DateTime _applyTimezoneOffset(DateTime utc) {
    final tz = matchTimezone(localTimeZone);
    if (tz == null) return utc;
    var offsetMinutes = tz.utcOffsetMinutes;
    if (inferDstEnabled(localTimeZone)) {
      offsetMinutes += 60;
    }
    return utc.add(Duration(minutes: offsetMinutes));
  }

  @override
  List<Object?> get props => [
        enable,
        status,
        currentLocalTime,
        localTimeZone,
        ntpServer1,
        ntpServer2,
      ];
}
