// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class DhcpClientModel extends Equatable {
  final String name;
  final String mac;
  final String interface;
  final String ipAddress;
  final String expires;
  const DhcpClientModel({
    required this.name,
    required this.mac,
    required this.interface,
    required this.ipAddress,
    required this.expires,
  });

  DhcpClientModel copyWith({
    String? name,
    String? mac,
    String? interface,
    String? ipAddress,
    String? expires,
  }) {
    return DhcpClientModel(
      name: name ?? this.name,
      mac: mac ?? this.mac,
      interface: interface ?? this.interface,
      ipAddress: ipAddress ?? this.ipAddress,
      expires: expires ?? this.expires,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'mac': mac,
      'interface': interface,
      'ipAddress': ipAddress,
      'expires': expires,
    };
  }

  factory DhcpClientModel.fromMap(Map<String, dynamic> map) {
    return DhcpClientModel(
      name: map['name'] as String,
      mac: map['mac'] as String,
      interface: map['interface'] as String,
      ipAddress: map['ipAddress'] as String,
      expires: map['expires'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory DhcpClientModel.fromJson(String source) => DhcpClientModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      name,
      mac,
      interface,
      ipAddress,
      expires,
    ];
  }
}
