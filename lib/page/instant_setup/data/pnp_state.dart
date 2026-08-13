// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';

import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart';

class PnpState extends Equatable {
  final NodeDeviceInfo? deviceInfo;
  final String? attachedPassword;
  final Map<int, PnpStepState> stepStateList;
  final bool? isUnconfigured;
  final Map<JNAPAction, JNAPResult> data;
  final List<RawDevice> childNodes;
  final bool forceLogin;
  final bool isPrePaired;
  final AutoMasterStatus? autoMasterStatusOnEntry;

  /// Whether Auto Master has been seen rotating the admin password since the
  /// last time the router accepted a credential from us.
  ///
  /// Set when a status read returns `running` — the one reading that *dates* the
  /// rotation, because firmware reports it only while make-Master is actually
  /// working. Cleared when `CheckAdminPassword` succeeds, since the router has
  /// then just vouched for the credential we hold.
  ///
  /// This exists because `complete` is sticky: firmware leaves the status at
  /// `complete` for good once make-Master has run, so "the status is complete"
  /// says nothing about *when* it happened. Read on its own it means "this
  /// router was auto-mastered at some point", which is true forever and of no
  /// use to anyone. Paired with this flag it becomes the question that matters:
  /// is the credential we are about to send older than the rotation?
  final bool autoMasterRotatedSinceLogin;

  const PnpState({
    required this.deviceInfo,
    this.attachedPassword,
    this.stepStateList = const {},
    this.isUnconfigured,
    this.data = const {},
    this.childNodes = const [],
    this.forceLogin = false,
    this.isPrePaired = false,
    this.autoMasterStatusOnEntry,
    this.autoMasterRotatedSinceLogin = false,
  });

  PnpState copyWith({
    NodeDeviceInfo? deviceInfo,
    // A ValueGetter, not a plain String?, so `null` can be *assigned* rather
    // than read as "leave it alone". Clearing this is load-bearing: it holds the
    // credential PnP arrived with, and the no-internet troubleshooter re-sends
    // it unprompted — so a credential Auto Master has invalidated has to be
    // droppable, or that resend spends one of the router's 5 CGI auth attempts
    // on a password that cannot work.
    ValueGetter<String?>? attachedPassword,
    Map<int, PnpStepState>? stepStateList,
    bool? isUnconfigured,
    Map<JNAPAction, JNAPResult>? data,
    List<RawDevice>? childNodes,
    bool? forceLogin,
    bool? isPrePaired,
    ValueGetter<AutoMasterStatus?>? autoMasterStatusOnEntry,
    bool? autoMasterRotatedSinceLogin,
  }) {
    return PnpState(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      attachedPassword:
          attachedPassword != null ? attachedPassword() : this.attachedPassword,
      stepStateList: stepStateList ?? this.stepStateList,
      isUnconfigured: isUnconfigured ?? this.isUnconfigured,
      data: data ?? this.data,
      childNodes: childNodes ?? this.childNodes,
      forceLogin: forceLogin ?? this.forceLogin,
      isPrePaired: isPrePaired ?? this.isPrePaired,
      autoMasterStatusOnEntry: autoMasterStatusOnEntry != null
          ? autoMasterStatusOnEntry()
          : this.autoMasterStatusOnEntry,
      autoMasterRotatedSinceLogin:
          autoMasterRotatedSinceLogin ?? this.autoMasterRotatedSinceLogin,
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
        isPrePaired,
        autoMasterStatusOnEntry,
        autoMasterRotatedSinceLogin,
      ];

  bool get isRouterUnConfigured => isUnconfigured ?? false;
}
