// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';

class HealthCheckState extends Equatable {
  final String step;
  final String? timestamp;
  final List<HealthCheckResult> result;
  final JNAPError? error;
  final String status;
  final double meterValue;
  final double randomValue;
  final List<HealthCheckServer> servers;
  final HealthCheckServer? selectedServer;

  const HealthCheckState({
    this.step = 'latency',
    this.timestamp,
    this.result = const [],
    this.error,
    this.status = 'IDLE',
    this.meterValue = 0.0,
    this.randomValue = 0.0,
    this.servers = const [],
    this.selectedServer,
  });

  @override
  List<Object?> get props => [
        step,
        status,
        result,
        meterValue,
        randomValue,
        error,
        servers,
        selectedServer
      ];

  factory HealthCheckState.init() => const HealthCheckState(
        step: '',
        status: 'IDLE',
        result: [],
        meterValue: 0.0,
        randomValue: 0.0,
        servers: [],
        selectedServer: null,
      );

  HealthCheckState copyWith({
    String? step,
    String? status,
    List<HealthCheckResult>? result,
    String? timestamp,
    double? meterValue,
    double? randomValue,
    JNAPError? error,
    List<HealthCheckServer>? servers,
    HealthCheckServer? selectedServer,
  }) {
    return HealthCheckState(
      step: step ?? this.step,
      status: status ?? this.status,
      result: result ?? this.result,
      timestamp: timestamp ?? this.timestamp,
      meterValue: meterValue ?? this.meterValue,
      randomValue: randomValue ?? this.randomValue,
      error: error ?? this.error,
      servers: servers ?? this.servers,
      selectedServer: selectedServer ?? this.selectedServer,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'step': step,
      'timestamp': timestamp,
      'result': result.map((x) => x.toJson()).toList(),
      'error': error,
      'status': status,
      'meterValue': meterValue,
      'randomValue': randomValue,
      'servers': servers.map((x) => x.toJson()).toList(),
      'selectedServer': selectedServer?.toJson(),
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
      status: map['status'] as String,
      meterValue: map['meterValue'] as double,
      randomValue: map['randomValue'] as double,
      servers: map['servers'] != null
          ? List<HealthCheckServer>.from(
              map['servers'].map<HealthCheckServer>(
                (x) => HealthCheckServer.fromJson(x as Map<String, dynamic>),
              ),
            )
          : const [],
      selectedServer: map['selectedServer'] != null
          ? HealthCheckServer.fromJson(
              map['selectedServer'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory HealthCheckState.fromJson(String source) =>
      HealthCheckState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
