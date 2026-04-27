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

    final hasOffset = match[7] != null;
    if (hasOffset) {
      final sign = match[7] == '+' ? 1 : -1;
      final offsetMinutes =
          sign * (int.parse(match[8]!) * 60 + int.parse(match[9]!));
      dt = dt.subtract(Duration(minutes: offsetMinutes));

      final tzInfo = matchTimezone(localTimeZone);
      if (tzInfo != null) {
        dt = dt.add(Duration(minutes: tzInfo.utcOffsetMinutes));
      }
    }

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
  List<Object?> get props => [
        enable,
        status,
        currentLocalTime,
        localTimeZone,
        ntpServer1,
        ntpServer2,
      ];
}
