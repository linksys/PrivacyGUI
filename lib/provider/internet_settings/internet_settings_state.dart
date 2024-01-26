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
  final Map<String, Map> connectionData;
  final String duid;
  final bool isIPv6AutomaticEnabled;
  final int mtu;
  final bool macClone;
  final String macCloneAddress;
  final String? error;
  final PPPConnectionBehavior? behavior;
  final int? maxIdleMinutes;
  final int? reconnectAfterSeconds;
  final String? staticIpAddress;
  final String? staticGateway;
  final String? staticDns1;
  final String? staticDns2;
  final String? staticDns3;
  final String? username;
  final String? password;
  final String? serviceName;
  final int? vlanId;
  final String? serverIp;
  final bool? useStaticSettings;

  @override
  List<Object?> get props {
    return [
      ipv4ConnectionType,
      ipv6ConnectionType,
      supportedIPv4ConnectionType,
      supportedIPv6ConnectionType,
      supportedWANCombinations,
      connectionData,
      duid,
      isIPv6AutomaticEnabled,
      mtu,
      macClone,
      macCloneAddress,
      error,
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
      vlanId,
      serverIp,
      useStaticSettings,
    ];
  }

  const InternetSettingsState({
    required this.ipv4ConnectionType,
    required this.ipv6ConnectionType,
    required this.supportedIPv4ConnectionType,
    required this.supportedIPv6ConnectionType,
    required this.supportedWANCombinations,
    required this.connectionData,
    required this.duid,
    required this.isIPv6AutomaticEnabled,
    required this.mtu,
    required this.macClone,
    required this.macCloneAddress,
    this.error,
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
    this.vlanId,
    this.serverIp,
    this.useStaticSettings,
  });

  factory InternetSettingsState.init() {
    return const InternetSettingsState(
      ipv4ConnectionType: '',
      ipv6ConnectionType: '',
      supportedIPv4ConnectionType: [],
      supportedIPv6ConnectionType: [],
      supportedWANCombinations: [],
      connectionData: {},
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
    Map<String, Map>? connectionData,
    String? duid,
    bool? isIPv6AutomaticEnabled,
    int? mtu,
    bool? macClone,
    String? macCloneAddress,
    String? error,
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
    int? vlanId,
    String? serverIp,
    bool? useStaticSettings,
  }) {
    return InternetSettingsState(
      ipv4ConnectionType: ipv4ConnectionType ?? this.ipv4ConnectionType,
      ipv6ConnectionType: ipv6ConnectionType ?? this.ipv6ConnectionType,
      supportedIPv4ConnectionType: supportedIPv4ConnectionType ?? this.supportedIPv4ConnectionType,
      supportedIPv6ConnectionType: supportedIPv6ConnectionType ?? this.supportedIPv6ConnectionType,
      supportedWANCombinations: supportedWANCombinations ?? this.supportedWANCombinations,
      connectionData: connectionData ?? this.connectionData,
      duid: duid ?? this.duid,
      isIPv6AutomaticEnabled: isIPv6AutomaticEnabled ?? this.isIPv6AutomaticEnabled,
      mtu: mtu ?? this.mtu,
      macClone: macClone ?? this.macClone,
      macCloneAddress: macCloneAddress ?? this.macCloneAddress,
      error: error ?? this.error,
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
      vlanId: vlanId ?? this.vlanId,
      serverIp: serverIp ?? this.serverIp,
      useStaticSettings: useStaticSettings ?? this.useStaticSettings,
    );
  }

}
