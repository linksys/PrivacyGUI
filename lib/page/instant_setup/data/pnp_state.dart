import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';

import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';

/// Represents the entire state of the PnP (Plug and Play) setup flow.
///
/// This class is immutable and holds all the data required across different steps
/// of the setup wizard, acting as the single source of truth.
class PnpState extends Equatable {
  /// Information about the router device being set up.
  final NodeDeviceInfo? deviceInfo;

  /// The admin password passed via URL or manually entered, used for initial login attempts.
  final String? attachedPassword;

  /// A map holding the state for each individual step in the wizard, keyed by [PnpStepId].
  final Map<PnpStepId, PnpStepState> stepStateList;

  /// Indicates whether the router is in an unconfigured (factory default) state.
  /// `null` means it hasn't been checked yet.
  final bool? isUnconfigured;

  /// A cache of raw JNAP responses from the router for pre-fetched data.
  final Map<JNAPAction, JNAPResult> data;

  /// A list of child nodes detected in the network.
  final List<RawDevice> childNodes;

  /// A flag to indicate if the flow should force a login, bypassing other checks.
  final bool forceLogin;

  const PnpState({
    required this.deviceInfo,
    this.attachedPassword,
    this.stepStateList = const {},
    this.isUnconfigured,
    this.data = const {},
    this.childNodes = const [],
    this.forceLogin = false,
  });

  PnpState copyWith({
    NodeDeviceInfo? deviceInfo,
    String? attachedPassword,
    Map<PnpStepId, PnpStepState>? stepStateList,
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

  /// A convenience getter that treats `null` `isUnconfigured` as `false`.
  bool get isRouterUnConfigured => isUnconfigured ?? false;
}
