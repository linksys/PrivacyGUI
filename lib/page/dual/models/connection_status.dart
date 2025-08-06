import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/dual/models/connection.dart';

class ConnectionStatus extends Equatable {
  final DualWANConnection primaryStatus;
  final DualWANConnection secondaryStatus;
  final String primaryWANIPAddress;
  final String secondaryWANIPAddress;
  final int primaryUptime;
  final int secondaryUptime;

  const ConnectionStatus({
    this.primaryStatus = DualWANConnection.disconnected,
    this.secondaryStatus = DualWANConnection.disconnected,
    this.primaryWANIPAddress = '',
    this.secondaryWANIPAddress = '',
    this.primaryUptime = 0,
    this.secondaryUptime = 0,
  });

  ConnectionStatus copyWith({
    DualWANConnection? primaryStatus,
    DualWANConnection? secondaryStatus,
    String? primaryWANIPAddress,
    String? secondaryWANIPAddress,
    int? primaryUptime,
    int? secondaryUptime,
  }) {
    return ConnectionStatus(
      primaryStatus: primaryStatus ?? this.primaryStatus,
      secondaryStatus: secondaryStatus ?? this.secondaryStatus,
      primaryWANIPAddress: primaryWANIPAddress ?? this.primaryWANIPAddress,
      secondaryWANIPAddress:
          secondaryWANIPAddress ?? this.secondaryWANIPAddress,
      primaryUptime: primaryUptime ?? this.primaryUptime,
      secondaryUptime: secondaryUptime ?? this.secondaryUptime,
    );
  }

  factory ConnectionStatus.fromMap(Map<String, dynamic> map) {
    return ConnectionStatus(
      primaryStatus: DualWANConnection.fromValue(map['primaryStatus']),
      secondaryStatus: DualWANConnection.fromValue(map['secondaryStatus']),
      primaryWANIPAddress: map['primaryWANIPAddress'],
      secondaryWANIPAddress: map['secondaryWANIPAddress'],
      primaryUptime: map['primaryUptime'],
      secondaryUptime: map['secondaryUptime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ConnectionStatus.fromJson(String source) =>
      ConnectionStatus.fromMap(json.decode(source) as Map<String, dynamic>);

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
}
