import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/jnap/models/dual_wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';

const defaultMaxIdleMinutes = 15;
const defaultReconnectAfterSeconds = 30;

// TODO Clone from [#InternetSettingsState], revisit when spec confirmed
class DualWANConfiguration extends Equatable {
  final String wanType;
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
      'wanType': wanType,
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
      wanType: map['wanType'],
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
    String? wanType,
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
      wanType: wanType ?? this.wanType,
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
          mtu: data.mtu,
        ),
      'PPPoE' => DualWANConfiguration(
          wanType: wanType,
          mtu: data.mtu,
          behavior: PPPConnectionBehavior.resolve(data.pppoeSettings?.behavior),
          maxIdleMinutes: data.pppoeSettings?.maxIdleMinutes,
          reconnectAfterSeconds: data.pppoeSettings?.reconnectAfterSeconds,
          username: data.pppoeSettings?.username,
          password: data.pppoeSettings?.password,
          serviceName: data.pppoeSettings?.serviceName,
        ),
      'Static' => DualWANConfiguration(
          wanType: wanType,
          mtu: data.mtu,
          staticIpAddress: data.staticSettings?.ipAddress,
          staticGateway: data.staticSettings?.gateway,
          staticDns1: data.staticSettings?.dnsServer1,
          staticDns2: data.staticSettings?.dnsServer2,
          staticDns3: data.staticSettings?.dnsServer3,
          networkPrefixLength: data.staticSettings?.networkPrefixLength,
        ),
      'PPTP' => DualWANConfiguration(
          wanType: wanType,
          mtu: data.mtu,
          behavior: PPPConnectionBehavior.resolve(data.tpSettings?.behavior),
          maxIdleMinutes: data.tpSettings?.maxIdleMinutes,
          reconnectAfterSeconds: data.tpSettings?.reconnectAfterSeconds,
          username: data.tpSettings?.username,
          password: data.tpSettings?.password,
          serverIp: data.tpSettings?.server,
          useStaticSettings: data.tpSettings?.useStaticSettings,
        ),
      'L2TP' => DualWANConfiguration(
          wanType: wanType,
          mtu: data.mtu,
          behavior: PPPConnectionBehavior.resolve(data.tpSettings?.behavior),
          maxIdleMinutes: data.tpSettings?.maxIdleMinutes,
          reconnectAfterSeconds: data.tpSettings?.reconnectAfterSeconds,
          username: data.tpSettings?.username,
          password: data.tpSettings?.password,
          serverIp: data.tpSettings?.server,
          useStaticSettings: data.tpSettings?.useStaticSettings,
          staticIpAddress: data.tpSettings?.staticSettings?.ipAddress,
          staticGateway: data.tpSettings?.staticSettings?.gateway,
          staticDns1: data.tpSettings?.staticSettings?.dnsServer1,
          staticDns2: data.tpSettings?.staticSettings?.dnsServer2,
          staticDns3: data.tpSettings?.staticSettings?.dnsServer3,
          networkPrefixLength:
              data.tpSettings?.staticSettings?.networkPrefixLength,
        ),
      _ => DualWANConfiguration(
          wanType: wanType,
          mtu: data.mtu,
        ),
    };
  }
  DualWANSettingsData toData() {
    return switch (wanType) {
      'DHCP' => DualWANSettingsData(
          wanType: wanType,
          mtu: mtu,
        ),
      'PPPoE' => DualWANSettingsData(
          wanType: wanType,
          mtu: mtu,
          pppoeSettings: PPPoESettings(
            behavior: behavior?.value ?? PPPConnectionBehavior.keepAlive.value,
            maxIdleMinutes:
                maxIdleMinutes ?? getDefaultMaxIdleMinutes(behavior),
            reconnectAfterSeconds: reconnectAfterSeconds ??
                getDefaultReconnectAfterSeconds(behavior),
            username: username ?? '',
            password: password ?? '',
            serviceName: serviceName ?? '',
          ),
        ),
      'Static' => DualWANSettingsData(
          wanType: wanType,
          mtu: mtu,
          staticSettings: StaticSettings(
            ipAddress: staticIpAddress ?? '',
            gateway: staticGateway ?? '',
            dnsServer1: staticDns1 ?? '',
            dnsServer2: staticDns2,
            dnsServer3: staticDns3,
            networkPrefixLength: networkPrefixLength ?? 24,
          ),
        ),
      'PPTP' => DualWANSettingsData(
          wanType: wanType,
          mtu: mtu,
          tpSettings: TPSettings(
            behavior: behavior?.value ?? PPPConnectionBehavior.keepAlive.value,
            maxIdleMinutes:
                maxIdleMinutes ?? getDefaultMaxIdleMinutes(behavior),
            reconnectAfterSeconds: reconnectAfterSeconds ??
                getDefaultReconnectAfterSeconds(behavior),
            username: username ?? '',
            password: password ?? '',
            server: serverIp ?? '',
            useStaticSettings: useStaticSettings ?? false,
            staticSettings: (useStaticSettings ?? false) ? StaticSettings(
              ipAddress: staticIpAddress ?? '',
              networkPrefixLength: networkPrefixLength ?? 24,
              gateway: staticGateway ?? '',
              dnsServer1: staticDns1 ?? '',
              dnsServer2: staticDns2,
              dnsServer3: staticDns3,
              domainName: domainName,
            ) : null,
          ),
        ),
      'L2TP' => DualWANSettingsData(
          wanType: wanType,
          mtu: mtu,
          tpSettings: TPSettings(
            behavior: behavior?.value ?? PPPConnectionBehavior.keepAlive.value,
            maxIdleMinutes:
                maxIdleMinutes ?? getDefaultMaxIdleMinutes(behavior),
            reconnectAfterSeconds: reconnectAfterSeconds ??
                getDefaultReconnectAfterSeconds(behavior),
            username: username ?? '',
            password: password ?? '',
            server: serverIp ?? '',
            useStaticSettings: useStaticSettings ?? false,
          ),
        ),
      _ => DualWANSettingsData(
          wanType: wanType,
          mtu: mtu,
        ),
    };
  }

  int? getDefaultMaxIdleMinutes(PPPConnectionBehavior? behavior) {
    return switch (behavior ?? PPPConnectionBehavior.keepAlive) {
      PPPConnectionBehavior.keepAlive => null,
      PPPConnectionBehavior.connectOnDemand => defaultMaxIdleMinutes,
    };
  }

  int? getDefaultReconnectAfterSeconds(PPPConnectionBehavior? behavior) {
    return switch (behavior ?? PPPConnectionBehavior.keepAlive) {
      PPPConnectionBehavior.keepAlive => defaultReconnectAfterSeconds,
      PPPConnectionBehavior.connectOnDemand => null,
    };
  }

  // Check current WAN configuration depends on WAN type is valid
  bool get isCurrentWANConfigurationValid {
    return switch (wanType) {
      'DHCP' => true,
      'PPPoE' => _checkEmpty(username) && _checkEmpty(password),
      'Static' => _checkEmpty(staticIpAddress) &&
          _checkEmpty(staticGateway) &&
          _checkEmpty(staticDns1) &&
          _checkEmpty(networkPrefixLength),
      'PPTP' => _checkEmpty(username) &&
          _checkEmpty(password) &&
          _checkEmpty(serverIp) &&
          (useStaticSettings != true ||
              (_checkEmpty(staticIpAddress) &&
                  _checkEmpty(staticGateway) &&
                  _checkEmpty(staticDns1) &&
                  _checkEmpty(networkPrefixLength))),
      'L2TP' =>
        _checkEmpty(username) && _checkEmpty(password) && _checkEmpty(serverIp),
      _ => false,
    };
  }

  bool _checkEmpty(Object? value) {
    if (value == null) {
      return false;
    }
    if (value is String) {
      return value.isNotEmpty;
    }
    return true;
  }
}
