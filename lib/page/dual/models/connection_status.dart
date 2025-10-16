import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_status.dart';
import 'package:privacy_gui/page/dual/models/connection.dart';

class DualWANConnectionStatus extends Equatable {
  final DualWANConnection primaryStatus;
  final DualWANConnection secondaryStatus;
  final String? primaryWANIPAddress;
  final String? secondaryWANIPAddress;
  final int? primaryUptime;
  final int? secondaryUptime;

  const DualWANConnectionStatus({
    this.primaryStatus = DualWANConnection.disconnected,
    this.secondaryStatus = DualWANConnection.disconnected,
    this.primaryWANIPAddress,
    this.secondaryWANIPAddress,
    this.primaryUptime,
    this.secondaryUptime,
  });

  DualWANConnectionStatus copyWith({
    DualWANConnection? primaryStatus,
    DualWANConnection? secondaryStatus,
    String? primaryWANIPAddress,
    String? secondaryWANIPAddress,
    int? primaryUptime,
    int? secondaryUptime,
  }) {
    return DualWANConnectionStatus(
      primaryStatus: primaryStatus ?? this.primaryStatus,
      secondaryStatus: secondaryStatus ?? this.secondaryStatus,
      primaryWANIPAddress: primaryWANIPAddress ?? this.primaryWANIPAddress,
      secondaryWANIPAddress:
          secondaryWANIPAddress ?? this.secondaryWANIPAddress,
      primaryUptime: primaryUptime ?? this.primaryUptime,
      secondaryUptime: secondaryUptime ?? this.secondaryUptime,
    );
  }

  factory DualWANConnectionStatus.fromMap(Map<String, dynamic> map) {
    return DualWANConnectionStatus(
      primaryStatus: DualWANConnection.fromValue(map['primaryStatus']),
      secondaryStatus: DualWANConnection.fromValue(map['secondaryStatus']),
      primaryWANIPAddress: map['primaryWANIPAddress'],
      secondaryWANIPAddress: map['secondaryWANIPAddress'],
      primaryUptime: map['primaryUptime']?.toInt(),
      secondaryUptime: map['secondaryUptime']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory DualWANConnectionStatus.fromJson(String source) =>
      DualWANConnectionStatus.fromMap(
          json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'primaryStatus': primaryStatus.name,
      'secondaryStatus': secondaryStatus.name,
      'primaryUptime': primaryUptime,
      'secondaryUptime': secondaryUptime,
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => [
        primaryStatus,
        secondaryStatus,
        primaryWANIPAddress,
        secondaryWANIPAddress,
        primaryUptime,
        secondaryUptime,
      ];

  factory DualWANConnectionStatus.fromData(RouterDualWANStatus data) {
    return DualWANConnectionStatus(
      primaryStatus: data.primaryWANStatus != null
          ? DualWANConnection.fromValue(data.primaryWANStatus!)
          : DualWANConnection.disconnected,
      secondaryStatus: data.secondaryWANStatus != null
          ? DualWANConnection.fromValue(data.secondaryWANStatus!)
          : DualWANConnection.disconnected,
      primaryWANIPAddress: data.primaryWANConnection?.ipAddress,
      secondaryWANIPAddress: data.secondaryWANConnection?.ipAddress,
      primaryUptime: data.primaryWANConnection?.uptime,
      secondaryUptime: data.secondaryWANConnection?.uptime,
    );
  }
}
