// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'dyn_dns_settings.dart';
import 'no_ip_settings.dart';
import 'tzo_settings.dart';

class RouterDDNSSettings extends Equatable {
  final String ddnsProvider;
  final DynDNSSettings? dynDNSSettings;
  final TZOSettings? tzoSettings;
  final NoIPSettings? noIPSettings;
  const RouterDDNSSettings({
    required this.ddnsProvider,
    this.dynDNSSettings,
    this.tzoSettings,
    this.noIPSettings,
  });

  RouterDDNSSettings copyWith({
    String? ddnsProvider,
    DynDNSSettings? dynDNSSettings,
    TZOSettings? tzoSettings,
    NoIPSettings? noIPSettings,
  }) {
    return RouterDDNSSettings(
      ddnsProvider: ddnsProvider ?? this.ddnsProvider,
      dynDNSSettings: dynDNSSettings ?? this.dynDNSSettings,
      tzoSettings: tzoSettings ?? this.tzoSettings,
      noIPSettings: noIPSettings ?? this.noIPSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ddnsProvider': ddnsProvider,
      'dynDNSSettings': dynDNSSettings?.toMap(),
      'tzoSettings': tzoSettings?.toMap(),
      'noipSettings': noIPSettings?.toMap(),
    };
  }

  factory RouterDDNSSettings.fromMap(Map<String, dynamic> map) {
    return RouterDDNSSettings(
      ddnsProvider: map['ddnsProvider'] as String,
      dynDNSSettings: map['dynDNSSettings'] != null
          ? DynDNSSettings.fromMap(
              map['dynDNSSettings'] as Map<String, dynamic>)
          : null,
      tzoSettings: map['tzoSettings'] != null
          ? TZOSettings.fromMap(map['tzoSettings'] as Map<String, dynamic>)
          : null,
      noIPSettings: map['noipSettings'] != null
          ? NoIPSettings.fromMap(map['noipSettings'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RouterDDNSSettings.fromJson(String source) =>
      RouterDDNSSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props =>
      [ddnsProvider, dynDNSSettings, tzoSettings, noIPSettings];
}
