import 'package:equatable/equatable.dart';

// http://linksys.com/jnap/router/DualWanConnectionStatus
enum DualWANConnectionStatusData {
  connected('Connected'),
  active('Active'),
  standby('Standby');

  final String value;
  const DualWANConnectionStatusData(this.value);

  static DualWANConnectionStatusData fromJson(String json) =>
      values.firstWhere((e) => e.value == json);

  String toJson() => value;
}

// http://linksys.com/jnap/router/DualWANConnectionInfo
class DualWANConnectionInfo extends Equatable {
  /// WAN type of the wan connection
  final String wanType;

  /// IP address of the wan connection (optional)
  final String? ipAddress;

  /// Up time of the wan connection (optional)
  final int? uptime;

  const DualWANConnectionInfo({
    required this.wanType,
    this.ipAddress,
    this.uptime,
  });

  @override
  List<Object?> get props => [
        wanType,
        ipAddress,
        uptime,
      ];

  factory DualWANConnectionInfo.fromMap(Map<String, dynamic> map) {
    return DualWANConnectionInfo(
      wanType: map['wanType'],
      ipAddress: map['ipAddress'] as String?,
      // JNAP spec sample uses an int for uptime
      uptime: map['uptime'] is String
          ? int.tryParse(map['uptime'])
          : map['uptime'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wanType': wanType,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (uptime != null) 'uptime': uptime,
    };
  }

  factory DualWANConnectionInfo.fromJson(Map<String, dynamic> json) =>
      DualWANConnectionInfo.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}

// http://linksys.com/jnap/router/GetDualWANStatus
class RouterDualWANStatus extends Equatable {
  /// The list of WAN types supported by the router
  final List<String> supportedWANTypes;

  /// Current WAN connection status of the primary wan
  final DualWANConnectionStatusData? primaryWANStatus;

  /// Connection information of the primary wan
  /// (Only present if status is not Disconnected or LimitedConnection, per WANStatus general usage)
  final DualWANConnectionInfo? primaryWANConnection;

  /// Current WAN connection status of the secondary wan
  final DualWANConnectionStatusData? secondaryWANStatus;

  /// Connection information of the secondary wan
  /// (Only present if status is not Disconnected or LimitedConnection, per WANStatus general usage)
  final DualWANConnectionInfo? secondaryWANConnection;

  const RouterDualWANStatus({
    required this.supportedWANTypes,
    this.primaryWANStatus,
    this.primaryWANConnection,
    this.secondaryWANStatus,
    this.secondaryWANConnection,
  });

  // 1. 繼承 Equatable
  @override
  List<Object?> get props => [
        supportedWANTypes,
        primaryWANStatus,
        primaryWANConnection,
        secondaryWANStatus,
        secondaryWANConnection,
      ];

  // 3. fromMap/toMap functions
  factory RouterDualWANStatus.fromMap(Map<String, dynamic> map) {
    return RouterDualWANStatus(
      supportedWANTypes: List<String>.from(map['supportedWANTypes']),
      primaryWANStatus: map['primaryWANStatus'] != null
          ? DualWANConnectionStatusData.fromJson(
              map['primaryWANStatus'] as String)
          : null,
      primaryWANConnection: map['primaryWANConnection'] != null
          ? DualWANConnectionInfo.fromMap(
              map['primaryWANConnection'] as Map<String, dynamic>)
          : null,
      secondaryWANStatus: map['secondaryWANStatus'] != null
          ? DualWANConnectionStatusData.fromJson(
              map['secondaryWANStatus'] as String)
          : null,
      secondaryWANConnection: map['secondaryWANConnection'] != null
          ? DualWANConnectionInfo.fromMap(
              map['secondaryWANConnection'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supportedWANTypes': supportedWANTypes,
      if (primaryWANStatus != null)
        'primaryWANStatus': primaryWANStatus?.toJson(),
      if (primaryWANConnection != null)
        'primaryWANConnection': primaryWANConnection?.toMap(),
      if (secondaryWANStatus != null)
        'secondaryWANStatus': secondaryWANStatus?.toJson(),
      if (secondaryWANConnection != null)
        'secondaryWANConnection': secondaryWANConnection?.toMap(),
    };
  }

  // 2. fromJson/toJson functions
  factory RouterDualWANStatus.fromJson(Map<String, dynamic> json) =>
      RouterDualWANStatus.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}
