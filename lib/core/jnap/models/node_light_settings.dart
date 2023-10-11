// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class NodeLightSettings extends Equatable {
  final bool isNightModeEnable;
  final int? startHour;
  final int? endHour;
  final bool? allDayOff;
  const NodeLightSettings({
    required this.isNightModeEnable,
    this.startHour,
    this.endHour,
    this.allDayOff,
  });

  @override
  List<Object?> get props => [isNightModeEnable, startHour, endHour, allDayOff];

  NodeLightSettings copyWith({
    bool? isNightModeEnable,
    int? startHour,
    int? endHour,
    bool? allDayOff,
  }) {
    return NodeLightSettings(
      isNightModeEnable: isNightModeEnable ?? this.isNightModeEnable,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      allDayOff: allDayOff ?? this.allDayOff,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Enable': isNightModeEnable,
      'StartingTime': startHour,
      'EndingTime': endHour,
      'AllDayOff': allDayOff,
    };
  }

  factory NodeLightSettings.fromMap(Map<String, dynamic> map) {
    return NodeLightSettings(
      isNightModeEnable: map['Enable'] as bool,
      startHour: map['StartingTime'] != null ? map['StartingTime'] as int : null,
      endHour: map['EndingTime'] != null ? map['EndingTime'] as int : null,
      allDayOff: map['AllDayOff'] != null ? map['AllDayOff'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory NodeLightSettings.fromJson(String source) => NodeLightSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
