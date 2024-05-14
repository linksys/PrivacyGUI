// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class TZOSettings extends Equatable {
  final String username;
  final String password;
  final String hostName;
  const TZOSettings({
    required this.username,
    required this.password,
    required this.hostName,
  });

  TZOSettings copyWith({
    String? username,
    String? password,
    String? hostName,
  }) {
    return TZOSettings(
      username: username ?? this.username,
      password: password ?? this.password,
      hostName: hostName ?? this.hostName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'username': username,
      'password': password,
      'hostName': hostName,
    };
  }

  factory TZOSettings.fromMap(Map<String, dynamic> map) {
    return TZOSettings(
      username: map['username'] as String,
      password: map['password'] as String,
      hostName: map['hostName'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory TZOSettings.fromJson(String source) => TZOSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [username, password, hostName];
}
