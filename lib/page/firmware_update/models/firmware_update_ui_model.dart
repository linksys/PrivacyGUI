import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';

class FirmwareUpdateUIModel extends Equatable {
  const FirmwareUpdateUIModel({
    required this.deviceId,
    required this.deviceName,
    required this.isMaster,
    required this.lastSuccessfulCheckTime,
    this.availableUpdate,
    this.operation,
    this.progressPercent,
    this.lastOperationFailure,
    this.currentFirmwareVersion,
    this.newFirmwareVersion,
    this.modelNumber,
  });

  final String deviceId;
  final String deviceName;
  final bool isMaster;
  final String lastSuccessfulCheckTime;
  final AvailableUpdateUIModel? availableUpdate;
  final String? operation;
  final int? progressPercent;
  final String? lastOperationFailure;
  final String? currentFirmwareVersion;
  final String? newFirmwareVersion;
  final String? modelNumber;

  @override
  List<Object?> get props => [
        deviceId,
        deviceName,
        isMaster,
        lastSuccessfulCheckTime,
        availableUpdate,
        operation,
        progressPercent,
        lastOperationFailure,
        currentFirmwareVersion,
        newFirmwareVersion,
        modelNumber,
      ];

  FirmwareUpdateUIModel copyWith({
    String? deviceId,
    String? deviceName,
    bool? isMaster,
    String? lastSuccessfulCheckTime,
    AvailableUpdateUIModel? availableUpdate,
    String? operation,
    int? progressPercent,
    String? lastOperationFailure,
    String? currentFirmwareVersion,
    String? newFirmwareVersion,
    String? modelNumber,
  }) {
    return FirmwareUpdateUIModel(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      isMaster: isMaster ?? this.isMaster,
      lastSuccessfulCheckTime:
          lastSuccessfulCheckTime ?? this.lastSuccessfulCheckTime,
      availableUpdate: availableUpdate ?? this.availableUpdate,
      operation: operation ?? this.operation,
      progressPercent: progressPercent ?? this.progressPercent,
      lastOperationFailure: lastOperationFailure ?? this.lastOperationFailure,
      currentFirmwareVersion:
          currentFirmwareVersion ?? this.currentFirmwareVersion,
      newFirmwareVersion: newFirmwareVersion ?? this.newFirmwareVersion,
      modelNumber: modelNumber ?? this.modelNumber,
    );
  }

  factory FirmwareUpdateUIModel.fromFirmwareUpdateStatus(
      FirmwareUpdateStatus status, LinksysDevice? device) {
    return FirmwareUpdateUIModel(
      deviceId: device?.deviceID ?? '',
      deviceName: device?.getDeviceName() ?? '',
      isMaster: device?.isMaster ?? false,
      lastSuccessfulCheckTime: status.lastSuccessfulCheckTime,
      availableUpdate: status.availableUpdate != null
          ? AvailableUpdateUIModel(
              version: status.availableUpdate!.firmwareVersion,
              date: status.availableUpdate!.firmwareDate,
              description: status.availableUpdate!.description,
            )
          : null,
      operation: status.pendingOperation?.operation,
      progressPercent: status.pendingOperation?.progressPercent,
      lastOperationFailure: status.lastOperationFailure,
      currentFirmwareVersion: device?.unit.firmwareVersion,
      newFirmwareVersion: status.availableUpdate?.firmwareVersion,
      modelNumber: device?.modelNumber,
    );
  }

  factory FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
      NodesFirmwareUpdateStatus status, LinksysDevice? device) {
    return FirmwareUpdateUIModel(
      deviceId: status.deviceUUID,
      deviceName: device?.getDeviceName() ?? '',
      isMaster: device?.isMaster ?? false,
      lastSuccessfulCheckTime: status.lastSuccessfulCheckTime,
      availableUpdate: status.availableUpdate != null
          ? AvailableUpdateUIModel(
              version: status.availableUpdate!.firmwareVersion,
              date: status.availableUpdate!.firmwareDate,
              description: status.availableUpdate!.description,
            )
          : null,
      operation: status.pendingOperation?.operation,
      progressPercent: status.pendingOperation?.progressPercent,
      lastOperationFailure: status.lastOperationFailure,
      currentFirmwareVersion: device?.unit.firmwareVersion,
      newFirmwareVersion: status.availableUpdate?.firmwareVersion,
      modelNumber: device?.modelNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'isMaster': isMaster,
      'lastSuccessfulCheckTime': lastSuccessfulCheckTime,
      'availableUpdate': availableUpdate?.toMap(),
      'operation': operation,
      'progressPercent': progressPercent,
      'lastOperationFailure': lastOperationFailure,
      'currentFirmwareVersion': currentFirmwareVersion,
      'newFirmwareVersion': newFirmwareVersion,
      'modelNumber': modelNumber,
    };
  }

  factory FirmwareUpdateUIModel.fromMap(Map<String, dynamic> map) {
    return FirmwareUpdateUIModel(
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? '',
      isMaster: map['isMaster'] ?? false,
      lastSuccessfulCheckTime: map['lastSuccessfulCheckTime'] ?? '',
      availableUpdate: map['availableUpdate'] != null
          ? AvailableUpdateUIModel.fromMap(map['availableUpdate'])
          : null,
      operation: map['operation'],
      progressPercent: map['progressPercent'],
      lastOperationFailure: map['lastOperationFailure'],
      currentFirmwareVersion: map['currentFirmwareVersion'],
      newFirmwareVersion: map['newFirmwareVersion'],
      modelNumber: map['modelNumber'],
    );
  }
  String toJson() => json.encode(toMap());

  factory FirmwareUpdateUIModel.fromJson(String source) =>
      FirmwareUpdateUIModel.fromMap(json.decode(source));
}

class AvailableUpdateUIModel extends Equatable {
  const AvailableUpdateUIModel({
    required this.version,
    required this.date,
    this.description,
  });

  final String version;
  final String date;
  final String? description;

  @override
  List<Object?> get props => [version, date, description];

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'date': date,
      'description': description,
    };
  }

  factory AvailableUpdateUIModel.fromMap(Map<String, dynamic> map) {
    return AvailableUpdateUIModel(
      version: map['version'] ?? '',
      date: map['date'] ?? '',
      description: map['description'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AvailableUpdateUIModel.fromJson(String source) =>
      AvailableUpdateUIModel.fromMap(json.decode(source));
}
