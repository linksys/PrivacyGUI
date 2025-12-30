import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/ipv4_settings_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/ipv6_settings_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/supported_wan_combination_ui_model.dart';

class InternetSettingsUIModel extends Equatable {
  final Ipv4SettingsUIModel ipv4Setting;
  final Ipv6SettingsUIModel ipv6Setting;
  // MAC Clone
  final bool macClone;
  final String? macCloneAddress;

  @override
  List<Object?> get props => [
        ipv4Setting,
        ipv6Setting,
        macClone,
        macCloneAddress,
      ];

  const InternetSettingsUIModel({
    required this.ipv4Setting,
    required this.ipv6Setting,
    required this.macClone,
    this.macCloneAddress,
  });

  factory InternetSettingsUIModel.init() {
    return const InternetSettingsUIModel(
      ipv4Setting: Ipv4SettingsUIModel(
        ipv4ConnectionType: '',
        mtu: 0,
      ),
      ipv6Setting: Ipv6SettingsUIModel(
        ipv6ConnectionType: '',
        isIPv6AutomaticEnabled: true,
      ),
      macClone: false,
      macCloneAddress: '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ipv4Setting': ipv4Setting.toMap(),
      'ipv6Setting': ipv6Setting.toMap(),
      'macClone': macClone,
      'macCloneAddress': macCloneAddress,
    }..removeWhere((key, value) => value == null);
  }

  factory InternetSettingsUIModel.fromMap(Map<String, dynamic> map) {
    return InternetSettingsUIModel(
      ipv4Setting: Ipv4SettingsUIModel.fromMap(
          map['ipv4Setting'] as Map<String, dynamic>),
      ipv6Setting: Ipv6SettingsUIModel.fromMap(
          map['ipv6Setting'] as Map<String, dynamic>),
      macClone: map['macClone'] as bool,
      macCloneAddress: map['macCloneAddress'] != null
          ? map['macCloneAddress'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory InternetSettingsUIModel.fromJson(String source) =>
      InternetSettingsUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  InternetSettingsUIModel copyWith({
    Ipv4SettingsUIModel? ipv4Setting,
    Ipv6SettingsUIModel? ipv6Setting,
    bool? macClone,
    ValueGetter<String?>? macCloneAddress,
  }) {
    return InternetSettingsUIModel(
      ipv4Setting: ipv4Setting ?? this.ipv4Setting,
      ipv6Setting: ipv6Setting ?? this.ipv6Setting,
      macClone: macClone ?? this.macClone,
      macCloneAddress:
          macCloneAddress != null ? macCloneAddress() : this.macCloneAddress,
    );
  }
}

class InternetSettingsStatusUIModel extends Equatable {
  final List<String> supportedIPv4ConnectionType;
  final List<SupportedWANCombinationUIModel> supportedWANCombinations;
  final List<String> supportedIPv6ConnectionType;
  final String duid;
  final String? redirection;
  final String? hostname;

  const InternetSettingsStatusUIModel({
    required this.supportedIPv4ConnectionType,
    required this.supportedWANCombinations,
    required this.supportedIPv6ConnectionType,
    required this.duid,
    this.redirection,
    this.hostname,
  });

  factory InternetSettingsStatusUIModel.init() {
    return const InternetSettingsStatusUIModel(
      supportedIPv4ConnectionType: [],
      supportedWANCombinations: [],
      supportedIPv6ConnectionType: [],
      duid: '',
      hostname: null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'supportedIPv4ConnectionType': supportedIPv4ConnectionType,
      'supportedWANCombinations':
          supportedWANCombinations.map((x) => x.toMap()).toList(),
      'supportedIPv6ConnectionType': supportedIPv6ConnectionType,
      'duid': duid,
      'redirection': redirection,
      'hostname': hostname,
    }..removeWhere((key, value) => value == null);
  }

  factory InternetSettingsStatusUIModel.fromMap(Map<String, dynamic> map) {
    return InternetSettingsStatusUIModel(
      supportedIPv4ConnectionType:
          List<String>.from(map['supportedIPv4ConnectionType']),
      supportedWANCombinations: List<SupportedWANCombinationUIModel>.from(
        map['supportedWANCombinations'].map(
          (x) => SupportedWANCombinationUIModel.fromMap(x),
        ),
      ),
      supportedIPv6ConnectionType:
          List<String>.from(map['supportedIPv6ConnectionType']),
      duid: map['duid'] as String,
      redirection:
          map['redirection'] != null ? map['redirection'] as String : null,
      hostname: map['hostname'] != null ? map['hostname'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory InternetSettingsStatusUIModel.fromJson(String source) =>
      InternetSettingsStatusUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        supportedIPv4ConnectionType,
        supportedWANCombinations,
        supportedIPv6ConnectionType,
        duid,
        redirection,
        hostname,
      ];

  InternetSettingsStatusUIModel copyWith({
    List<String>? supportedIPv4ConnectionType,
    List<SupportedWANCombinationUIModel>? supportedWANCombinations,
    List<String>? supportedIPv6ConnectionType,
    String? duid,
    ValueGetter<String?>? redirection,
    ValueGetter<String?>? hostname,
  }) {
    return InternetSettingsStatusUIModel(
      supportedIPv4ConnectionType:
          supportedIPv4ConnectionType ?? this.supportedIPv4ConnectionType,
      supportedWANCombinations:
          supportedWANCombinations ?? this.supportedWANCombinations,
      supportedIPv6ConnectionType:
          supportedIPv6ConnectionType ?? this.supportedIPv6ConnectionType,
      duid: duid ?? this.duid,
      redirection: redirection != null ? redirection() : this.redirection,
      hostname: hostname != null ? hostname() : this.hostname,
    );
  }

  @override
  bool get stringify => true;
}
