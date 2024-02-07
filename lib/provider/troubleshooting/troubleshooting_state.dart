// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:linksys_app/provider/troubleshooting/device_status.dart';
import 'package:linksys_app/provider/troubleshooting/dhcp_client.dart';

class TroubleshootingState extends Equatable {
  final List<DeviceStatusModel> deviceStatusList;
  final List<DhcpClientModel> dhcpClientList;
  const TroubleshootingState({
    required this.deviceStatusList,
    required this.dhcpClientList,
  });

  TroubleshootingState copyWith({
    List<DeviceStatusModel>? deviceStatusList,
    List<DhcpClientModel>? dhchClientList,
  }) {
    return TroubleshootingState(
      deviceStatusList: deviceStatusList ?? this.deviceStatusList,
      dhcpClientList: dhchClientList ?? this.dhcpClientList,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceStatusList': deviceStatusList.map((x) => x.toMap()).toList(),
      'dhchClientList': dhcpClientList.map((x) => x.toMap()).toList(),
    };
  }

  factory TroubleshootingState.fromMap(Map<String, dynamic> map) {
    return TroubleshootingState(
      deviceStatusList: List<DeviceStatusModel>.from(
        (map['deviceStatusList'] as List<int>).map<DeviceStatusModel>(
          (x) => DeviceStatusModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      dhcpClientList: List<DhcpClientModel>.from(
        (map['dhchClientList'] as List<int>).map<DhcpClientModel>(
          (x) => DhcpClientModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory TroubleshootingState.fromJson(String source) =>
      TroubleshootingState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [deviceStatusList, dhcpClientList];
}
