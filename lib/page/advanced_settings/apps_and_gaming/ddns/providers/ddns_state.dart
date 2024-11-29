// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/ddns_settings_model.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';

const String dynDNSProviderName = 'DynDNS';
const String noIPDNSProviderName = 'No-IP';
const String tzoDNSProviderName = 'TZO';
const String noDNSProviderName = 'None';

sealed class DDNSProvider<T> extends Equatable {
  final String name;
  final T settings;

  const DDNSProvider({
    required this.name,
    required this.settings,
  });

  DDNSProvider applySettings(dynamic settings);

  static DDNSProvider reslove(DDNSSettings? settings) {
    if (settings == null) {
      return NoDDNSProvider();
    } else if (settings.dynDNSSettings != null) {
      return DynDNSProvider(settings: settings.dynDNSSettings!);
    } else if (settings.noIPSettings != null) {
      return NoIPDNSProvider(settings: settings.noIPSettings!);
    } else if (settings.tzoSettings != null) {
      return TzoDNSProvider(settings: settings.tzoSettings!);
    } else {
      return NoDDNSProvider();
    }
  }

  static DDNSProvider create(String name) {
    if (name == dynDNSProviderName) {
      return DynDNSProvider(
          settings: const DynDNSSettings(
              username: '',
              password: '',
              hostName: '',
              isWildcardEnabled: false,
              mode: 'Dynamic',
              isMailExchangeEnabled: false));
    } else if (name == noIPDNSProviderName) {
      return NoIPDNSProvider(
          settings:
              const NoIPSettings(username: '', password: '', hostName: ''));
    } else if (name == tzoDNSProviderName) {
      return TzoDNSProvider(
          settings:
              const TZOSettings(username: '', password: '', hostName: ''));
    } else {
      return NoDDNSProvider();
    }
  }

  Map<String, dynamic> toMap();

  factory DDNSProvider.fromMap(Map<String, dynamic> map) {
    return switch (map['name']) {
      dynDNSProviderName =>
        DynDNSProvider(settings: DynDNSSettings.fromMap(map['settings']))
            as DDNSProvider<T>,
      noIPDNSProviderName =>
        NoIPDNSProvider(settings: NoIPSettings.fromMap(map['settings']))
            as DDNSProvider<T>,
      tzoDNSProviderName =>
        TzoDNSProvider(settings: TZOSettings.fromMap(map['settings']))
            as DDNSProvider<T>,
      _ => NoDDNSProvider() as DDNSProvider<T>,
    };
  }

  String toJson() => json.encode(toMap());

  factory DDNSProvider.fromJson(String source) =>
      DDNSProvider.fromMap(json.decode(source));

  @override
  List<Object?> get props => [
        name,
        settings,
      ];
}

class DynDNSProvider extends DDNSProvider<DynDNSSettings> {
  const DynDNSProvider({
    required super.settings,
  }) : super(name: dynDNSProviderName);

  @override
  DDNSProvider applySettings(settings) {
    return DynDNSProvider(settings: settings);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'settings': settings.toMap(),
    }..removeWhere((key, value) => value == null);
  }
}

class NoIPDNSProvider extends DDNSProvider<NoIPSettings> {
  const NoIPDNSProvider({
    required super.settings,
  }) : super(name: noIPDNSProviderName);

  @override
  DDNSProvider applySettings(settings) {
    return NoIPDNSProvider(settings: settings);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'settings': settings.toMap(),
    }..removeWhere((key, value) => value == null);
  }
}

class TzoDNSProvider extends DDNSProvider<TZOSettings> {
  const TzoDNSProvider({required super.settings})
      : super(name: tzoDNSProviderName);

  @override
  DDNSProvider applySettings(settings) {
    return TzoDNSProvider(settings: settings);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'settings': settings.toMap(),
    }..removeWhere((key, value) => value == null);
  }
}

class NoDDNSProvider extends DDNSProvider<dynamic> {
  const NoDDNSProvider({super.settings}) : super(name: noDNSProviderName);

  @override
  DDNSProvider applySettings(settings) {
    return NoDDNSProvider();
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
    }..removeWhere((key, value) => value == null);
  }
}

class DDNSState extends Equatable {
  final List<String> supportedProvider;
  final DDNSProvider provider;
  final String status;
  final String ipAddress;
  const DDNSState({
    required this.supportedProvider,
    required this.provider,
    required this.status,
    required this.ipAddress,
  });

  DDNSState copyWith({
    List<String>? supportedProvider,
    DDNSProvider? provider,
    String? status,
    String? ipAddress,
  }) {
    return DDNSState(
      supportedProvider: supportedProvider ?? this.supportedProvider,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [supportedProvider, provider, status, ipAddress];

  Map<String, dynamic> toMap() {
    return {
      'supportedProvider': supportedProvider,
      'provider': provider.toMap(),
      'status': status,
      'ipAddress': ipAddress,
    };
  }

  factory DDNSState.fromMap(Map<String, dynamic> map) {
    return DDNSState(
      supportedProvider: List<String>.from(map['supportedProvider']),
      provider: DDNSProvider.fromMap(map['provider']),
      status: map['status'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DDNSState.fromJson(String source) =>
      DDNSState.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DDNSState(supportedProvider: $supportedProvider, provider: $provider, status: $status, ipAddress: $ipAddress)';
  }
}
