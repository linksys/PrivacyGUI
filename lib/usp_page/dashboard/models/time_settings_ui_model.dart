import 'package:equatable/equatable.dart';

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

  /// Formatted date/time for display.
  String get formattedDateTime {
    if (currentLocalTime.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(currentLocalTime);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return currentLocalTime;
    }
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
