// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class DynDNSMailExchangeSettings extends Equatable {
  final String hostName;
  final bool isBackup;
  const DynDNSMailExchangeSettings({
    required this.hostName,
    required this.isBackup,
  });

  DynDNSMailExchangeSettings copyWith({
    String? hostName,
    bool? isBackup,
  }) {
    return DynDNSMailExchangeSettings(
      hostName: hostName ?? this.hostName,
      isBackup: isBackup ?? this.isBackup,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hostName': hostName,
      'isBackup': isBackup,
    };
  }

  factory DynDNSMailExchangeSettings.fromMap(Map<String, dynamic> map) {
    return DynDNSMailExchangeSettings(
      hostName: map['hostName'] as String,
      isBackup: map['isBackup'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory DynDNSMailExchangeSettings.fromJson(String source) =>
      DynDNSMailExchangeSettings.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [hostName, isBackup];
}

class DynDNSSettings extends Equatable {
  final String username;
  final String password;
  final String hostName;
  final bool isWildcardEnabled;
  final String mode;
  final bool isMailExchangeEnabled;
  final DynDNSMailExchangeSettings? mailExchangeSettings;
  const DynDNSSettings({
    required this.username,
    required this.password,
    required this.hostName,
    required this.isWildcardEnabled,
    required this.mode,
    required this.isMailExchangeEnabled,
    this.mailExchangeSettings,
  });

  DynDNSSettings copyWith({
    String? username,
    String? password,
    String? hostName,
    bool? isWildcardEnabled,
    String? mode,
    bool? isMailExchangeEnabled,
    DynDNSMailExchangeSettings? mailExchangeSettings,
  }) {
    return DynDNSSettings(
      username: username ?? this.username,
      password: password ?? this.password,
      hostName: hostName ?? this.hostName,
      isWildcardEnabled: isWildcardEnabled ?? this.isWildcardEnabled,
      mode: mode ?? this.mode,
      isMailExchangeEnabled:
          isMailExchangeEnabled ?? this.isMailExchangeEnabled,
      mailExchangeSettings: mailExchangeSettings ?? this.mailExchangeSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'username': username,
      'password': password,
      'hostName': hostName,
      'isWildcardEnabled': isWildcardEnabled,
      'mode': mode,
      'isMailExchangeEnabled': isMailExchangeEnabled,
      'mailExchangeSettings': mailExchangeSettings?.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  factory DynDNSSettings.fromMap(Map<String, dynamic> map) {
    return DynDNSSettings(
      username: map['username'] as String,
      password: map['password'] as String,
      hostName: map['hostName'] as String,
      isWildcardEnabled: map['isWildcardEnabled'] as bool,
      mode: map['mode'] as String,
      isMailExchangeEnabled: map['isMailExchangeEnabled'] as bool,
      mailExchangeSettings: map['mailExchangeSettings'] != null
          ? DynDNSMailExchangeSettings.fromMap(
              map['mailExchangeSettings'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DynDNSSettings.fromJson(String source) =>
      DynDNSSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      username,
      password,
      hostName,
      isWildcardEnabled,
      mode,
      isMailExchangeEnabled,
      mailExchangeSettings,
    ];
  }
}
