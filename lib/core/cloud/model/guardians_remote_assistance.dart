import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Remote assistance session status.
///
/// Represents the lifecycle states of a Guardian Remote Assistance session:
/// - [initiate]: Session created, waiting for PIN generation
/// - [pending]: PIN generated, waiting for CA to verify
/// - [active]: CA verified, session is active
/// - [invalid]: Session expired or terminated
enum GRASessionStatus {
  initiate,
  pending,
  active,
  invalid;

  static GRASessionStatus fromString(String status) {
    return switch (status) {
      'INITIATE' => GRASessionStatus.initiate,
      'PENDING' => GRASessionStatus.pending,
      'ACTIVE' => GRASessionStatus.active,
      'INVALID' => GRASessionStatus.invalid,
      _ => throw ArgumentError('Invalid GRASessionStatus: $status'),
    };
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

/// Guardian Remote Assistance session information.
///
/// Response example:
/// ```json
/// {
///   "id": "3683AC72-A4F9-40DC-9CA5-CD5D53F815A9",
///   "serialNumber": "65G10M27E03053",
///   "modelNumber": "LN16-EU",
///   "status": "ACTIVE",
///   "expiredIn": -748,
///   "createdAt": 1748315872000,
///   "statusChangedAt": 1748315989000,
///   "currentTime": 1748316924838
/// }
/// ```
class GRASessionInfo extends Equatable {
  final String id;
  final String serialNumber;
  final String modelNumber;
  final GRASessionStatus status;

  /// Seconds until expiry. Negative value means time remaining.
  final int expiredIn;
  final int createdAt;
  final int statusChangedAt;
  final int currentTime;

  /// PIN code for CA verification (may be null if not in response).
  final String? pin;

  const GRASessionInfo({
    required this.id,
    required this.serialNumber,
    required this.modelNumber,
    required this.status,
    required this.expiredIn,
    required this.createdAt,
    required this.statusChangedAt,
    required this.currentTime,
    this.pin,
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
        currentTime,
        pin,
      ];

  factory GRASessionInfo.fromMap(Map<String, dynamic> map) {
    return GRASessionInfo(
      id: map['id'] as String? ?? '',
      serialNumber: map['serialNumber'] as String? ?? '',
      modelNumber: map['modelNumber'] as String? ?? '',
      status:
          GRASessionStatus.fromString(map['status'] as String? ?? 'INVALID'),
      expiredIn: map['expiredIn'] as int? ?? 0,
      createdAt: map['createdAt'] as int? ?? 0,
      statusChangedAt: map['statusChangedAt'] as int? ?? 0,
      currentTime: map['currentTime'] as int? ?? 0,
      pin: map['pin'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'modelNumber': modelNumber,
      'status': status.toValue(),
      'expiredIn': expiredIn,
      'createdAt': createdAt,
      'statusChangedAt': statusChangedAt,
      'currentTime': currentTime,
      if (pin != null) 'pin': pin,
    };
  }

  String toJson() => json.encode(toMap());

  factory GRASessionInfo.fromJson(String source) =>
      GRASessionInfo.fromMap(json.decode(source) as Map<String, dynamic>);
}
