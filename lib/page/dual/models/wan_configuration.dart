import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';

// TODO Clone from [#InternetSettingsState], revisit when spec confirmed
class DualWANConfiguration extends Equatable {
  static const supportedWANConnectionType = ['DHCP', 'PPPoE', 'Static', 'PPTP'];
  final String wanType;
  final List<String> supportedWANType;
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

  const DualWANConfiguration({
    required this.wanType,
    required this.supportedWANType,
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
  });

  @override
  List<Object?> get props {
    return [
      wanType,
      supportedWANType,
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
    ];
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ipv4ConnectionType': wanType,
      'supportedIPv4ConnectionType': supportedWANType,
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
    }..removeWhere((key, value) => value == null);
  }

  factory DualWANConfiguration.fromMap(Map<String, dynamic> map) {
    return DualWANConfiguration(
      wanType: map['ipv4ConnectionType'],
      supportedWANType: List<String>.from(map['supportedIPv4ConnectionType']),
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
    );
  }

  String toJson() => json.encode(toMap());

  factory DualWANConfiguration.fromJson(String source) =>
      DualWANConfiguration.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  DualWANConfiguration copyWith({
    String? ipv4ConnectionType,
    List<String>? supportedIPv4ConnectionType,
    List<SupportedWANCombination>? supportedWANCombinations,
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
  }) {
    return DualWANConfiguration(
      wanType: ipv4ConnectionType ?? this.wanType,
      supportedWANType: supportedIPv4ConnectionType ?? this.supportedWANType,
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
    );
  }

  factory DualWANConfiguration.fromData(DualWANSettingsData data) {
    final wanType = data.wanType;
    return switch (wanType) {
      'DHCP' => DualWANConfiguration(
          wanType: wanType,
          supportedWANType: supportedWANConnectionType,
          mtu: 0,
        ),
      'PPPoE' => DualWANConfiguration(
          wanType: wanType,
          supportedWANType: supportedWANConnectionType,
          mtu: 0,
          behavior: PPPConnectionBehavior.resolve(data.pppoeSettings?.behavior),
          maxIdleMinutes: data.pppoeSettings?.maxIdleMinutes,
          reconnectAfterSeconds: data.pppoeSettings?.reconnectAfterSeconds,
          username: data.pppoeSettings?.username,
          password: data.pppoeSettings?.password,
          serviceName: data.pppoeSettings?.serviceName,
        ),
      'Static' => DualWANConfiguration(
          wanType: wanType,
          supportedWANType: supportedWANConnectionType,
          mtu: 0,
          staticIpAddress: data.staticSettings?.ipAddress,
          staticGateway: data.staticSettings?.gateway,
          staticDns1: data.staticSettings?.dnsServer1,
          staticDns2: data.staticSettings?.dnsServer2,
          staticDns3: data.staticSettings?.dnsServer3,
          networkPrefixLength: data.staticSettings?.networkPrefixLength,
        ),
      'PPTP' => DualWANConfiguration(
          wanType: wanType,
          supportedWANType: supportedWANConnectionType,
          mtu: 0,
          behavior: PPPConnectionBehavior.resolve(data.tpSettings?.behavior),
          maxIdleMinutes: data.tpSettings?.maxIdleMinutes,
          reconnectAfterSeconds: data.tpSettings?.reconnectAfterSeconds,
          username: data.tpSettings?.username,
          password: data.tpSettings?.password,
          serverIp: data.tpSettings?.server,
          useStaticSettings: data.tpSettings?.useStaticSettings,
        ),
      _ => DualWANConfiguration(
          wanType: wanType,
          supportedWANType: supportedWANConnectionType,
          mtu: 0,
        ),
    };
  }
  DualWANSettingsData toData() {
    return switch (wanType) {
      'DHCP' => DualWANSettingsData(
          wanType: wanType,
        ),
      'PPPoE' => DualWANSettingsData(
          wanType: wanType,
          pppoeSettings: PPPoESettings(
            behavior: behavior?.value ?? PPPConnectionBehavior.keepAlive.value,
            maxIdleMinutes: maxIdleMinutes,
            reconnectAfterSeconds: reconnectAfterSeconds,
            username: username ?? '',
            password: password ?? '',
            serviceName: serviceName ?? '',
          ),
        ),
      'Static' => DualWANSettingsData(
          wanType: wanType,
          staticSettings: StaticSettings(
            ipAddress: staticIpAddress ?? '',
            gateway: staticGateway ?? '',
            dnsServer1: staticDns1 ?? '',
            dnsServer2: staticDns2 ?? '',
            dnsServer3: staticDns3 ?? '',
            networkPrefixLength: networkPrefixLength ?? 24,
          ),
        ),
      'PPTP' => DualWANSettingsData(
          wanType: wanType,
          tpSettings: TPSettings(
            behavior: behavior?.value ?? PPPConnectionBehavior.keepAlive.value,
            maxIdleMinutes: maxIdleMinutes,
            reconnectAfterSeconds: reconnectAfterSeconds,
            username: username ?? '',
            password: password ?? '',
            server: serverIp ?? '',
            useStaticSettings: useStaticSettings ?? false,
          ),
        ),
      _ => DualWANSettingsData(
          wanType: wanType,
        ),
    };
  }
}
