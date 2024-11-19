// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';

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

  factory NodeLightSettings.fromStatus(NodeLightStatus status) =>
      switch (status) {
        NodeLightStatus.on => NodeLightSettings.on(),
        NodeLightStatus.off => NodeLightSettings.off(),
        NodeLightStatus.night => NodeLightSettings.night(),
      };
  factory NodeLightSettings.on() => NodeLightSettings(
        isNightModeEnable: false,
      );
  factory NodeLightSettings.off() =>
      NodeLightSettings(isNightModeEnable: true, startHour: 0, endHour: 24);
  factory NodeLightSettings.night() =>
      NodeLightSettings(isNightModeEnable: true, startHour: 20, endHour: 8);

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
    }..removeWhere((key, value) => value == null);
  }

  factory NodeLightSettings.fromMap(Map<String, dynamic> map) {
    return NodeLightSettings(
      isNightModeEnable: map['Enable'] as bool,
      startHour:
          map['StartingTime'] != null ? map['StartingTime'] as int : null,
      endHour: map['EndingTime'] != null ? map['EndingTime'] as int : null,
      allDayOff: map['AllDayOff'] != null ? map['AllDayOff'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory NodeLightSettings.fromJson(String source) =>
      NodeLightSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
