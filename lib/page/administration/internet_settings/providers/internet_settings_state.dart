// ignore_for_file: public_member_api_docs, sort_constructors_first

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
    return WanIPv6Type.values.firstWhereOrNull((element) => element.type == type);
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
    return IPv6rdTunnelMode.values.firstWhereOrNull((element) => element.value == value);
  }
}

enum TaggingStatus {
  tagged(value: 'Tagged'),
  untagged(value: 'Untagged'),
  ;

  const TaggingStatus({required this.value});

  final String value;

  static TaggingStatus? resolve(String value) {
    return TaggingStatus.values.firstWhereOrNull((element) => element.value == value);
  }
}

enum PPPConnectionBehavior {
  connectOnDemand(value: 'ConnectOnDemand'),
  keepAlive(value: 'KeepAlive'),
  ;

  const PPPConnectionBehavior({required this.value});

  final String value;

  static PPPConnectionBehavior? resolve(String value) {
    return PPPConnectionBehavior.values.firstWhereOrNull((element) => element.value == value);
  }
}

class InternetSettingsState extends Equatable {
  final String ipv4ConnectionType;
  final String ipv6ConnectionType;
  final List<String> supportedIPv4ConnectionType;
  final List<String> supportedIPv6ConnectionType;
  final List<SupportedWANCombination> supportedWANCombinations;
  final int mtu;
  // IPv6
  final String duid;
  final bool isIPv6AutomaticEnabled;
  final IPv6rdTunnelMode? ipv6rdTunnelMode;
  final String? ipv6Prefix;
  final int? ipv6PrefixLength;
  final String? ipv6BorderRelay;
  final int? ipv6BorderRelayPrefixLength;
  // MAC Clone
  final bool macClone;
  final String macCloneAddress;
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
  // PPPoE & TP (PPTP/L2TP) Settings
  final String? username;
  final String? password;
  final String? serviceName;
  final String? serverIp;
  final bool? useStaticSettings;
  // Wan Tagging Settings
  final int? vlanId;
  
  final String? error;

  @override
  List<Object?> get props {
    return [
      ipv4ConnectionType,
      ipv6ConnectionType,
      supportedIPv4ConnectionType,
      supportedIPv6ConnectionType,
      supportedWANCombinations,
      mtu,
      duid,
      isIPv6AutomaticEnabled,
      ipv6rdTunnelMode,
      ipv6Prefix,
      ipv6PrefixLength,
      ipv6BorderRelay,
      ipv6BorderRelayPrefixLength,
      macClone,
      macCloneAddress,
      behavior,
      maxIdleMinutes,
      reconnectAfterSeconds,
      staticIpAddress,
      staticGateway,
      staticDns1,
      staticDns2,
      staticDns3,
      username,
      password,
      serviceName,
      serverIp,
      useStaticSettings,
      vlanId,
      error,
    ];
  }

  const InternetSettingsState({
    required this.ipv4ConnectionType,
    required this.ipv6ConnectionType,
    required this.supportedIPv4ConnectionType,
    required this.supportedIPv6ConnectionType,
    required this.supportedWANCombinations,
    required this.mtu,
    required this.duid,
    required this.isIPv6AutomaticEnabled,
    this.ipv6rdTunnelMode,
    this.ipv6Prefix,
    this.ipv6PrefixLength,
    this.ipv6BorderRelay,
    this.ipv6BorderRelayPrefixLength,
    required this.macClone,
    required this.macCloneAddress,
    this.behavior,
    this.maxIdleMinutes,
    this.reconnectAfterSeconds,
    this.staticIpAddress,
    this.staticGateway,
    this.staticDns1,
    this.staticDns2,
    this.staticDns3,
    this.username,
    this.password,
    this.serviceName,
    this.serverIp,
    this.useStaticSettings,
    this.vlanId,
    this.error,
  });

