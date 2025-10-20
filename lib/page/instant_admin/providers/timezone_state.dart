// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/providers/feature_state.dart';

class TimezoneSettings extends Equatable {
  final bool isDaylightSaving;
  final String timezoneId;

  const TimezoneSettings({
    required this.isDaylightSaving,
    required this.timezoneId,
  });

  @override
  List<Object?> get props => [isDaylightSaving, timezoneId];

  TimezoneSettings copyWith({
    bool? isDaylightSaving,
    String? timezoneId,
  }) {
    return TimezoneSettings(
      isDaylightSaving: isDaylightSaving ?? this.isDaylightSaving,
      timezoneId: timezoneId ?? this.timezoneId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isDaylightSaving': isDaylightSaving,
      'timezoneId': timezoneId,
    };
  }
}

class TimezoneStatus extends Equatable {
  final List<SupportedTimezone> supportedTimezones;
  final String? error;

  const TimezoneStatus({
    required this.supportedTimezones,
    this.error,
  });

  @override
  List<Object?> get props => [supportedTimezones, error];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'supportedTimezones': supportedTimezones.map((x) => x.toMap()).toList(),
      'error': error,
    };
  }
}

class TimezoneState extends FeatureState<TimezoneSettings, TimezoneStatus> {
  const TimezoneState({
    required super.settings,
    required super.status,
  });

  factory TimezoneState.init() {
    return const TimezoneState(
      settings: TimezoneSettings(
        isDaylightSaving: true,
        timezoneId: 'PST8',
      ),
      status: TimezoneStatus(
        supportedTimezones: [],
        error: null,
      ),
    );
  }

  @override
  TimezoneState copyWith({
    TimezoneSettings? settings,
    TimezoneStatus? status,
  }) {
    return TimezoneState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'settings': settings.toMap(),
      'status': status.toMap(),
    };
  }
}
