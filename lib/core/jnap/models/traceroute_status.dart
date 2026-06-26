// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class TracerouteStatus extends Equatable {
  final bool isRunning;
  final String tracerouteLog;
  const TracerouteStatus({
    required this.isRunning,
    required this.tracerouteLog,
  });

  TracerouteStatus copyWith({
    bool? isRunning,
    String? tracerouteLog,
  }) {
    return TracerouteStatus(
      isRunning: isRunning ?? this.isRunning,
      tracerouteLog: tracerouteLog ?? this.tracerouteLog,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isRunning': isRunning,
      'pingLog': tracerouteLog,
    };
  }

  factory TracerouteStatus.fromMap(Map<String, dynamic> map) {
    return TracerouteStatus(
      isRunning: map['isRunning'] as bool,
      tracerouteLog: map['tracerouteLog'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory TracerouteStatus.fromJson(String source) =>
      TracerouteStatus.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isRunning, tracerouteLog];
}
