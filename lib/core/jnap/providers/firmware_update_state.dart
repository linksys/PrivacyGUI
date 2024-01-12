// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:linksys_app/core/jnap/models/firmware_update_settings.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status_nodes.dart';

class FirmwareUpdateState extends Equatable {
  final FirmwareUpdateSettings settings;
  final FirmwareUpdateStatus? status;
  final List<NodesFirmwareUpdateStatus>? nodesStatus;

  const FirmwareUpdateState({
    required this.settings,
    required this.status,
    required this.nodesStatus,
  });

  factory FirmwareUpdateState.empty() => FirmwareUpdateState(
      settings: FirmwareUpdateSettings(
          updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
          autoUpdateWindow: FirmwareAutoUpdateWindow.simple()),
      status: const FirmwareUpdateStatus(lastSuccessfulCheckTime: '0'),
      nodesStatus: const []);

  FirmwareUpdateState copyWith({
    FirmwareUpdateSettings? settings,
    FirmwareUpdateStatus? status,
    List<NodesFirmwareUpdateStatus>? nodeStatus,
  }) {
    return FirmwareUpdateState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
      nodesStatus: nodeStatus ?? this.nodesStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap(),
      'status': status?.toMap(),
      'nodeStatus': nodesStatus?.map((x) => x.toMap()).toList(),
    };
  }

  factory FirmwareUpdateState.fromMap(Map<String, dynamic> map) {
    return FirmwareUpdateState(
      settings: FirmwareUpdateSettings.fromMap(
          map['settings'] as Map<String, dynamic>),
      status: map['status'] != null
          ? FirmwareUpdateStatus.fromMap(map['status'] as Map<String, dynamic>)
          : null,
      nodesStatus: map['nodeStatus'] != null
          ? List<NodesFirmwareUpdateStatus>.from(
              (map['nodeStatus'] as List<int>).map<NodesFirmwareUpdateStatus?>(
                (x) => NodesFirmwareUpdateStatus.fromMap(
                    x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory FirmwareUpdateState.fromJson(String source) =>
      FirmwareUpdateState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [settings, status, nodesStatus];
}
