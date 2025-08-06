import 'dart:convert';

import 'package:equatable/equatable.dart';

class LoggingOptions extends Equatable {
  final bool failoverEvents;
  final bool wanUptime;
  final bool speedChecks;
  final bool throughputData;

  const LoggingOptions({
    this.failoverEvents = false,
    this.wanUptime = false,
    this.speedChecks = false,
    this.throughputData = false,
  });

  LoggingOptions copyWith({
    bool? failoverEvents,
    bool? wanUptime,
    bool? speedChecks,
    bool? throughputData,
  }) {
    return LoggingOptions(
      failoverEvents: failoverEvents ?? this.failoverEvents,
      wanUptime: wanUptime ?? this.wanUptime,
      speedChecks: speedChecks ?? this.speedChecks,
      throughputData: throughputData ?? this.throughputData,
    );
  }

  factory LoggingOptions.fromMap(Map<String, dynamic> map) {
    return LoggingOptions(
      failoverEvents: map['failoverEvents'],
      wanUptime: map['wanUptime'],
      speedChecks: map['speedChecks'],
      throughputData: map['throughputData'],
    );
  }

  String toJson() => json.encode(toMap());

  factory LoggingOptions.fromJson(String source) =>
      LoggingOptions.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'failoverEvents': failoverEvents,
      'wanUptime': wanUptime,
      'speedChecks': speedChecks,
      'throughputData': throughputData,
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => [
        failoverEvents,
        wanUptime,
        speedChecks,
        throughputData,
      ];
}