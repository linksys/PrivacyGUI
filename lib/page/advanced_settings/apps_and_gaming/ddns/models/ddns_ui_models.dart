// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Provider name constants for UI layer
const String dynDNSProviderName = 'DynDNS';
const String noIPDNSProviderName = 'No-IP';
const String tzoDNSProviderName = 'TZO';
const String noDNSProviderName = 'None';

/// Mail Exchange settings for DynDNS provider
class DynDNSMailExchangeUIModel extends Equatable {
  final String hostName;
  final bool isBackup;

  const DynDNSMailExchangeUIModel({
    required this.hostName,
    required this.isBackup,
  });

  DynDNSMailExchangeUIModel copyWith({
    String? hostName,
    bool? isBackup,
  }) {
    return DynDNSMailExchangeUIModel(
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

  factory DynDNSMailExchangeUIModel.fromMap(Map<String, dynamic> map) {
    return DynDNSMailExchangeUIModel(
      hostName: map['hostName'] as String,
      isBackup: map['isBackup'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory DynDNSMailExchangeUIModel.fromJson(String source) =>
      DynDNSMailExchangeUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  List<Object> get props => [hostName, isBackup];
}

/// Base sealed class for DDNS provider UI models
sealed class DDNSProviderUIModel extends Equatable {
  const DDNSProviderUIModel();

  String get name;

  /// Apply new settings and return a new instance
  DDNSProviderUIModel applySettings(dynamic settings);

  Map<String, dynamic> toMap();

  String toJson() => json.encode(toMap());

  /// Factory to resolve provider from name
  static DDNSProviderUIModel create(String name) {
    return switch (name) {
      dynDNSProviderName => const DynDNSProviderUIModel(
          username: '',
          password: '',
          hostName: '',
          isWildcardEnabled: false,
          mode: 'Dynamic',
          isMailExchangeEnabled: false,
        ),
      noIPDNSProviderName => const NoIPDNSProviderUIModel(
          username: '',
          password: '',
          hostName: '',
        ),
      tzoDNSProviderName => const TzoDNSProviderUIModel(
          username: '',
          password: '',
          hostName: '',
        ),
      _ => const NoDDNSProviderUIModel(),
    };
  }

  factory DDNSProviderUIModel.fromMap(Map<String, dynamic> map) {
    return switch (map['name']) {
      dynDNSProviderName => DynDNSProviderUIModel.fromMap(map),
      noIPDNSProviderName => NoIPDNSProviderUIModel.fromMap(map),
      tzoDNSProviderName => TzoDNSProviderUIModel.fromMap(map),
      _ => const NoDDNSProviderUIModel(),
    };
  }

  factory DDNSProviderUIModel.fromJson(String source) =>
      DDNSProviderUIModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// UI model for DynDNS provider
class DynDNSProviderUIModel extends DDNSProviderUIModel {
  @override
  final String name = dynDNSProviderName;

  final String username;
  final String password;
  final String hostName;
  final bool isWildcardEnabled;
  final String mode;
  final bool isMailExchangeEnabled;
  final DynDNSMailExchangeUIModel? mailExchangeSettings;

  const DynDNSProviderUIModel({
    this.username = '',
    this.password = '',
    this.hostName = '',
    this.isWildcardEnabled = false,
    this.mode = 'Dynamic',
    this.isMailExchangeEnabled = false,
    this.mailExchangeSettings,
  });

  DynDNSProviderUIModel copyWith({
    String? username,
    String? password,
    String? hostName,
    bool? isWildcardEnabled,
    String? mode,
    bool? isMailExchangeEnabled,
    ValueGetter<DynDNSMailExchangeUIModel?>? mailExchangeSettings,
  }) {
    return DynDNSProviderUIModel(
      username: username ?? this.username,
      password: password ?? this.password,
      hostName: hostName ?? this.hostName,
      isWildcardEnabled: isWildcardEnabled ?? this.isWildcardEnabled,
      mode: mode ?? this.mode,
      isMailExchangeEnabled:
          isMailExchangeEnabled ?? this.isMailExchangeEnabled,
      mailExchangeSettings: mailExchangeSettings != null
          ? mailExchangeSettings()
          : this.mailExchangeSettings,
    );
  }

  @override
  DDNSProviderUIModel applySettings(dynamic settings) {
    if (settings is DynDNSProviderUIModel) {
      return settings;
    }
    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'username': username,
      'password': password,
      'hostName': hostName,
      'isWildcardEnabled': isWildcardEnabled,
      'mode': mode,
      'isMailExchangeEnabled': isMailExchangeEnabled,
      'mailExchangeSettings': mailExchangeSettings?.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  factory DynDNSProviderUIModel.fromMap(Map<String, dynamic> map) {
    return DynDNSProviderUIModel(
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      hostName: map['hostName'] as String? ?? '',
      isWildcardEnabled: map['isWildcardEnabled'] as bool? ?? false,
      mode: map['mode'] as String? ?? 'Dynamic',
      isMailExchangeEnabled: map['isMailExchangeEnabled'] as bool? ?? false,
      mailExchangeSettings: map['mailExchangeSettings'] != null
          ? DynDNSMailExchangeUIModel.fromMap(
              map['mailExchangeSettings'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        name,
        username,
        password,
        hostName,
        isWildcardEnabled,
        mode,
        isMailExchangeEnabled,
        mailExchangeSettings,
      ];
}

/// UI model for No-IP DNS provider
class NoIPDNSProviderUIModel extends DDNSProviderUIModel {
  @override
  final String name = noIPDNSProviderName;

  final String username;
  final String password;
  final String hostName;

  const NoIPDNSProviderUIModel({
    this.username = '',
    this.password = '',
    this.hostName = '',
  });

  NoIPDNSProviderUIModel copyWith({
    String? username,
    String? password,
    String? hostName,
  }) {
    return NoIPDNSProviderUIModel(
      username: username ?? this.username,
      password: password ?? this.password,
      hostName: hostName ?? this.hostName,
    );
  }

  @override
  DDNSProviderUIModel applySettings(dynamic settings) {
    if (settings is NoIPDNSProviderUIModel) {
      return settings;
    }
    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'username': username,
      'password': password,
      'hostName': hostName,
    };
  }

  factory NoIPDNSProviderUIModel.fromMap(Map<String, dynamic> map) {
    return NoIPDNSProviderUIModel(
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      hostName: map['hostName'] as String? ?? '',
    );
  }

  @override
  List<Object> get props => [name, username, password, hostName];
}

/// UI model for TZO DNS provider
class TzoDNSProviderUIModel extends DDNSProviderUIModel {
  @override
  final String name = tzoDNSProviderName;

  final String username;
  final String password;
  final String hostName;

  const TzoDNSProviderUIModel({
    this.username = '',
    this.password = '',
    this.hostName = '',
  });

  TzoDNSProviderUIModel copyWith({
    String? username,
    String? password,
    String? hostName,
  }) {
    return TzoDNSProviderUIModel(
      username: username ?? this.username,
      password: password ?? this.password,
      hostName: hostName ?? this.hostName,
    );
  }

  @override
  DDNSProviderUIModel applySettings(dynamic settings) {
    if (settings is TzoDNSProviderUIModel) {
      return settings;
    }
    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'username': username,
      'password': password,
      'hostName': hostName,
    };
  }

  factory TzoDNSProviderUIModel.fromMap(Map<String, dynamic> map) {
    return TzoDNSProviderUIModel(
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      hostName: map['hostName'] as String? ?? '',
    );
  }

  @override
  List<Object> get props => [name, username, password, hostName];
}

/// UI model for no DDNS provider (disabled)
class NoDDNSProviderUIModel extends DDNSProviderUIModel {
  @override
  final String name = noDNSProviderName;

  const NoDDNSProviderUIModel();

  @override
  DDNSProviderUIModel applySettings(dynamic settings) {
    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
    };
  }

  @override
  List<Object> get props => [name];
}

/// Container for DDNS settings
class DDNSSettingsUIModel extends Equatable {
  final DDNSProviderUIModel provider;

  const DDNSSettingsUIModel({required this.provider});

  DDNSSettingsUIModel copyWith({DDNSProviderUIModel? provider}) {
    return DDNSSettingsUIModel(provider: provider ?? this.provider);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'provider': provider.toMap(),
    };
  }

  factory DDNSSettingsUIModel.fromMap(Map<String, dynamic> map) {
    return DDNSSettingsUIModel(
      provider:
          DDNSProviderUIModel.fromMap(map['provider'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory DDNSSettingsUIModel.fromJson(String source) =>
      DDNSSettingsUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [provider];
}

/// Status information for DDNS
class DDNSStatusUIModel extends Equatable {
  final List<String> supportedProviders;
  final String status;
  final String ipAddress;

  const DDNSStatusUIModel({
    required this.supportedProviders,
    required this.status,
    required this.ipAddress,
  });

  DDNSStatusUIModel copyWith({
    List<String>? supportedProviders,
    String? status,
    String? ipAddress,
  }) {
    return DDNSStatusUIModel(
      supportedProviders: supportedProviders ?? this.supportedProviders,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'supportedProviders': supportedProviders,
      'status': status,
      'ipAddress': ipAddress,
    };
  }

  factory DDNSStatusUIModel.fromMap(Map<String, dynamic> map) {
    return DDNSStatusUIModel(
      supportedProviders: List<String>.from(
          map['supportedProviders'] ?? map['supportedProvider'] ?? []),
      status: map['status'] as String? ?? '',
      ipAddress: map['ipAddress'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DDNSStatusUIModel.fromJson(String source) =>
      DDNSStatusUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [supportedProviders, status, ipAddress];
}
