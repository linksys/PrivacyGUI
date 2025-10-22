// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';

class RouterWANSettings extends Equatable {
  ///
  /// DHCP	A DHCP WAN connection.
  /// PPPoE	A DHCP PPPoE WAN connection.
  /// PPTP	A PPTP WAN connection.
  /// L2TP	A L2TP WAN connection.
  /// Telstra	A Telstra WAN connection.
  /// Static	A static IP WAN connection.
  /// Bridge	The router is in bridge mode.
  /// DSLite	A DS-Lite WAN connection.
  /// WirelessBridge	A Wireless Bridge mode connection.
  /// WirelessRepeater	A Wireless Bridge mode connection
  ///
  final String wanType;
  final PPPoESettings? pppoeSettings;
  final TPSettings? tpSettings;
  final TelstraSettings? telstraSettings;
  final StaticSettings? staticSettings;
  final BridgeSettings? bridgeSettings;
  final DSLiteSettings? dsliteSettings;
  final WirelessModeSettings? wirelessModeSettings;
  final String? domainName;
  final int mtu;
  final SinglePortVLANTaggingSettings? wanTaggingSettings;

  const RouterWANSettings({
    required this.wanType,
    this.pppoeSettings,
    this.tpSettings,
    this.telstraSettings,
    this.staticSettings,
    this.bridgeSettings,
    this.dsliteSettings,
    this.wirelessModeSettings,
    this.domainName,
    required this.mtu,
    this.wanTaggingSettings,
  });

  factory RouterWANSettings.dhcp(
      {required int mtu, SinglePortVLANTaggingSettings? wanTaggingSettings}) {
    return RouterWANSettings(
      wanType: 'DHCP',
      mtu: mtu,
      wanTaggingSettings: wanTaggingSettings,
    );
  }

  factory RouterWANSettings.pppoe(
      {required int mtu,
      required PPPoESettings pppoeSettings,
      required SinglePortVLANTaggingSettings wanTaggingSettings}) {
    return RouterWANSettings(
      wanType: 'PPPoE',
      mtu: mtu,
      pppoeSettings: pppoeSettings,
      wanTaggingSettings: wanTaggingSettings,
    );
  }

  factory RouterWANSettings.pptp(
      {required int mtu,
      required TPSettings tpSettings,
      required SinglePortVLANTaggingSettings wanTaggingSettings}) {
    return RouterWANSettings(
      wanType: 'PPTP',
      mtu: mtu,
      tpSettings: tpSettings,
      wanTaggingSettings: wanTaggingSettings,
    );
  }

  factory RouterWANSettings.l2tp(
      {required int mtu,
      required TPSettings tpSettings,
      SinglePortVLANTaggingSettings? wanTaggingSettings}) {
    return RouterWANSettings(
      wanType: 'L2TP',
      mtu: mtu,
      tpSettings: tpSettings,
      wanTaggingSettings: wanTaggingSettings,
    );
  }

  factory RouterWANSettings.static(
      {required int mtu,
      required StaticSettings staticSettings,
      required SinglePortVLANTaggingSettings wanTaggingSettings}) {
    return RouterWANSettings(
      wanType: 'Static',
      mtu: mtu,
      staticSettings: staticSettings,
      wanTaggingSettings: wanTaggingSettings,
    );
  }

  factory RouterWANSettings.bridge(
      {int mtu = 0,
      required BridgeSettings bridgeSettings,
      SinglePortVLANTaggingSettings? wanTaggingSettings}) {
    return RouterWANSettings(
      wanType: 'Bridge',
      mtu: mtu,
      bridgeSettings: bridgeSettings,
      wanTaggingSettings: wanTaggingSettings,
    );
  }

