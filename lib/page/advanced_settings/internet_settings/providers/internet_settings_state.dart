// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import 'package:linksys_app/core/jnap/models/wan_status.dart';

enum WanType {
  dhcp(type: 'DHCP'),
  pppoe(type: 'PPPoE'),
  pptp(type: 'PPTP'),
  l2tp(type: 'L2TP'),
  telstra(type: 'Telstra'),
  dsLite(type: 'DSLite'),
  static(type: 'Static'),
  bridge(type: 'Bridge'),
  wirelessBridge(type: 'WirelessBridge'),
  wirelessRepeater(type: 'WirelessRepeater'),
  ;

  const WanType({required this.type});

  final String type;

  static WanType? resolve(String type) {
    return WanType.values.firstWhereOrNull((element) => element.type == type);
  }
}

enum WanIPv6Type {
  automatic(type: 'Automatic'),
  static(type: 'Static'),
  bridge(type: 'Bridge'),
  sixRdTunnel(type: '6rd Tunnel'),
  slaac(type: 'SLAAC'),
  dhcpv6(type: 'DHCPv6'),
  pppoe(type: 'PPPoE'),
  passThrough(type: 'Pass-through'),
  ;

  const WanIPv6Type({required this.type});

  final String type;

  static WanIPv6Type? resolve(String type) {
    return WanIPv6Type.values
        .firstWhereOrNull((element) => element.type == type);
  }
}

enum IPv6rdTunnelMode {
  disabled(value: 'Disabled'),
  automatic(value: 'Automatic'),
  manual(value: 'Manual'),
  ;

  const IPv6rdTunnelMode({required this.value});

  final String value;

  static IPv6rdTunnelMode? resolve(String value) {
    return IPv6rdTunnelMode.values
        .firstWhereOrNull((element) => element.value == value);
  }
}

enum TaggingStatus {
  tagged(value: 'Tagged'),
  untagged(value: 'Untagged'),
  ;

  const TaggingStatus({required this.value});

  final String value;

  static TaggingStatus? resolve(String value) {
    return TaggingStatus.values
        .firstWhereOrNull((element) => element.value == value);
  }
}

enum PPPConnectionBehavior {
  connectOnDemand(value: 'ConnectOnDemand'),
  keepAlive(value: 'KeepAlive'),
  ;

  const PPPConnectionBehavior({required this.value});

  final String value;

  static PPPConnectionBehavior? resolve(String value) {
    return PPPConnectionBehavior.values
        .firstWhereOrNull((element) => element.value == value);
  }
}

class InternetSettingsState extends Equatable {
  final Ipv4Setting ipv4Setting;
  final Ipv6Setting ipv6Setting;
  // MAC Clone
  final bool macClone;
  final String? macCloneAddress;

  @override
  List<Object?> get props =>
      [ipv4Setting, ipv6Setting, macClone, macCloneAddress];

  const InternetSettingsState({
    required this.ipv4Setting,
    required this.ipv6Setting,
    required this.macClone,
    this.macCloneAddress,
  });

  factory InternetSettingsState.init() {
    return const InternetSettingsState(
      ipv4Setting: Ipv4Setting(
        ipv4ConnectionType: '',
        supportedIPv4ConnectionType: [],
        supportedWANCombinations: [],
        mtu: 0,
      ),
      ipv6Setting: Ipv6Setting(
        ipv6ConnectionType: '',
        supportedIPv6ConnectionType: [],
        duid: '',
        isIPv6AutomaticEnabled: true,
      ),
      macClone: false,
      macCloneAddress: '',
    );
  }

