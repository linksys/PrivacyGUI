import 'dart:convert';

import 'package:equatable/equatable.dart';

class SupportedTimezone extends Equatable {
  final bool observesDST;
  final String timeZoneID;
  final String description;
  final int utcOffsetMinutes;

  @override
  List<Object?> get props => [
        observesDST,
        timeZoneID,
        description,
        utcOffsetMinutes,
      ];

  const SupportedTimezone({
    required this.observesDST,
    required this.timeZoneID,
    required this.description,
    required this.utcOffsetMinutes,
  });

  SupportedTimezone copyWith({
    bool? observesDST,
    String? timeZoneID,
    String? description,
    int? utcOffsetMinutes,
  }) {
    return SupportedTimezone(
      observesDST: observesDST ?? this.observesDST,
      timeZoneID: timeZoneID ?? this.timeZoneID,
      description: description ?? this.description,
      utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'observesDST': observesDST,
      'timeZoneID': timeZoneID,
      'description': description,
      'utcOffsetMinutes': utcOffsetMinutes,
    }..removeWhere((key, value) => value == null);
  }

  factory SupportedTimezone.fromMap(Map<String, dynamic> json) {
    return SupportedTimezone(
      observesDST: json['observesDST'],
      timeZoneID: json['timeZoneID'],
      description: json['description'],
      utcOffsetMinutes: json['utcOffsetMinutes'],
    );
  }
  String toJson() => json.encode(toMap());

  factory SupportedTimezone.fromJson(String source) =>
      SupportedTimezone.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
