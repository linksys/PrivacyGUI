import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/timezone.dart';

class TimezoneState extends Equatable {
  final bool isDaylightSaving;
  final String timezoneId;
  final List<SupportedTimezone> supportedTimezones;
  final String? error;

  @override
  List<Object?> get props =>
      [isDaylightSaving, timezoneId, error];

  const TimezoneState({
    required this.isDaylightSaving,
    required this.timezoneId,
    required this.supportedTimezones,
    this.error,
  });

  factory TimezoneState.init() {
    return const TimezoneState(
      isDaylightSaving: false,
      timezoneId: 'PST8',
      supportedTimezones: [],
      error: null,
    );
  }
  TimezoneState copyWith({
    bool? isDaylightSaving,
    String? timezoneId,
    List<SupportedTimezone>? supportedTimezones,
    String? error,
  }) {
    return TimezoneState(
      isDaylightSaving: isDaylightSaving ?? this.isDaylightSaving,
      timezoneId: timezoneId ?? this.timezoneId,
      supportedTimezones: supportedTimezones ?? this.supportedTimezones,
      error: error ?? this.error,
    );
  }

}