  InternetSettingsState copyWith({
    Ipv4Setting? ipv4Setting,
    Ipv6Setting? ipv6Setting,
    bool? macClone,
    String? macCloneAddress,
  }) {
    return InternetSettingsState(
      ipv4Setting: ipv4Setting ?? this.ipv4Setting,
      ipv6Setting: ipv6Setting ?? this.ipv6Setting,
      macClone: macClone ?? this.macClone,
      macCloneAddress: macCloneAddress ?? this.macCloneAddress,
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

  factory InternetSettingsState.fromMap(Map<String, dynamic> map) {
    return InternetSettingsState(
      ipv4Setting:
          Ipv4Setting.fromMap(map['ipv4Setting'] as Map<String, dynamic>),
      ipv6Setting:
          Ipv6Setting.fromMap(map['ipv6Setting'] as Map<String, dynamic>),
      macClone: map['macClone'] as bool,
      macCloneAddress: map['macCloneAddress'] != null
          ? map['macCloneAddress'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory InternetSettingsState.fromJson(String source) =>
      InternetSettingsState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class Ipv4Setting extends Equatable {
  final String ipv4ConnectionType;
  final List<String> supportedIPv4ConnectionType;
  final List<SupportedWANCombination> supportedWANCombinations;
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
  // PPPoE & TP (PPTP/L2TP) Settings
  final String? username;
  final String? password;
  final String? serviceName;
  final String? serverIp;
  final bool? useStaticSettings;
  // Brigde
  final String? redirection;
  // Wan Tagging Settings
  final bool? wanTaggingSettingsEnable;
  final int? vlanId;

  const Ipv4Setting({
    required this.ipv4ConnectionType,
    required this.supportedIPv4ConnectionType,
    required this.supportedWANCombinations,
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
    this.username,
    this.password,
    this.serviceName,
    this.serverIp,
    this.useStaticSettings,
    this.redirection,
    this.wanTaggingSettingsEnable,
    this.vlanId,
  });

  @override
  List<Object?> get props {
    return [
      ipv4ConnectionType,
      supportedIPv4ConnectionType,
      supportedWANCombinations,
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
      username,
      password,
      serviceName,
      serverIp,
      useStaticSettings,
      redirection,
      wanTaggingSettingsEnable,
      vlanId,
    ];
  }

  Ipv4Setting copyWith({
    String? ipv4ConnectionType,
    List<String>? supportedIPv4ConnectionType,
    List<SupportedWANCombination>? supportedWANCombinations,
    int? mtu,
    PPPConnectionBehavior? behavior,
    int? maxIdleMinutes,
    int? reconnectAfterSeconds,
    String? staticIpAddress,
    String? staticGateway,
    String? staticDns1,
    String? staticDns2,
    String? staticDns3,
    int? networkPrefixLength,
    String? username,
    String? password,
    String? serviceName,
    String? serverIp,
    bool? useStaticSettings,
    String? redirection,
    bool? wanTaggingSettingsEnable,
    int? vlanId,
  }) {
    return Ipv4Setting(
      ipv4ConnectionType: ipv4ConnectionType ?? this.ipv4ConnectionType,
      supportedIPv4ConnectionType:
          supportedIPv4ConnectionType ?? this.supportedIPv4ConnectionType,
      supportedWANCombinations:
          supportedWANCombinations ?? this.supportedWANCombinations,
      mtu: mtu ?? this.mtu,
      behavior: behavior ?? this.behavior,
      maxIdleMinutes: maxIdleMinutes ?? this.maxIdleMinutes,
      reconnectAfterSeconds:
          reconnectAfterSeconds ?? this.reconnectAfterSeconds,
      staticIpAddress: staticIpAddress ?? this.staticIpAddress,
      staticGateway: staticGateway ?? this.staticGateway,
      staticDns1: staticDns1 ?? this.staticDns1,
      staticDns2: staticDns2 ?? this.staticDns2,
      staticDns3: staticDns3 ?? this.staticDns3,
      networkPrefixLength: networkPrefixLength ?? this.networkPrefixLength,
      username: username ?? this.username,
      password: password ?? this.password,
      serviceName: serviceName ?? this.serviceName,
      serverIp: serverIp ?? this.serverIp,
      useStaticSettings: useStaticSettings ?? this.useStaticSettings,
      redirection: redirection ?? this.redirection,
      wanTaggingSettingsEnable:
          wanTaggingSettingsEnable ?? this.wanTaggingSettingsEnable,
      vlanId: vlanId ?? this.vlanId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ipv4ConnectionType': ipv4ConnectionType,
      'supportedIPv4ConnectionType': supportedIPv4ConnectionType,
      'supportedWANCombinations':
          supportedWANCombinations.map((x) => x.toMap()).toList(),
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
      'username': username,
      'password': password,
      'serviceName': serviceName,
      'serverIp': serverIp,
      'useStaticSettings': useStaticSettings,
      'redirection': redirection,
      'wanTaggingSettingsEnable': wanTaggingSettingsEnable,
      'vlanId': vlanId,
    }..removeWhere((key, value) => value == null);
  }

  factory Ipv4Setting.fromMap(Map<String, dynamic> map) {
    return Ipv4Setting(
      ipv4ConnectionType: map['ipv4ConnectionType'],
      supportedIPv4ConnectionType:
          List<String>.from(map['supportedIPv4ConnectionType']),
      supportedWANCombinations: List<SupportedWANCombination>.from(
        map['supportedWANCombinations'].map(
          (x) => SupportedWANCombination.fromMap(x),
        ),
      ),
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
      username: map['username'] != null ? map['username'] as String : null,
      password: map['password'] != null ? map['password'] as String : null,
      serviceName:
          map['serviceName'] != null ? map['serviceName'] as String : null,
      serverIp: map['serverIp'] != null ? map['serverIp'] as String : null,
      useStaticSettings: map['useStaticSettings'] != null
          ? map['useStaticSettings'] as bool
          : null,
      redirection:
          map['redirection'] != null ? map['redirection'] as String : null,
      wanTaggingSettingsEnable: map['wanTaggingSettingsEnable'] != null
          ? map['wanTaggingSettingsEnable'] as bool
          : null,
      vlanId: map['vlanId'] != null ? map['vlanId'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Ipv4Setting.fromJson(String source) =>
      Ipv4Setting.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class Ipv6Setting extends Equatable {
  final String ipv6ConnectionType;
  final List<String> supportedIPv6ConnectionType;
  // IPv6
  final String duid;
  final bool isIPv6AutomaticEnabled;
  final IPv6rdTunnelMode? ipv6rdTunnelMode;
  final String? ipv6Prefix;
  final int? ipv6PrefixLength;
  final String? ipv6BorderRelay;
  final int? ipv6BorderRelayPrefixLength;

  const Ipv6Setting({
    required this.ipv6ConnectionType,
    required this.supportedIPv6ConnectionType,
    required this.duid,
    required this.isIPv6AutomaticEnabled,
    this.ipv6rdTunnelMode,
    this.ipv6Prefix,
    this.ipv6PrefixLength,
    this.ipv6BorderRelay,
    this.ipv6BorderRelayPrefixLength,
  });

  Ipv6Setting copyWith({
    String? ipv6ConnectionType,
    List<String>? supportedIPv6ConnectionType,
    String? duid,
    bool? isIPv6AutomaticEnabled,
    IPv6rdTunnelMode? ipv6rdTunnelMode,
    String? ipv6Prefix,
    int? ipv6PrefixLength,
    String? ipv6BorderRelay,
    int? ipv6BorderRelayPrefixLength,
  }) {
    return Ipv6Setting(
      ipv6ConnectionType: ipv6ConnectionType ?? this.ipv6ConnectionType,
      supportedIPv6ConnectionType:
          supportedIPv6ConnectionType ?? this.supportedIPv6ConnectionType,
      duid: duid ?? this.duid,
      isIPv6AutomaticEnabled:
          isIPv6AutomaticEnabled ?? this.isIPv6AutomaticEnabled,
      ipv6rdTunnelMode: ipv6rdTunnelMode ?? this.ipv6rdTunnelMode,
      ipv6Prefix: ipv6Prefix ?? this.ipv6Prefix,
      ipv6PrefixLength: ipv6PrefixLength ?? this.ipv6PrefixLength,
      ipv6BorderRelay: ipv6BorderRelay ?? this.ipv6BorderRelay,
      ipv6BorderRelayPrefixLength:
          ipv6BorderRelayPrefixLength ?? this.ipv6BorderRelayPrefixLength,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ipv6ConnectionType': ipv6ConnectionType,
      'supportedIPv6ConnectionType': supportedIPv6ConnectionType,
      'duid': duid,
      'isIPv6AutomaticEnabled': isIPv6AutomaticEnabled,
      'ipv6rdTunnelMode': ipv6rdTunnelMode?.value,
      'ipv6Prefix': ipv6Prefix,
      'ipv6PrefixLength': ipv6PrefixLength,
      'ipv6BorderRelay': ipv6BorderRelay,
      'ipv6BorderRelayPrefixLength': ipv6BorderRelayPrefixLength,
    }..removeWhere((key, value) => value == null);
  }

  factory Ipv6Setting.fromMap(Map<String, dynamic> map) {
    return Ipv6Setting(
      ipv6ConnectionType: map['ipv6ConnectionType'] as String,
      supportedIPv6ConnectionType:
          List<String>.from(map['supportedIPv6ConnectionType']),
      duid: map['duid'] as String,
      isIPv6AutomaticEnabled: map['isIPv6AutomaticEnabled'] as bool,
      ipv6rdTunnelMode: map['ipv6rdTunnelMode'] != null
          ? IPv6rdTunnelMode.resolve(map['ipv6rdTunnelMode'])
          : null,
      ipv6Prefix:
          map['ipv6Prefix'] != null ? map['ipv6Prefix'] as String : null,
      ipv6PrefixLength: map['ipv6PrefixLength'] != null
          ? map['ipv6PrefixLength'] as int
          : null,
      ipv6BorderRelay: map['ipv6BorderRelay'] != null
          ? map['ipv6BorderRelay'] as String
          : null,
      ipv6BorderRelayPrefixLength: map['ipv6BorderRelayPrefixLength'] != null
          ? map['ipv6BorderRelayPrefixLength'] as int
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Ipv6Setting.fromJson(String source) =>
      Ipv6Setting.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      ipv6ConnectionType,
      supportedIPv6ConnectionType,
      duid,
      isIPv6AutomaticEnabled,
      ipv6rdTunnelMode,
      ipv6Prefix,
      ipv6PrefixLength,
      ipv6BorderRelay,
      ipv6BorderRelayPrefixLength,
    ];
  }
}
