// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

enum DeviceStatusType {
  ipv4,
  ipv6,
  ;

  static DeviceStatusType reslove(String type) =>
      DeviceStatusType.values
          .firstWhereOrNull((element) => element.name == type) ??
      DeviceStatusType.ipv4;
}

class DeviceStatusModel extends Equatable {
  final String name;
  final String mac;
  final String ipAddress;
  final String connection;
  final DeviceStatusType type;
  const DeviceStatusModel({
    required this.name,
    required this.mac,
    required this.ipAddress,
    required this.connection,
    required this.type,
  });

  factory DeviceStatusModel.ipv4({
    required String name,
    required String mac,
    required String ipAddress,
    required String connection,
  }) =>
      DeviceStatusModel(
          name: name,
          mac: mac,
          ipAddress: ipAddress,
          connection: connection,
          type: DeviceStatusType.ipv4);

  factory DeviceStatusModel.ipv6({
    required String name,
    required String mac,
    required String ipAddress,
    required String connection,
  }) =>
      DeviceStatusModel(
          name: name,
          mac: mac,
          ipAddress: ipAddress,
          connection: connection,
          type: DeviceStatusType.ipv6);
          
  DeviceStatusModel copyWith({
    String? name,
    String? mac,
    String? ipAddress,
    String? connection,
    DeviceStatusType? type,
  }) {
    return DeviceStatusModel(
      name: name ?? this.name,
      mac: mac ?? this.mac,
      ipAddress: ipAddress ?? this.ipAddress,
      connection: connection ?? this.connection,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'mac': mac,
      'ipAddress': ipAddress,
      'connection': connection,
      'type': type.name,
    };
  }

  factory DeviceStatusModel.fromMap(Map<String, dynamic> map) {
    return DeviceStatusModel(
      name: map['name'] as String,
      mac: map['mac'] as String,
      ipAddress: map['ipAddress'] as String,
      connection: map['connection'] as String,
      type: DeviceStatusType.reslove(map['type']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceStatusModel.fromJson(String source) =>
      DeviceStatusModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      name,
      mac,
      ipAddress,
      connection,
      type,
    ];
  }
}
