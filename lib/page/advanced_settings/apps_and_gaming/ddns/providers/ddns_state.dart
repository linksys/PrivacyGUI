// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/ddns_settings_model.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

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

  static DDNSProvider reslove(RouterDDNSSettings? settings) {
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

class DDNSSettings extends Equatable {
  final DDNSProvider provider;

  const DDNSSettings({required this.provider});

  @override
  List<Object?> get props => [provider];

  DDNSSettings copyWith({DDNSProvider? provider}) {
    return DDNSSettings(provider: provider ?? this.provider);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'provider': provider.toMap()};
  }

  factory DDNSSettings.fromMap(Map<String, dynamic> map) {
    return DDNSSettings(provider: DDNSProvider.fromMap(map['provider']));
  }
}

class DDNSStatus extends Equatable {
  final List<String> supportedProvider;
  final String status;
  final String ipAddress;

  const DDNSStatus({
    required this.supportedProvider,
    required this.status,
    required this.ipAddress,
  });

  @override
  List<Object?> get props => [supportedProvider, status, ipAddress];

  DDNSStatus copyWith({
    List<String>? supportedProvider,
    String? status,
    String? ipAddress,
  }) {
    return DDNSStatus(
      supportedProvider: supportedProvider ?? this.supportedProvider,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'supportedProvider': supportedProvider,
      'status': status,
      'ipAddress': ipAddress,
    };
  }

  factory DDNSStatus.fromMap(Map<String, dynamic> map) {
    return DDNSStatus(
      supportedProvider: List<String>.from(map['supportedProvider']),
      status: map['status'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
    );
  }
}

class DDNSState extends FeatureState<DDNSSettings, DDNSStatus> {
  const DDNSState({
    required super.settings,
    required super.status,
  });

  @override
  DDNSState copyWith({
    Preservable<DDNSSettings>? settings,
    DDNSStatus? status,
  }) {
    return DDNSState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((s) => s.toMap()),
      'status': status.toMap(),
    };
  }

  factory DDNSState.fromMap(Map<String, dynamic> map) {
    return DDNSState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) => DDNSSettings.fromMap(valueMap as Map<String, dynamic>),
      ),
      status: DDNSStatus.fromMap(map['status'] as Map<String, dynamic>),
    );
  }

  factory DDNSState.fromJson(String source) =>
      DDNSState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings, status];
}
