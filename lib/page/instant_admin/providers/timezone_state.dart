import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/feature_state.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/timezone.dart';

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

  factory TimezoneSettings.fromMap(Map<String, dynamic> map) {
    return TimezoneSettings(
      isDaylightSaving: map['isDaylightSaving'] as bool,
      timezoneId: map['timezoneId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory TimezoneSettings.fromJson(String source) =>
      TimezoneSettings.fromMap(json.decode(source) as Map<String, dynamic>);
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

  TimezoneStatus copyWith({
    List<SupportedTimezone>? supportedTimezones,
    String? error,
  }) {
    return TimezoneStatus(
      supportedTimezones: supportedTimezones ?? this.supportedTimezones,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'supportedTimezones': supportedTimezones.map((x) => x.toMap()).toList(),
      'error': error,
    };
  }

  factory TimezoneStatus.fromMap(Map<String, dynamic> map) {
    return TimezoneStatus(
      supportedTimezones: List<SupportedTimezone>.from(
        map['supportedTimezones'].map<SupportedTimezone>(
          (x) => SupportedTimezone.fromMap(x as Map<String, dynamic>),
        ),
      ),
      error: map['error'] != null ? map['error'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TimezoneStatus.fromJson(String source) =>
      TimezoneStatus.fromMap(json.decode(source) as Map<String, dynamic>);
}

class TimezoneState extends FeatureState<TimezoneSettings, TimezoneStatus> {
  @override
  List<Object?> get props => [settings, status];

  const TimezoneState({
    required super.settings,
    required super.status,
  });

  factory TimezoneState.init() {
    return TimezoneState(
      settings: Preservable(
        original: const TimezoneSettings(
          isDaylightSaving: true,
          timezoneId: 'PST8',
        ),
        current: const TimezoneSettings(
          isDaylightSaving: true,
          timezoneId: 'PST8',
        ),
      ),
      status: const TimezoneStatus(
        supportedTimezones: [],
        error: null,
      ),
    );
  }

  @override
  TimezoneState copyWith({
    Preservable<TimezoneSettings>? settings,
    TimezoneStatus? status,
  }) {
    return TimezoneState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((s) => s.toMap()),
      'status': status.toMap(),
    };
  }

  factory TimezoneState.fromMap(Map<String, dynamic> map) {
    return TimezoneState(
      settings: Preservable.fromMap(
          map['settings'] as Map<String, dynamic>,
          (value) => TimezoneSettings.fromMap(value)),
      status: TimezoneStatus.fromMap(map['status'] as Map<String, dynamic>),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  factory TimezoneState.fromJson(String source) =>
      TimezoneState.fromMap(json.decode(source) as Map<String, dynamic>);
}
