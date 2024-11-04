// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/timezone.dart';

class TimezoneState extends Equatable {
  final bool isDaylightSaving;
  final String timezoneId;
  final List<SupportedTimezone> supportedTimezones;
  final String? error;

  @override
  List<Object?> get props => [isDaylightSaving, timezoneId, error];

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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isDaylightSaving': isDaylightSaving,
      'timezoneId': timezoneId,
      'supportedTimezones': supportedTimezones.map((x) => x.toMap()).toList(),
      'error': error,
    };
  }

  factory TimezoneState.fromMap(Map<String, dynamic> map) {
    return TimezoneState(
      isDaylightSaving: map['isDaylightSaving'] as bool,
      timezoneId: map['timezoneId'] as String,
      supportedTimezones: List<SupportedTimezone>.from(
        map['supportedTimezones'].map<SupportedTimezone>(
          (x) => SupportedTimezone.fromMap(x as Map<String, dynamic>),
        ),
      ),
      error: map['error'] != null ? map['error'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TimezoneState.fromJson(String source) =>
      TimezoneState.fromMap(json.decode(source) as Map<String, dynamic>);
}
