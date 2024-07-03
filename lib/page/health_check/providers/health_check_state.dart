// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

class HealthCheckState extends Equatable {
  final String step;
  final String? timestamp;
  final List<HealthCheckResult> result;
  final JNAPError? error;

  const HealthCheckState({
    this.step = 'latency',
    this.timestamp,
    this.result = const [],
    this.error,
  });

  @override
  List<Object?> get props => [step, timestamp, result, error];

  factory HealthCheckState.init() {
    return const HealthCheckState(
      step: 'latency',
      result: [],
    );
  }

  HealthCheckState copyWith({
    String? step,
    String? timestamp,
    List<HealthCheckResult>? result,
    JNAPError? error,
  }) {
    return HealthCheckState(
      step: step ?? this.step,
      timestamp: timestamp ?? this.timestamp,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'step': step,
      'timestamp': timestamp,
      'result': result.map((x) => x.toJson()).toList(),
      'error': error,
    }..removeWhere((key, value) => value == null);
  }

  factory HealthCheckState.fromMap(Map<String, dynamic> map) {
    return HealthCheckState(
      step: map['step'] as String,
      timestamp: map['timestamp'] != null ? map['timestamp'] as String : null,
      result: List<HealthCheckResult>.from(
        map['result'].map<HealthCheckResult>(
          (x) => HealthCheckResult.fromJson(x as Map<String, dynamic>),
        ),
      ),
      error: map['error'] == null
          ? null
          : JNAPError(
              result: map['error']?['result'], error: map['error']?['error']),
    );
  }

  String toJson() => json.encode(toMap());

  factory HealthCheckState.fromJson(String source) =>
      HealthCheckState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
