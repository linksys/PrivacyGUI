// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/device.dart';

import 'package:linksys_app/core/jnap/models/device_info.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/page/pnp/data/pnp_step_state.dart';

class PnpState extends Equatable {
  final NodeDeviceInfo? deviceInfo;
  final String password;
  final Map<int, PnpStepState> stepStateList;
  final bool isUnconfigured;
  final Map<JNAPAction, JNAPResult> data;
  final List<RawDevice> childNodes;

  const PnpState({
    required this.deviceInfo,
    required this.password,
    this.stepStateList = const {},
    this.isUnconfigured = false,
    this.data = const {},
    this.childNodes = const [],
  });

  PnpState copyWith({
    NodeDeviceInfo? deviceInfo,
    String? password,
    Map<int, PnpStepState>? stepStateList,
    bool? isUnconfigured,
    Map<JNAPAction, JNAPResult>? data,
    List<RawDevice>? childNodes,
  }) {
    return PnpState(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      password: password ?? this.password,
      stepStateList: stepStateList ?? this.stepStateList,
      isUnconfigured: isUnconfigured ?? this.isUnconfigured,
      data: data ?? this.data,
      childNodes: childNodes ?? this.childNodes,
    );
  }

  @override
  List<Object?> get props => [
        deviceInfo,
        password,
        stepStateList,
        isUnconfigured,
        data,
        childNodes,
      ];
}