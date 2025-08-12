// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

///	remoteSessionStatus: string
/// The status of the remote assistance session.
/// Enum:
/// [ INITIATE, PENDING, ACTIVE, INVALID ]
enum GRASessionStatus {
  initiate,
  pending,
  active,
  invalid,
  ;

  static GRASessionStatus fromString(String status) {
    switch (status) {
      case 'INITIATE':
        return GRASessionStatus.initiate;
      case 'PENDING':
        return GRASessionStatus.pending;
      case 'ACTIVE':
        return GRASessionStatus.active;
      case 'INVALID':
        return GRASessionStatus.invalid;
      default:
        throw Exception('Invalid GRASessionStatus: $status');
    }
  }

  String toValue() {
    return switch (this) {
      GRASessionStatus.initiate => 'INITIATE',
      GRASessionStatus.pending => 'PENDING',
      GRASessionStatus.active => 'ACTIVE',
      GRASessionStatus.invalid => 'INVALID',
    };
  }
}

/// Guardians Remote Assistance Session Info
/// {
/// "id":"3683AC72-A4F9-40DC-9CA5-CD5D53F815A9",
/// "serialNumber":"65G10M27E03053",
/// "modelNumber":"LN16-EU",
/// "status":"ACTIVE",
/// "expiredIn":-748,
/// "createdAt":1748315872000,
/// "statusChangedAt":1748315989000,
/// "currentTime":1748316924838
/// }
class GRASessionInfo extends Equatable {
  final String id;
  final String serialNumber;
  final String modelNumber;
  final GRASessionStatus status;
  final int expiredIn;
  final int createdAt;
  final int statusChangedAt;
  final int currentTime;

  const GRASessionInfo({
    required this.id,
    required this.serialNumber,
    required this.modelNumber,
    required this.status,
    required this.expiredIn,
    required this.createdAt,
    required this.statusChangedAt,
    required this.currentTime,
  });

  @override
  List<Object?> get props => [
        id,
        serialNumber,
        modelNumber,
        status,
        expiredIn,
        createdAt,
        statusChangedAt,
        currentTime
      ];

  factory GRASessionInfo.fromMap(Map<String, dynamic> map) {
    return GRASessionInfo(
      id: map['id'] as String,
      serialNumber: map['serialNumber'] as String,
      modelNumber: map['modelNumber'] as String,
      status: GRASessionStatus.fromString(map['status'] as String),
      expiredIn: map['expiredIn'] as int,
      createdAt: map['createdAt'] as int,
      statusChangedAt: map['statusChangedAt'] as int,
      currentTime: map['currentTime'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'serialNumber': serialNumber,
      'modelNumber': modelNumber,
      'status': status.toValue(),
      'expiredIn': expiredIn,
      'createdAt': createdAt,
      'statusChangedAt': statusChangedAt,
      'currentTime': currentTime,
    };
  }

  String toJson() => json.encode(toMap());

  factory GRASessionInfo.fromJson(String source) =>
      GRASessionInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'GRASessionInfo(id: $id, serialNumber: $serialNumber, modelNumber: $modelNumber, status: $status, expiredIn: $expiredIn, createdAt: $createdAt, statusChangedAt: $statusChangedAt, currentTime: $currentTime)';
}
