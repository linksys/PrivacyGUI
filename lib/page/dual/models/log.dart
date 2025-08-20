import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/dual/models/log_level.dart';
import 'package:privacy_gui/page/dual/models/log_type.dart';

class DualWANLog extends Equatable {
  final DualWANLogLevel level;
  final String message;
  final String source;
  final int timestamp;
  final DualWANLogType type;

  const DualWANLog({
    required this.level,
    required this.message,
    required this.source,
    required this.timestamp,
    required this.type,
  });

  DualWANLog copyWith({
    DualWANLogLevel? level,
    String? message,
    String? source,
    int? timestamp,
    DualWANLogType? type,
  }) {
    return DualWANLog(
      level: level ?? this.level,
      message: message ?? this.message,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  factory DualWANLog.fromMap(Map<String, dynamic> map) {
    return DualWANLog(
      level: DualWANLogLevel.fromValue(map['level']),
      message: map['message'],
      source: map['source'],
      timestamp: map['timestamp'],
      type: DualWANLogType.fromValue(map['type']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level.toValue(),
      'message': message,
      'source': source,
      'timestamp': timestamp,
      'type': type.toValue(),
    };
  }

  factory DualWANLog.fromJson(String source) =>
      DualWANLog.fromMap(json.decode(source));

  String toJson() => toMap().toString();

  @override
  String toString() {
    // Log style [timestamp] [level] [source] [type] message
    return '[${DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String()}] [${level.name}] [$source] [${type.name}] $message';
  }

  @override
  List<Object?> get props => [level, message, source, timestamp, type];
}
