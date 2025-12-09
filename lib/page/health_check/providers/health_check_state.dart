import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/page/health_check/models/health_check_enum.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';

/// Represents the state of the health check feature.
class HealthCheckState extends Equatable {
  // --- Transient State (for a single test run) ---

  /// The current step in the health check process (e.g., latency, download).
  final HealthCheckStep step;

  /// The overall status of the health check (e.g., idle, running, complete).
  final HealthCheckStatus status;

  /// The current value for the animated meter, typically in Kbps.
  final double meterValue;

  /// The current speed test result, which can be partial or final.
  final SpeedTestUIModel? result;

  /// If an error occurred, this holds the specific error code.
  final SpeedTestError? errorCode;

  // --- Persistent State ---

  /// The most recent completed speed test result.
  final SpeedTestUIModel? latestSpeedTest;

  /// A list of historical speed test results.
  final List<SpeedTestUIModel> historicalSpeedTests;

  /// A list of health check modules supported by the router.
  final List<String> healthCheckModules;

  const HealthCheckState({
    // Transient
    this.step = HealthCheckStep.latency,
    this.status = HealthCheckStatus.idle,
    this.meterValue = 0.0,
    this.result,
    this.errorCode,
    // Persistent
    this.latestSpeedTest,
    this.historicalSpeedTests = const [],
    this.healthCheckModules = const [],
  });

  /// A getter to easily check if the 'SpeedTest' module is supported.
  bool get isSpeedTestModuleSupported =>
      healthCheckModules.contains('SpeedTest');

  @override
  List<Object?> get props => [
        // Transient
        step,
        status,
        meterValue,
        result,
        errorCode,
        // Persistent
        latestSpeedTest,
        historicalSpeedTests,
        healthCheckModules,
      ];

  /// Creates the initial state for the health check.
  factory HealthCheckState.init() {
    return const HealthCheckState();
  }

  /// Creates a copy of the current state with updated values.
  HealthCheckState copyWith({
    HealthCheckStep? step,
    HealthCheckStatus? status,
    double? meterValue,
    ValueGetter<SpeedTestUIModel?>? result,
    ValueGetter<SpeedTestError?>? errorCode,
    ValueGetter<SpeedTestUIModel?>? latestSpeedTest,
    List<SpeedTestUIModel>? historicalSpeedTests,
    List<String>? healthCheckModules,
  }) {
    return HealthCheckState(
      step: step ?? this.step,
      status: status ?? this.status,
      meterValue: meterValue ?? this.meterValue,
      result: result != null ? result() : this.result,
      errorCode: errorCode != null ? errorCode() : this.errorCode,
      latestSpeedTest:
          latestSpeedTest != null ? latestSpeedTest() : this.latestSpeedTest,
      historicalSpeedTests: historicalSpeedTests ?? this.historicalSpeedTests,
      healthCheckModules: healthCheckModules ?? this.healthCheckModules,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'step': step.name,
      'status': status.name,
      'meterValue': meterValue,
      'result': result?.toMap(),
      'errorCode': errorCode?.name,
      'latestSpeedTest': latestSpeedTest?.toMap(),
      'historicalSpeedTests':
          historicalSpeedTests.map((x) => x.toMap()).toList(),
      'healthCheckModules': healthCheckModules,
    };
  }

  factory HealthCheckState.fromMap(Map<String, dynamic> map) {
    return HealthCheckState(
      step: HealthCheckStep.values.byName(map['step'] as String),
      status: HealthCheckStatus.values.byName(map['status'] as String),
      meterValue: map['meterValue'] as double,
      result: map['result'] != null
          ? SpeedTestUIModel.fromMap(map['result'] as Map<String, dynamic>)
          : null,
      errorCode: map['errorCode'] != null
          ? SpeedTestError.values.byName(map['errorCode'] as String)
          : null,
      latestSpeedTest: map['latestSpeedTest'] != null
          ? SpeedTestUIModel.fromMap(
              map['latestSpeedTest'] as Map<String, dynamic>)
          : null,
      historicalSpeedTests: map['historicalSpeedTests'] != null
          ? List<SpeedTestUIModel>.from(
              (map['historicalSpeedTests'] as List<dynamic>)
                  .map<SpeedTestUIModel>(
                (x) => SpeedTestUIModel.fromMap(x as Map<String, dynamic>),
              ),
            )
          : const [],
      healthCheckModules: map['healthCheckModules'] != null
          ? List<String>.from(map['healthCheckModules'] as List<dynamic>)
          : const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory HealthCheckState.fromJson(String source) =>
      HealthCheckState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  String? get moduleName {
    return isSpeedTestModuleSupported
        ? (healthCheckModules.contains('SpeedTestSamKnows')
            ? 'SamKnows'
            : 'Ookla')
        : null;
  }

  bool get isOoklaSpeedTestModule => moduleName == 'Ookla';
  bool get isSamKnowsSpeedTestModule => moduleName == 'SamKnows';
}
