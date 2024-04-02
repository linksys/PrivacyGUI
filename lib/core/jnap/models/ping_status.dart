// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class PingStatus extends Equatable {
  final bool isRunning;
  final String pingLog;
  const PingStatus({
    required this.isRunning,
    required this.pingLog,
  });

  PingStatus copyWith({
    bool? isRunning,
    String? pingLog,
  }) {
    return PingStatus(
      isRunning: isRunning ?? this.isRunning,
      pingLog: pingLog ?? this.pingLog,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isRunning': isRunning,
      'pingLog': pingLog,
    };
  }

  factory PingStatus.fromMap(Map<String, dynamic> map) {
    return PingStatus(
      isRunning: map['isRunning'] as bool,
      pingLog: map['pingLog'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PingStatus.fromJson(String source) => PingStatus.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isRunning, pingLog];
}
