import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';

class Ipv4SettingsUIModel extends Equatable {
  final String ipv4ConnectionType;
  final int mtu;
  // PPPConnection
  final PPPConnectionBehavior? behavior;
  final int? maxIdleMinutes;
  final int? reconnectAfterSeconds;
  // Static Settings
  final String? staticIpAddress;
  final String? staticGateway;
  final String? staticDns1;
  final String? staticDns2;
  final String? staticDns3;
  final int? networkPrefixLength;
  final String? domainName;
  // PPPoE & TP (PPTP/L2TP) Settings
  final String? username;
  final String? password;
  final String? serviceName;
  final String? serverIp;
  final bool? useStaticSettings;
  // Wan Tagging Settings
  final bool? wanTaggingSettingsEnable;
  final int? vlanId;

  const Ipv4SettingsUIModel({
    required this.ipv4ConnectionType,
    required this.mtu,
    this.behavior,
    this.maxIdleMinutes,
    this.reconnectAfterSeconds,
    this.staticIpAddress,
    this.staticGateway,
    this.staticDns1,
    this.staticDns2,
    this.staticDns3,
    this.networkPrefixLength,
    this.domainName,
    this.username,
    this.password,
    this.serviceName,
    this.serverIp,
    this.useStaticSettings,
    this.wanTaggingSettingsEnable,
    this.vlanId,
  });

  @override
  List<Object?> get props {
    return [
      ipv4ConnectionType,
      mtu,
      behavior,
      maxIdleMinutes,
      reconnectAfterSeconds,
      staticIpAddress,
      staticGateway,
      staticDns1,
      staticDns2,
      staticDns3,
      networkPrefixLength,
      domainName,
      username,
      password,
      serviceName,
      serverIp,
      useStaticSettings,
      wanTaggingSettingsEnable,
      vlanId,
    ];
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ipv4ConnectionType': ipv4ConnectionType,
      'mtu': mtu,
      'behavior': behavior?.value,
      'maxIdleMinutes': maxIdleMinutes,
      'reconnectAfterSeconds': reconnectAfterSeconds,
      'staticIpAddress': staticIpAddress,
      'staticGateway': staticGateway,
      'staticDns1': staticDns1,
      'staticDns2': staticDns2,
      'staticDns3': staticDns3,
      'networkPrefixLength': networkPrefixLength,
      'domainName': domainName,
      'username': username,
      'password': password,
      'serviceName': serviceName,
      'serverIp': serverIp,
      'useStaticSettings': useStaticSettings,
      'wanTaggingSettingsEnable': wanTaggingSettingsEnable,
      'vlanId': vlanId,
    }..removeWhere((key, value) => value == null);
  }

  factory Ipv4SettingsUIModel.fromMap(Map<String, dynamic> map) {
    return Ipv4SettingsUIModel(
      ipv4ConnectionType: map['ipv4ConnectionType'],
      mtu: map['mtu'] as int,
      behavior: PPPConnectionBehavior.resolve(map['behavior']),
      maxIdleMinutes:
          map['maxIdleMinutes'] != null ? map['maxIdleMinutes'] as int : null,
      reconnectAfterSeconds: map['reconnectAfterSeconds'] != null
          ? map['reconnectAfterSeconds'] as int
          : null,
      staticIpAddress: map['staticIpAddress'] != null
          ? map['staticIpAddress'] as String
          : null,
      staticGateway:
          map['staticGateway'] != null ? map['staticGateway'] as String : null,
      staticDns1:
          map['staticDns1'] != null ? map['staticDns1'] as String : null,
      staticDns2:
          map['staticDns2'] != null ? map['staticDns2'] as String : null,
      staticDns3:
          map['staticDns3'] != null ? map['staticDns3'] as String : null,
      networkPrefixLength: map['networkPrefixLength'],
      domainName: map['domainName'],
      username: map['username'] != null ? map['username'] as String : null,
      password: map['password'] != null ? map['password'] as String : null,
      serviceName:
          map['serviceName'] != null ? map['serviceName'] as String : null,
      serverIp: map['serverIp'] != null ? map['serverIp'] as String : null,
      useStaticSettings: map['useStaticSettings'] != null
          ? map['useStaticSettings'] as bool
          : null,
      wanTaggingSettingsEnable: map['wanTaggingSettingsEnable'] != null
          ? map['wanTaggingSettingsEnable'] as bool
          : null,
      vlanId: map['vlanId'] != null ? map['vlanId'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Ipv4SettingsUIModel.fromJson(String source) =>
      Ipv4SettingsUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  Ipv4SettingsUIModel copyWith({
    String? ipv4ConnectionType,
    int? mtu,
    ValueGetter<PPPConnectionBehavior?>? behavior,
    ValueGetter<int?>? maxIdleMinutes,
    ValueGetter<int?>? reconnectAfterSeconds,
    ValueGetter<String?>? staticIpAddress,
    ValueGetter<String?>? staticGateway,
    ValueGetter<String?>? staticDns1,
    ValueGetter<String?>? staticDns2,
    ValueGetter<String?>? staticDns3,
    ValueGetter<int?>? networkPrefixLength,
    ValueGetter<String?>? domainName,
    ValueGetter<String?>? username,
    ValueGetter<String?>? password,
    ValueGetter<String?>? serviceName,
    ValueGetter<String?>? serverIp,
    ValueGetter<bool?>? useStaticSettings,
    ValueGetter<bool?>? wanTaggingSettingsEnable,
    ValueGetter<int?>? vlanId,
  }) {
    return Ipv4SettingsUIModel(
      ipv4ConnectionType: ipv4ConnectionType ?? this.ipv4ConnectionType,
      mtu: mtu ?? this.mtu,
      behavior: behavior != null ? behavior() : this.behavior,
      maxIdleMinutes:
          maxIdleMinutes != null ? maxIdleMinutes() : this.maxIdleMinutes,
      reconnectAfterSeconds: reconnectAfterSeconds != null
          ? reconnectAfterSeconds()
          : this.reconnectAfterSeconds,
      staticIpAddress:
          staticIpAddress != null ? staticIpAddress() : this.staticIpAddress,
      staticGateway:
          staticGateway != null ? staticGateway() : this.staticGateway,
      staticDns1: staticDns1 != null ? staticDns1() : this.staticDns1,
      staticDns2: staticDns2 != null ? staticDns2() : this.staticDns2,
      staticDns3: staticDns3 != null ? staticDns3() : this.staticDns3,
      networkPrefixLength: networkPrefixLength != null
          ? networkPrefixLength()
          : this.networkPrefixLength,
      domainName: domainName != null ? domainName() : this.domainName,
      username: username != null ? username() : this.username,
      password: password != null ? password() : this.password,
      serviceName: serviceName != null ? serviceName() : this.serviceName,
      serverIp: serverIp != null ? serverIp() : this.serverIp,
      useStaticSettings: useStaticSettings != null
          ? useStaticSettings()
          : this.useStaticSettings,
      wanTaggingSettingsEnable: wanTaggingSettingsEnable != null
          ? wanTaggingSettingsEnable()
          : this.wanTaggingSettingsEnable,
      vlanId: vlanId != null ? vlanId() : this.vlanId,
    );
  }
}
