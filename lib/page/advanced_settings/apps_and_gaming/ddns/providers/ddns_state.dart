// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/ddns_settings_model.dart';

import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';

const String dynDNSProviderName = 'DynDNS';
const String noIPDNSProviderName = 'No-IP';
const String tzoDNSProviderName = 'TZO';
const String noDNSProviderName = 'disabled';

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
              mode: '',
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
}

class NoIPDNSProvider extends DDNSProvider<NoIPSettings> {
  NoIPDNSProvider({
    required super.settings,
  }) : super(name: noIPDNSProviderName);

  @override
  DDNSProvider applySettings(settings) {
    return NoIPDNSProvider(settings: settings);
  }
}

class TzoDNSProvider extends DDNSProvider<TZOSettings> {
  TzoDNSProvider({required super.settings}) : super(name: tzoDNSProviderName);

  @override
  DDNSProvider applySettings(settings) {
    return TzoDNSProvider(settings: settings);
  }
}

class NoDDNSProvider extends DDNSProvider<dynamic> {
  NoDDNSProvider({super.settings}) : super(name: noDNSProviderName);

  @override
  DDNSProvider applySettings(settings) {
    return NoDDNSProvider();
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
}
