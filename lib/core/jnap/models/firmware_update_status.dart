// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class FirmwareUpdateStatus extends Equatable {
  final String lastSuccessfulCheckTime;
  final FirmwareUpdateData? availableUpdate;
  final FirmwareUpdateOperationStatus? pendingOperation;
  final String? lastOperationFailure;
  const FirmwareUpdateStatus({
    required this.lastSuccessfulCheckTime,
    this.availableUpdate,
    this.pendingOperation,
    this.lastOperationFailure,
  });

  FirmwareUpdateStatus copyWith({
    String? lastSuccessfulCheckTime,
    ValueGetter<FirmwareUpdateData?>? availableUpdate,
    ValueGetter<FirmwareUpdateOperationStatus?>? pendingOperation,
    ValueGetter<String?>? lastOperationFailure,
  }) {
    return FirmwareUpdateStatus(
      lastSuccessfulCheckTime: lastSuccessfulCheckTime ?? this.lastSuccessfulCheckTime,
      availableUpdate: availableUpdate != null ? availableUpdate() : this.availableUpdate,
      pendingOperation: pendingOperation != null ? pendingOperation() : this.pendingOperation,
      lastOperationFailure: lastOperationFailure != null ? lastOperationFailure() : this.lastOperationFailure,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lastSuccessfulCheckTime': lastSuccessfulCheckTime,
      'availableUpdate': availableUpdate?.toMap(),
      'pendingOperation': pendingOperation?.toMap(),
      'lastOperationFailure': lastOperationFailure,
    };
  }

  factory FirmwareUpdateStatus.fromMap(Map<String, dynamic> map) {
    return FirmwareUpdateStatus(
      lastSuccessfulCheckTime: map['lastSuccessfulCheckTime'] as String? ?? '',
      availableUpdate: map['availableUpdate'] != null ? FirmwareUpdateData.fromMap(map['availableUpdate'] as Map<String,dynamic>) : null,
      pendingOperation: map['pendingOperation'] != null ? FirmwareUpdateOperationStatus.fromMap(map['pendingOperation'] as Map<String,dynamic>) : null,
      lastOperationFailure: map['lastOperationFailure'] != null ? map['lastOperationFailure'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory FirmwareUpdateStatus.fromJson(String source) => FirmwareUpdateStatus.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [lastSuccessfulCheckTime, availableUpdate, pendingOperation, lastOperationFailure];
}

class FirmwareUpdateData extends Equatable {
  final String firmwareVersion;
  final String firmwareDate;
  final String? description;
  const FirmwareUpdateData({
    required this.firmwareVersion,
    required this.firmwareDate,
    this.description,
  });

  FirmwareUpdateData copyWith({
    String? firmwareVersion,
    String? firmwareDate,
    String? description,
  }) {
    return FirmwareUpdateData(
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      firmwareDate: firmwareDate ?? this.firmwareDate,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'firmwareVersion': firmwareVersion,
      'firmwareDate': firmwareDate,
      'description': description,
    };
  }

  factory FirmwareUpdateData.fromMap(Map<String, dynamic> map) {
    return FirmwareUpdateData(
      firmwareVersion: map['firmwareVersion'] as String,
      firmwareDate: map['firmwareDate'] as String,
      description: map['description'] != null ? map['description'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory FirmwareUpdateData.fromJson(String source) => FirmwareUpdateData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [firmwareVersion, firmwareDate, description];
}

class FirmwareUpdateOperationStatus extends Equatable {
  final String operation;
  final int progressPercent;
  const FirmwareUpdateOperationStatus({
    required this.operation,
    required this.progressPercent,
  });

  FirmwareUpdateOperationStatus copyWith({
    String? operation,
    int? progressPercent,
  }) {
    return FirmwareUpdateOperationStatus(
      operation: operation ?? this.operation,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'operation': operation,
      'progressPercent': progressPercent,
    };
  }

  factory FirmwareUpdateOperationStatus.fromMap(Map<String, dynamic> map) {
    return FirmwareUpdateOperationStatus(
      operation: map['operation'] as String,
      progressPercent: map['progressPercent'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory FirmwareUpdateOperationStatus.fromJson(String source) => FirmwareUpdateOperationStatus.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [operation, progressPercent];
}
