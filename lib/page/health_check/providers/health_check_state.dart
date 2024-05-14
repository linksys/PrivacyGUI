import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

class HealthCheckState extends Equatable {
  final String step;
  final List<HealthCheckResult> result;
  final JNAPError? error;

  @override
  List<Object?> get props => [step, result, error];

  const HealthCheckState(
      {required this.step, required this.result, this.error});

  factory HealthCheckState.init() {
    return const HealthCheckState(step: '', result: [], error: null);
  }

  factory HealthCheckState.reset() {
    return const HealthCheckState(step: '', result: [], error: null);
  }

  HealthCheckState copyWith(
      {String? step, List<HealthCheckResult>? result, JNAPError? error}) {
    return HealthCheckState(
        step: step ?? this.step,
        result: result ?? this.result,
        error: error ?? this.error);
  }
}