  RouterWANSettings copyWith({
    String? wanType,
    PPPoESettings? pppoeSettings,
    TPSettings? tpSettings,
    TelstraSettings? telstraSettings,
    StaticSettings? staticSettings,
    BridgeSettings? bridgeSettings,
    DSLiteSettings? dsliteSettings,
    WirelessModeSettings? wirelessModeSettings,
    String? domainName,
    int? mtu,
    SinglePortVLANTaggingSettings? wanTaggingSettings,
  }) {
    return RouterWANSettings(
      wanType: wanType ?? this.wanType,
      pppoeSettings: pppoeSettings ?? this.pppoeSettings,
      tpSettings: tpSettings ?? this.tpSettings,
      telstraSettings: telstraSettings ?? this.telstraSettings,
      staticSettings: staticSettings ?? this.staticSettings,
      bridgeSettings: bridgeSettings ?? this.bridgeSettings,
      dsliteSettings: dsliteSettings ?? this.dsliteSettings,
      wirelessModeSettings: wirelessModeSettings ?? this.wirelessModeSettings,
      domainName: domainName ?? this.domainName,
      mtu: mtu ?? this.mtu,
      wanTaggingSettings: wanTaggingSettings ?? this.wanTaggingSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wanType': wanType,
      'pppoeSettings': pppoeSettings,
      'tpSettings': tpSettings,
      'telstraSettings': telstraSettings,
      'staticSettings': staticSettings,
      'bridgeSettings': bridgeSettings,
      'dsliteSettings': dsliteSettings,
      'wirelessModeSettings': wirelessModeSettings,
      'domainName': domainName,
      'mtu': mtu,
      'wanTaggingSettings': wanTaggingSettings,
    }..removeWhere((key, value) => value == null);
  }

  factory RouterWANSettings.fromMap(Map<String, dynamic> map) {
    return RouterWANSettings(
      wanType: map['wanType'],
      pppoeSettings: map['pppoeSettings'] == null
          ? null
          : PPPoESettings.fromMap(map['pppoeSettings']),
      tpSettings: map['tpSettings'] == null
          ? null
          : TPSettings.fromMap(map['tpSettings']),
      telstraSettings: map['telstraSettings'] == null
          ? null
          : TelstraSettings.fromMap(map['telstraSettings']),
      staticSettings: map['staticSettings'] == null
          ? null
          : StaticSettings.fromMap(map['staticSettings']),
      bridgeSettings: map['bridgeSettings'] == null
          ? null
          : BridgeSettings.fromMap(map['bridgeSettings']),
      dsliteSettings: map['dsliteSettings'] == null
          ? null
          : DSLiteSettings.fromMap(map['dsliteSettings']),
      wirelessModeSettings: map['wirelessModeSettings'] == null
          ? null
          : WirelessModeSettings.fromMap(map['wirelessModeSettings']),
      domainName: map['domainName'],
      mtu: map['mtu'],
      wanTaggingSettings: map['wanTaggingSettings'] == null
          ? null
          : SinglePortVLANTaggingSettings.fromMap(map['wanTaggingSettings']),
    );
  }

  @override
  List<Object?> get props => [
        wanType,
        pppoeSettings,
        tpSettings,
        telstraSettings,
        staticSettings,
        bridgeSettings,
        dsliteSettings,
        wirelessModeSettings,
        domainName,
        mtu,
        wanTaggingSettings,
      ];

  String toJson() => jsonEncode(toMap());