  factory InternetSettingsState.init() {
    return const InternetSettingsState(
      ipv4ConnectionType: '',
      ipv6ConnectionType: '',
      supportedIPv4ConnectionType: [],
      supportedIPv6ConnectionType: [],
      supportedWANCombinations: [],
      duid: '',
      isIPv6AutomaticEnabled: false,
      mtu: 0,
      macClone: false,
      macCloneAddress: '',
      error: null,
      behavior: PPPConnectionBehavior.keepAlive,
      maxIdleMinutes: 15,
      reconnectAfterSeconds: 30,
    );
  }

  InternetSettingsState copyWith({
    String? ipv4ConnectionType,
    String? ipv6ConnectionType,
    List<String>? supportedIPv4ConnectionType,
    List<String>? supportedIPv6ConnectionType,
    List<SupportedWANCombination>? supportedWANCombinations,
    int? mtu,
    String? duid,
    bool? isIPv6AutomaticEnabled,
    IPv6rdTunnelMode? ipv6rdTunnelMode,
    String? ipv6Prefix,
    int? ipv6PrefixLength,
    String? ipv6BorderRelay,
    int? ipv6BorderRelayPrefixLength,
    bool? macClone,
    String? macCloneAddress,
    PPPConnectionBehavior? behavior,
    int? maxIdleMinutes,
    int? reconnectAfterSeconds,
    String? staticIpAddress,
    String? staticGateway,
    String? staticDns1,
    String? staticDns2,
    String? staticDns3,
    String? username,
    String? password,
    String? serviceName,
    String? serverIp,
    bool? useStaticSettings,
    int? vlanId,
    String? error,
  }) {
    return InternetSettingsState(
      ipv4ConnectionType: ipv4ConnectionType ?? this.ipv4ConnectionType,
      ipv6ConnectionType: ipv6ConnectionType ?? this.ipv6ConnectionType,
      supportedIPv4ConnectionType: supportedIPv4ConnectionType ?? this.supportedIPv4ConnectionType,
      supportedIPv6ConnectionType: supportedIPv6ConnectionType ?? this.supportedIPv6ConnectionType,
      supportedWANCombinations: supportedWANCombinations ?? this.supportedWANCombinations,
      mtu: mtu ?? this.mtu,
      duid: duid ?? this.duid,
      isIPv6AutomaticEnabled: isIPv6AutomaticEnabled ?? this.isIPv6AutomaticEnabled,
      ipv6rdTunnelMode: ipv6rdTunnelMode ?? this.ipv6rdTunnelMode,
      ipv6Prefix: ipv6Prefix ?? this.ipv6Prefix,
      ipv6PrefixLength: ipv6PrefixLength ?? this.ipv6PrefixLength,
      ipv6BorderRelay: ipv6BorderRelay ?? this.ipv6BorderRelay,
      ipv6BorderRelayPrefixLength: ipv6BorderRelayPrefixLength ?? this.ipv6BorderRelayPrefixLength,
      macClone: macClone ?? this.macClone,
      macCloneAddress: macCloneAddress ?? this.macCloneAddress,
      behavior: behavior ?? this.behavior,
      maxIdleMinutes: maxIdleMinutes ?? this.maxIdleMinutes,
      reconnectAfterSeconds: reconnectAfterSeconds ?? this.reconnectAfterSeconds,
      staticIpAddress: staticIpAddress ?? this.staticIpAddress,
      staticGateway: staticGateway ?? this.staticGateway,
      staticDns1: staticDns1 ?? this.staticDns1,
      staticDns2: staticDns2 ?? this.staticDns2,
      staticDns3: staticDns3 ?? this.staticDns3,
      username: username ?? this.username,
      password: password ?? this.password,
      serviceName: serviceName ?? this.serviceName,
      serverIp: serverIp ?? this.serverIp,
      useStaticSettings: useStaticSettings ?? this.useStaticSettings,
      vlanId: vlanId ?? this.vlanId,
      error: error ?? this.error,
    );
  }

}
