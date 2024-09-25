// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'package:equatable/equatable.dart';

class GuestWiFiItem extends Equatable {
  final bool isEnabled;
  final String ssid;
  final String password;
  final int numOfDevices;

  const GuestWiFiItem({
    required this.isEnabled,
    required this.ssid,
    required this.password,
    required this.numOfDevices,
  });

  GuestWiFiItem copyWith({
    bool? isEnabled,
    String? ssid,
    String? password,
    int? numOfDevices,
  }) {
    return GuestWiFiItem(
      isEnabled: isEnabled ?? this.isEnabled,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      numOfDevices: numOfDevices ?? this.numOfDevices,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isEnabled': isEnabled,
      'ssid': ssid,
      'password': password,
      'numOfDevices': numOfDevices,
    };
  }

  factory GuestWiFiItem.fromMap(Map<String, dynamic> map) {
    return GuestWiFiItem(
      isEnabled: map['isEnabled'] as bool,
      ssid: map['ssid'] as String,
      password: map['password'] as String,
      numOfDevices: map['numOfDevices'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory GuestWiFiItem.fromJson(String source) =>
      GuestWiFiItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isEnabled, ssid, password, numOfDevices];
}