  factory RouterWANSettings.fromJson(String source) =>
      RouterWANSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class StaticSettings {
  final String ipAddress;
  final int networkPrefixLength;
  final String gateway;
  final String dnsServer1;
  final String? dnsServer2;
  final String? dnsServer3;
  final String? domainName;

  const StaticSettings({
    required this.ipAddress,
    required this.networkPrefixLength,
    required this.gateway,
    required this.dnsServer1,
    this.dnsServer2,
    this.dnsServer3,
    this.domainName,
  });

  StaticSettings copyWith({
    String? ipAddress,
    int? networkPrefixLength,
    String? gateway,
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
    String? domainName,
  }) {
    return StaticSettings(
      ipAddress: ipAddress ?? this.ipAddress,
      networkPrefixLength: networkPrefixLength ?? this.networkPrefixLength,
      gateway: gateway ?? this.gateway,
      dnsServer1: dnsServer1 ?? this.dnsServer1,
      dnsServer2: dnsServer2 ?? this.dnsServer2,
      dnsServer3: dnsServer3 ?? this.dnsServer3,
      domainName: domainName ?? this.domainName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ipAddress': ipAddress,
      'networkPrefixLength': networkPrefixLength,
      'gateway': gateway,
      'dnsServer1': dnsServer1,
      'dnsServer2': dnsServer2,
      'dnsServer3': dnsServer3,
      'domainName': domainName,
    }..removeWhere((key, value) => value == null);
  }

  factory StaticSettings.fromMap(Map<String, dynamic> map) {
    return StaticSettings(
      ipAddress: map['ipAddress'],
      networkPrefixLength: map['networkPrefixLength'],
      gateway: map['gateway'],
      dnsServer1: map['dnsServer1'],
      dnsServer2: map['dnsServer2'],
      dnsServer3: map['dnsServer3'],
      domainName: map['domainName'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory StaticSettings.fromJson(String source) =>
      StaticSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class PPPoESettings {
  final String username;
  final String password;
  final String serviceName;

  // KeepAlive/ConnectOnDemand
  final String behavior;
  final int? maxIdleMinutes;
  final int? reconnectAfterSeconds;

  const PPPoESettings({
    required this.username,
    required this.password,
    required this.serviceName,
    required this.behavior,
    required this.maxIdleMinutes,
    required this.reconnectAfterSeconds,
  });

  PPPoESettings copyWith({
    String? username,
    String? password,
    String? serviceName,
    String? behavior,
    int? maxIdleMinutes,
    int? reconnectAfterSeconds,
  }) {
    return PPPoESettings(
      username: username ?? this.username,
      password: password ?? this.password,
      serviceName: serviceName ?? this.serviceName,
      behavior: behavior ?? this.behavior,
      maxIdleMinutes: maxIdleMinutes ?? this.maxIdleMinutes,
      reconnectAfterSeconds:
          reconnectAfterSeconds ?? this.reconnectAfterSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'serviceName': serviceName,
      'behavior': behavior,
      'maxIdleMinutes': maxIdleMinutes,
      'reconnectAfterSeconds': reconnectAfterSeconds,
    }..removeWhere((key, value) => value == null);
  }

  factory PPPoESettings.fromMap(Map<String, dynamic> map) {
    return PPPoESettings(
      username: map['username'],
      password: map['password'],
      serviceName: map['serviceName'],
      behavior: map['behavior'],
      maxIdleMinutes: map['maxIdleMinutes'],
      reconnectAfterSeconds: map['reconnectAfterSeconds'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PPPoESettings.fromJson(String source) =>
      PPPoESettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class TPSettings extends Equatable {
  final bool useStaticSettings;
  final StaticSettings? staticSettings;
  final String server;
  final String username;
  final String password;
  final String behavior;
  final int? maxIdleMinutes;
  final int? reconnectAfterSeconds;

  const TPSettings({
    required this.useStaticSettings,
    this.staticSettings,
    required this.server,
    required this.username,
    required this.password,
    required this.behavior,
    this.maxIdleMinutes,
    this.reconnectAfterSeconds,
  });

  TPSettings copyWith({
    bool? useStaticSettings,
    StaticSettings? staticSettings,
    String? server,
    String? username,
    String? password,
    String? behavior,
    int? maxIdleMinutes,
    int? reconnectAfterSeconds,
  }) {
    return TPSettings(
      useStaticSettings: useStaticSettings ?? this.useStaticSettings,
      staticSettings: staticSettings ?? this.staticSettings,
      server: server ?? this.server,
      username: username ?? this.username,
      password: password ?? this.password,
      behavior: behavior ?? this.behavior,
      maxIdleMinutes: maxIdleMinutes ?? this.maxIdleMinutes,
      reconnectAfterSeconds:
          reconnectAfterSeconds ?? this.reconnectAfterSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useStaticSettings': useStaticSettings,
      'staticSettings': staticSettings?.toMap(),
      'server': server,
      'username': username,
      'password': password,
      'behavior': behavior,
      'maxIdleMinutes': maxIdleMinutes,
      'reconnectAfterSeconds': reconnectAfterSeconds,
    }..removeWhere((key, value) => value == null);
  }

  factory TPSettings.fromMap(Map<String, dynamic> map) {
    return TPSettings(
      useStaticSettings: map['useStaticSettings'],
      staticSettings: map['staticSettings'] == null
          ? null
          : StaticSettings.fromMap(map['staticSettings']),
      server: map['server'],
      username: map['username'],
      password: map['password'],
      behavior: map['behavior'],
      maxIdleMinutes: map['maxIdleMinutes'],
      reconnectAfterSeconds: map['reconnectAfterSeconds'],
    );
  }

  @override
  List<Object?> get props => [
        useStaticSettings,
        staticSettings,
        server,
        username,
        password,
        behavior,
        maxIdleMinutes,
        reconnectAfterSeconds,
      ];

  String toJson() => jsonEncode(toMap());

  factory TPSettings.fromJson(String source) =>
      TPSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class TelstraSettings extends Equatable {
  final String server;
  final String username;
  final String password;

  const TelstraSettings({
    required this.server,
    required this.username,
    required this.password,
  });

  TelstraSettings copyWith({
    String? server,
    String? username,
    String? password,
  }) {
    return TelstraSettings(
      server: server ?? this.server,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'server': server,
      'username': username,
      'password': password,
    }..removeWhere((key, value) => value == null);
  }

  factory TelstraSettings.fromMap(Map<String, dynamic> map) {
    return TelstraSettings(
      server: map['server'],
      username: map['username'],
      password: map['password'],
    );
  }

  @override
  List<Object> get props => [server, username, password];

  String toJson() => jsonEncode(toMap());

  factory TelstraSettings.fromJson(String source) =>
      TelstraSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class BridgeSettings extends Equatable {
  final bool useStaticSettings;
  final StaticSettings? staticSettings;

  const BridgeSettings({
    required this.useStaticSettings,
    this.staticSettings,
  });

  BridgeSettings copyWith({
    bool? useStaticSettings,
    StaticSettings? staticSettings,
  }) {
    return BridgeSettings(
      useStaticSettings: useStaticSettings ?? this.useStaticSettings,
      staticSettings: staticSettings ?? this.staticSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useStaticSettings': useStaticSettings,
      'staticSettings': staticSettings,
    }..removeWhere((key, value) => value == null);
  }

  factory BridgeSettings.fromMap(Map<String, dynamic> map) {
    return BridgeSettings(
      useStaticSettings: map['useStaticSettings'],
      staticSettings: map['staticSettings'] == null
          ? null
          : StaticSettings.fromMap(map['staticSettings']),
    );
  }

  @override
  List<Object?> get props => [useStaticSettings, staticSettings];

  String toJson() => jsonEncode(toMap());

  factory BridgeSettings.fromJson(String source) =>
      BridgeSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class DSLiteSettings extends Equatable {
  final bool useManualSettings;
  final AFTRSettings? manualSettings;

  const DSLiteSettings({
    required this.useManualSettings,
    this.manualSettings,
  });

  DSLiteSettings copyWith({
    bool? useManualSettings,
    AFTRSettings? manualSettings,
  }) {
    return DSLiteSettings(
      useManualSettings: useManualSettings ?? this.useManualSettings,
      manualSettings: manualSettings ?? this.manualSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useManualSettings': useManualSettings,
      'manualSettings': manualSettings,
    }..removeWhere((key, value) => value == null);
  }

  factory DSLiteSettings.fromMap(Map<String, dynamic> map) {
    return DSLiteSettings(
      useManualSettings: map['useManualSettings'],
      manualSettings: map['manualSettings'] == null
          ? null
          : AFTRSettings.fromMap(map['manualSettings']),
    );
  }

  @override
  List<Object?> get props => [useManualSettings, manualSettings];

  String toJson() => jsonEncode(toMap());

  factory DSLiteSettings.fromJson(String source) =>
      DSLiteSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class WirelessModeSettings extends Equatable {
  final String ssid;
  final String? bssid;
  final String? band;
  final String security;
  final String password;

  const WirelessModeSettings({
    required this.ssid,
    this.bssid,
    this.band,
    required this.security,
    required this.password,
  });

  WirelessModeSettings copyWith({
    String? ssid,
    String? bssid,
    String? band,
    String? security,
    String? password,
  }) {
    return WirelessModeSettings(
      ssid: ssid ?? this.ssid,
      bssid: bssid ?? this.bssid,
      band: band ?? this.band,
      security: security ?? this.security,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ssid': ssid,
      'bssid': bssid,
      'band': band,
      'security': security,
      'password': password,
    }..removeWhere((key, value) => value == null);
  }

  factory WirelessModeSettings.fromMap(Map<String, dynamic> map) {
    return WirelessModeSettings(
      ssid: map['ssid'],
      bssid: map['bssid'],
      band: map['band'],
      security: map['security'],
      password: map['password'],
    );
  }

  @override
  List<Object?> get props => [ssid, bssid, band, security, password];

  String toJson() => jsonEncode(toMap());

  factory WirelessModeSettings.fromJson(String source) =>
      WirelessModeSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class AFTRSettings extends Equatable {
  final String? aftrURL;
  final String? afterAddress;

  const AFTRSettings({
    this.aftrURL,
    this.afterAddress,
  });

  AFTRSettings copyWith({
    String? aftrURL,
    String? afterAddress,
  }) {
    return AFTRSettings(
      aftrURL: aftrURL ?? this.aftrURL,
      afterAddress: afterAddress ?? this.afterAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aftrURL': aftrURL,
      'afterAddress': afterAddress,
    }..removeWhere((key, value) => value == null);
  }

  factory AFTRSettings.fromMap(Map<String, dynamic> map) {
    return AFTRSettings(
      aftrURL: map['aftrURL'],
      afterAddress: map['afterAddress'],
    );
  }

  @override
  List<Object?> get props => [aftrURL, afterAddress];

  String toJson() => jsonEncode(toMap());

  factory AFTRSettings.fromJson(String source) =>
      AFTRSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class SinglePortVLANTaggingSettings extends Equatable {
  final bool isEnabled;
  final PortTaggingSettings? vlanTaggingSettings;
  final int? vlanLowerLimit;
  final int? vlanUpperLimit;

  const SinglePortVLANTaggingSettings({
    required this.isEnabled,
    this.vlanTaggingSettings,
    this.vlanLowerLimit,
    this.vlanUpperLimit,
  });

  SinglePortVLANTaggingSettings copyWith({
    bool? isEnabled,
    PortTaggingSettings? vlanTaggingSettings,
    int? vlanLowerLimit,
    int? vlanUpperLimit,
  }) {
    return SinglePortVLANTaggingSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      vlanTaggingSettings: vlanTaggingSettings ?? this.vlanTaggingSettings,
      vlanLowerLimit: vlanLowerLimit ?? this.vlanLowerLimit,
      vlanUpperLimit: vlanUpperLimit ?? this.vlanUpperLimit,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isEnabled': isEnabled,
      'vlanTaggingSettings': vlanTaggingSettings?.toMap(),
      'vlanLowerLimit': vlanLowerLimit,
      'vlanUpperLimit': vlanUpperLimit,
    }..removeWhere((key, value) => value == null);
  }

  factory SinglePortVLANTaggingSettings.fromMap(Map<String, dynamic> map) {
    return SinglePortVLANTaggingSettings(
      isEnabled: map['isEnabled'],
      vlanTaggingSettings: map['vlanTaggingSettings'] != null
          ? PortTaggingSettings.fromMap(
              map['vlanTaggingSettings'] as Map<String, dynamic>)
          : null,
      vlanLowerLimit:
          map['vlanLowerLimit'] != null ? map['vlanLowerLimit'] as int : null,
      vlanUpperLimit:
          map['vlanUpperLimit'] != null ? map['vlanUpperLimit'] as int : null,
    );
  }

  @override
  List<Object?> get props =>
      [isEnabled, vlanTaggingSettings, vlanLowerLimit, vlanUpperLimit];

  String toJson() => jsonEncode(toMap());

  factory SinglePortVLANTaggingSettings.fromJson(String source) =>
      SinglePortVLANTaggingSettings.fromMap(
          jsonDecode(source) as Map<String, dynamic>);
}

class PortTaggingSettings extends Equatable {
  final int vlanID;
  final int? vlanPriority;

  ///
  /// Tagged/Untagged
  ///
  final String vlanStatus;

  const PortTaggingSettings({
    required this.vlanID,
    this.vlanPriority,
    required this.vlanStatus,
  });

  PortTaggingSettings copyWith({
    int? vlanID,
    int? vlanPriority,
    String? vlanStatus,
  }) {
    return PortTaggingSettings(
      vlanID: vlanID ?? this.vlanID,
      vlanPriority: vlanPriority ?? this.vlanPriority,
      vlanStatus: vlanStatus ?? this.vlanStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'vlanID': vlanID,
      'vlanPriority': vlanPriority,
      'vlanStatus': vlanStatus,
    }..removeWhere((key, value) => value == null);
  }

  factory PortTaggingSettings.fromMap(Map<String, dynamic> map) {
    return PortTaggingSettings(
      vlanID: map['vlanID'] as int,
      vlanPriority:
          map['vlanPriority'] != null ? map['vlanPriority'] as int : null,
      vlanStatus: map['vlanStatus'] as String,
    );
  }

  @override
  List<Object?> get props => [vlanID, vlanPriority, vlanStatus];

  String toJson() => jsonEncode(toMap());

  factory PortTaggingSettings.fromJson(String source) =>
      PortTaggingSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
