// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:linksys_app/core/jnap/models/firmware_update_settings.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status_nodes.dart';

class FirmwareUpdateState extends Equatable {
  final FirmwareUpdateSettings settings;
  final List<FirmwareUpdateStatus>? nodesStatus;
  final bool isUpdating;
  final bool isChecking;

  const FirmwareUpdateState({
    required this.settings,
    required this.nodesStatus,
    this.isUpdating = false,
    this.isChecking = false,
  });

  factory FirmwareUpdateState.empty() => FirmwareUpdateState(
      settings: FirmwareUpdateSettings(
          updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
          autoUpdateWindow: FirmwareAutoUpdateWindow.simple()),
      nodesStatus: const []);

  FirmwareUpdateState copyWith({
    FirmwareUpdateSettings? settings,
    FirmwareUpdateStatus? status,
    List<FirmwareUpdateStatus>? nodesStatus,
    bool? isUpdating,
    bool? isChecking,
  }) {
    return FirmwareUpdateState(
      settings: settings ?? this.settings,
      nodesStatus: nodesStatus ?? this.nodesStatus,
      isUpdating: isUpdating ?? this.isUpdating,
      isChecking: isChecking ?? this.isChecking,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap(),
      'nodesStatus': nodesStatus?.map((x) => x.toMap()).toList(),
      'isUpdating': isUpdating,
      'isChecking': isChecking,
    };
  }

  factory FirmwareUpdateState.fromMap(Map<String, dynamic> map) {
    return FirmwareUpdateState(
      settings: FirmwareUpdateSettings.fromMap(
          map['settings'] as Map<String, dynamic>),
      nodesStatus: map['nodesStatus'] != null
          ? List<FirmwareUpdateStatus>.from(
              map['nodesStatus'].map<FirmwareUpdateStatus?>(
                (x) => x['deviceUUID'] == null
                    ? FirmwareUpdateStatus.fromMap(x)
                    : NodesFirmwareUpdateStatus.fromMap(x),
              ),
            )
          : null,
      isUpdating: map['isUpdating'] as bool,
      isChecking: map['isChecking'] as bool,
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
      isChecking,
    ];
  }
}
