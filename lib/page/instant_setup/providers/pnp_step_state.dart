import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';

/// Represents the state of a single step within the PnP wizard.
class PnpStepState extends Equatable {
  /// The current status of the step (e.g., loading, data entry, error).
  final StepViewStatus status;

  /// The data collected from the user for this specific step (e.g., SSID, password).
  final Map<String, dynamic> data;

  /// Any error object associated with this step's processing.
  final Object? error;

  const PnpStepState({
    required this.status,
    required this.data,
    this.error,
  });

  PnpStepState copyWith({
    StepViewStatus? status,
    Map<String, dynamic>? data,
    Object? error,
  }) {
    return PnpStepState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        data,
        error,
      ];

  /// Generic helper to safely retrieve data from the `data` map.
  T getData<T>(String key, [T? defaultValue]) {
    final value = data[key];
    if (value is T) {
      return value;
    }
    return defaultValue as T;
  }
}
