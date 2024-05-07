// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'package:equatable/equatable.dart';

class GuestWiFiState extends Equatable {
  final bool isEnabled;
  final String ssid;
  final String password;
  final int numOfDevices;

  const GuestWiFiState({
    required this.isEnabled,
    required this.ssid,
    required this.password,
    required this.numOfDevices,
  });

  GuestWiFiState copyWith({
    bool? isEnabled,
    String? ssid,
    String? password,
    int? numOfDevices,
  }) {
    return GuestWiFiState(
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

  factory GuestWiFiState.fromMap(Map<String, dynamic> map) {
    return GuestWiFiState(
      isEnabled: map['isEnabled'] as bool,
      ssid: map['ssid'] as String,
      password: map['password'] as String,
      numOfDevices: map['numOfDevices'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory GuestWiFiState.fromJson(String source) =>
      GuestWiFiState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isEnabled, ssid, password, numOfDevices];
}
