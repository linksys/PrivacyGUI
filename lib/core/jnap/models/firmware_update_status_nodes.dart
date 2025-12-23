// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';

class NodesFirmwareUpdateStatus extends FirmwareUpdateStatus {
  final String deviceUUID;

  const NodesFirmwareUpdateStatus({
    required this.deviceUUID,
    required super.lastSuccessfulCheckTime,
    super.availableUpdate,
    super.pendingOperation,
    super.lastOperationFailure,
  });

  @override
  NodesFirmwareUpdateStatus copyWith({
    String? deviceUUID,
    String? lastSuccessfulCheckTime,
    ValueGetter<FirmwareUpdateData?>? availableUpdate,
    ValueGetter<FirmwareUpdateOperationStatus?>? pendingOperation,
    ValueGetter<String?>? lastOperationFailure,
  }) {
    return NodesFirmwareUpdateStatus(
      deviceUUID: deviceUUID ?? this.deviceUUID,
      lastSuccessfulCheckTime:
          lastSuccessfulCheckTime ?? super.lastSuccessfulCheckTime,
      availableUpdate:
          availableUpdate != null ? availableUpdate() : super.availableUpdate,
      pendingOperation: pendingOperation != null
          ? pendingOperation()
          : super.pendingOperation,
      lastOperationFailure: lastOperationFailure != null
          ? lastOperationFailure()
          : super.lastOperationFailure,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll({
        'deviceUUID': deviceUUID,
      });
  }

  factory NodesFirmwareUpdateStatus.fromMap(Map<String, dynamic> map) {
    return NodesFirmwareUpdateStatus(
      deviceUUID: map['deviceUUID'] as String,
      lastSuccessfulCheckTime: map['lastSuccessfulCheckTime'] as String,
      availableUpdate: map['availableUpdate'] != null
          ? FirmwareUpdateData.fromMap(
              map['availableUpdate'] as Map<String, dynamic>)
          : null,
      pendingOperation: map['pendingOperation'] != null
          ? FirmwareUpdateOperationStatus.fromMap(
              map['pendingOperation'] as Map<String, dynamic>)
          : null,
      lastOperationFailure: map['lastOperationFailure'] != null
          ? map['lastOperationFailure'] as String
          : null,
    );
  }

  factory NodesFirmwareUpdateStatus.fromJson(String source) =>
      NodesFirmwareUpdateStatus.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props {
    return [
      deviceUUID,
      ...super.props,
    ];
  }
}
