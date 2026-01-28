// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_ui_model.dart';

class FirmwareUpdateState extends Equatable {
  final FirmwareUpdateSettings settings;
  final List<FirmwareUpdateUIModel>? nodesStatus;
  final bool isUpdating;
  final bool isRetryMaxReached;
  final bool isWaitingChildrenAfterUpdating;

  const FirmwareUpdateState({
    required this.settings,
    required this.nodesStatus,
    this.isUpdating = false,
    this.isRetryMaxReached = false,
    this.isWaitingChildrenAfterUpdating = false,
  });

  factory FirmwareUpdateState.empty() => FirmwareUpdateState(
        settings: FirmwareUpdateSettings(
          updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
          autoUpdateWindow: FirmwareAutoUpdateWindow.simple(),
        ),
        nodesStatus: const [],
      );

  FirmwareUpdateState copyWith({
    FirmwareUpdateSettings? settings,
    List<FirmwareUpdateUIModel>? nodesStatus,
    bool? isUpdating,
    bool? isRetryMaxReached,
    bool? isWaitingChildrenAfterUpdating,
  }) {
    return FirmwareUpdateState(
      settings: settings ?? this.settings,
      nodesStatus: nodesStatus ?? this.nodesStatus,
      isUpdating: isUpdating ?? this.isUpdating,
      isRetryMaxReached: isRetryMaxReached ?? this.isRetryMaxReached,
      isWaitingChildrenAfterUpdating:
          isWaitingChildrenAfterUpdating ?? this.isWaitingChildrenAfterUpdating,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap(),
      'nodesStatus': nodesStatus?.map((x) => x.toMap()).toList(),
      'isUpdating': isUpdating,
      'isRetryMaxReached': isRetryMaxReached,
      'isWaitingChildrenAfterUpdating': isWaitingChildrenAfterUpdating,
    };
  }

  factory FirmwareUpdateState.fromMap(Map<String, dynamic> map) {
    return FirmwareUpdateState(
      settings: FirmwareUpdateSettings.fromMap(
          map['settings'] as Map<String, dynamic>),
      nodesStatus: map['nodesStatus'] != null
          ? List<FirmwareUpdateUIModel>.from(
              map['nodesStatus'].map<FirmwareUpdateUIModel?>(
                (x) => FirmwareUpdateUIModel.fromMap(x),
              ),
            )
          : null,
      isUpdating: map['isUpdating'] as bool? ?? false,
      isRetryMaxReached: map['isRetryMaxReached'] as bool? ?? false,
      isWaitingChildrenAfterUpdating: map['isChildAllUp'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory FirmwareUpdateState.fromJson(String source) =>
      FirmwareUpdateState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      settings,
      nodesStatus,
      isUpdating,
      isRetryMaxReached,
      isWaitingChildrenAfterUpdating,
    ];
  }
}
