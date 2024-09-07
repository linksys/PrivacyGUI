// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CloudRemoteAssistanceInfo {
  final String remoteAssistanceSessionId;
  final String? status;
  final int? expiredIn;
  final int? createdAt;
  final int? statusChangedAt;
  final int? currentTime;
  CloudRemoteAssistanceInfo({
    required this.remoteAssistanceSessionId,
    this.status,
    this.expiredIn,
    this.createdAt,
    this.statusChangedAt,
    this.currentTime,
  });

  CloudRemoteAssistanceInfo copyWith({
    String? remoteAssistanceSessionId,
    String? status,
    int? expiredIn,
    int? createdAt,
    int? statusChangedAt,
    int? currentTime,
  }) {
    return CloudRemoteAssistanceInfo(
      remoteAssistanceSessionId: remoteAssistanceSessionId ?? this.remoteAssistanceSessionId,
      status: status ?? this.status,
      expiredIn: expiredIn ?? this.expiredIn,
      createdAt: createdAt ?? this.createdAt,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      currentTime: currentTime ?? this.currentTime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'remoteAssistanceSessionId': remoteAssistanceSessionId,
      'status': status,
      'expiredIn': expiredIn,
      'createdAt': createdAt,
      'statusChangedAt': statusChangedAt,
      'currentTime': currentTime,
    };
  }

  factory CloudRemoteAssistanceInfo.fromMap(Map<String, dynamic> map) {
    return CloudRemoteAssistanceInfo(
      remoteAssistanceSessionId: map['remoteAssistanceSessionId'] as String,
      status: map['status'] != null ? map['status'] as String : null,
      expiredIn: map['expiredIn'] != null ? map['expiredIn'] as int : null,
      createdAt: map['createdAt'] != null ? map['createdAt'] as int : null,
      statusChangedAt: map['statusChangedAt'] != null ? map['statusChangedAt'] as int : null,
      currentTime: map['currentTime'] != null ? map['currentTime'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudRemoteAssistanceInfo.fromJson(String source) => CloudRemoteAssistanceInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CloudRemoteAssistanceInfo(remoteAssistanceSessionId: $remoteAssistanceSessionId, status: $status, expiredIn: $expiredIn, createdAt: $createdAt, statusChangedAt: $statusChangedAt, currentTime: $currentTime)';
  }

  @override
  bool operator ==(covariant CloudRemoteAssistanceInfo other) {
    if (identical(this, other)) return true;
  
    return 
      other.remoteAssistanceSessionId == remoteAssistanceSessionId &&
      other.status == status &&
      other.expiredIn == expiredIn &&
      other.createdAt == createdAt &&
      other.statusChangedAt == statusChangedAt &&
      other.currentTime == currentTime;
  }

  @override
  int get hashCode {
    return remoteAssistanceSessionId.hashCode ^
      status.hashCode ^
      expiredIn.hashCode ^
      createdAt.hashCode ^
      statusChangedAt.hashCode ^
      currentTime.hashCode;
  }
}
