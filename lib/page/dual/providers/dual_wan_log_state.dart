
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/dual/models/log.dart';
import 'package:privacy_gui/page/dual/models/log_level.dart';
import 'package:privacy_gui/page/dual/models/log_type.dart';

class DualWANLogState extends Equatable {
  final List<DualWANLog> logs;
  const DualWANLogState({
    required this.logs,
  });

  DualWANLogState copyWith({
    List<DualWANLog>? logs,
  }) {
    return DualWANLogState(
      logs: logs ?? this.logs,
    );
  }

  factory DualWANLogState.fromMap(Map<String, dynamic> map) {
    return DualWANLogState(
      logs: List<DualWANLog>.from(
        map['logs'].map<DualWANLog>(
          (x) => DualWANLog.fromMap(x),
        ),
      ),
    );
  }

  factory DualWANLogState.fromJson(String source) =>
      DualWANLogState.fromMap(json.decode(source));

  String toJson() => toMap().toString();

  Map<String, dynamic> toMap() {
    return {
      'logs': logs.map((x) => x.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [logs];

  getLogCountByType(DualWANLogType type) {
    return type == DualWANLogType.all ? logs.length : logs.where((e) => e.type == type).length;
  }

  getLogCountByLevel(DualWANLogLevel level) {
    return level == DualWANLogLevel.none ? logs.length : logs.where((e) => e.level == level).length;
  }
}