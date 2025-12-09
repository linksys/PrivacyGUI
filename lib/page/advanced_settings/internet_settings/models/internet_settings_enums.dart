import 'package:collection/collection.dart';

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

  static PPPConnectionBehavior? resolve(String? value) {
    return PPPConnectionBehavior.values
        .firstWhereOrNull((element) => element.value == value);
  }
}

enum PPTPIpAddressMode {
  dhcp,
  specify,
}
