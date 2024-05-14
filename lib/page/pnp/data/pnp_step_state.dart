// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/pnp/model/pnp_step.dart';

class PnpStepState extends Equatable {
  final StepViewStatus status;
  final Map<String, dynamic> data;
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
}
