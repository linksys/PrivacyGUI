
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/dual/models/log_level.dart';
import 'package:privacy_gui/page/dual/models/log_type.dart';

class DualWANLogFilterConfigState extends Equatable {
  final List<DualWANLogLevel> logLevels;
  final List<DualWANLogType> logTypes;
  
  const DualWANLogFilterConfigState({
    required this.logLevels,
    required this.logTypes,
  });

  DualWANLogFilterConfigState copyWith({
    List<DualWANLogLevel>? logLevels,
    List<DualWANLogType>? logTypes,
  }) {
    return DualWANLogFilterConfigState(
      logLevels: logLevels ?? this.logLevels,
      logTypes: logTypes ?? this.logTypes,
    );
  }

  factory DualWANLogFilterConfigState.fromMap(Map<String, dynamic> map) {
    return DualWANLogFilterConfigState(
      logLevels: List<DualWANLogLevel>.from(map['logLevels'].map((x) => DualWANLogLevel.values.firstWhere((e) => e.name == x))),
      logTypes: List<DualWANLogType>.from(map['logTypes'].map((x) => DualWANLogType.values.firstWhere((e) => e.name == x))),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'logLevels': logLevels.map((x) => x.name).toList(),
      'logTypes': logTypes.map((x) => x.name).toList(),
    };
  }

  String toJson() => json.encode(toMap());

  factory DualWANLogFilterConfigState.fromJson(String source) => DualWANLogFilterConfigState.fromMap(json.decode(source));

  @override
  List<Object?> get props => [logLevels, logTypes];
}
