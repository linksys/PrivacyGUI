// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';

import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart';

class PnpState extends Equatable {
  final NodeDeviceInfo? deviceInfo;
  final String? attachedPassword;
  final Map<int, PnpStepState> stepStateList;
  final bool isUnconfigured;
  final Map<JNAPAction, JNAPResult> data;
  final List<RawDevice> childNodes;
  final bool forceLogin;

  const PnpState({
    required this.deviceInfo,
    this.attachedPassword,
    this.stepStateList = const {},
    this.isUnconfigured = false,
    this.data = const {},
    this.childNodes = const [],
    this.forceLogin = false,
  });

  PnpState copyWith({
    NodeDeviceInfo? deviceInfo,
    String? attachedPassword,
    Map<int, PnpStepState>? stepStateList,
    bool? isUnconfigured,
    Map<JNAPAction, JNAPResult>? data,
    List<RawDevice>? childNodes,
    bool? forceLogin,
  }) {
    return PnpState(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      attachedPassword: attachedPassword ?? this.attachedPassword,
      stepStateList: stepStateList ?? this.stepStateList,
      isUnconfigured: isUnconfigured ?? this.isUnconfigured,
      data: data ?? this.data,
      childNodes: childNodes ?? this.childNodes,
      forceLogin: forceLogin ?? this.forceLogin,
    );
  }

  @override
  List<Object?> get props => [
        deviceInfo,
        attachedPassword,
        stepStateList,
        isUnconfigured,
        data,
        childNodes,
        forceLogin,
      ];
}
