// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:linksys_app/core/jnap/models/device_info.dart';
import 'package:linksys_app/page/pnp/data/pnp_step_state.dart';

class PnpState extends Equatable {
  final NodeDeviceInfo? deviceInfo;
  final String password;
  final Map<int, PnpStepState> stepStateList;

  const PnpState({
    required this.deviceInfo,
    required this.password,
    this.stepStateList = const {},
  });

  PnpState copyWith(
      {NodeDeviceInfo? deviceInfo,
      String? password,
      Map<String, dynamic>? data,
      Map<int, PnpStepState>? stepStateList}) {
    return PnpState(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      password: password ?? this.password,
      stepStateList: stepStateList ?? this.stepStateList,
    );
  }

  @override
  List<Object?> get props => [
        deviceInfo,
        password,
        stepStateList,
      ];
}
