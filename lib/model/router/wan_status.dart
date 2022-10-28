import 'package:equatable/equatable.dart';

class RouterWANStatus extends Equatable {
  final String macAddress;
  final String detectedWANType;
  final String wanStatus;
  final String wanIPv6Status;
  final WANConnectionInfo? wanConnection;
  final WANIPv6ConnectionInfo? wanIPv6Connection;
  final List<String> supportedWANTypes;

  const RouterWANStatus({
    required this.macAddress,
    required this.detectedWANType,
    required this.wanStatus,
    required this.wanIPv6Status,
    this.wanConnection,
    this.wanIPv6Connection,
    required this.supportedWANTypes,
  });

  RouterWANStatus copyWith({
    String? macAddress,
    String? detectedWANType,
    String? wanStatus,
    String? wanIPv6Status,
    WANConnectionInfo? wanConnection,
    WANIPv6ConnectionInfo? wanIPv6Connection,
    List<String>? supportedWANTypes,
  }) {
    return RouterWANStatus(
      macAddress: macAddress ?? this.macAddress,
      detectedWANType: detectedWANType ?? this.detectedWANType,
      wanStatus: wanStatus ?? this.wanStatus,
      wanIPv6Status: wanIPv6Status ?? this.wanIPv6Status,
      wanConnection: wanConnection ?? this.wanConnection,
      wanIPv6Connection: wanIPv6Connection ?? this.wanIPv6Connection,
      supportedWANTypes: supportedWANTypes ?? this.supportedWANTypes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macAddress': macAddress,
      'detectedWANType': detectedWANType,
      'wanStatus': wanStatus,
      'wanIPv6Status': wanIPv6Status,
      'wanConnection': wanConnection?.toJson(),
      'wanIPv6Connection': wanIPv6Connection?.toJson(),
      'supportedWANTypes': supportedWANTypes,
    }..removeWhere((key, value) => value == null);
  }

  factory RouterWANStatus.fromJson(Map<String, dynamic> json) {
    return RouterWANStatus(
      macAddress: json['macAddress'],
      detectedWANType: json['detectedWANType'],
      wanStatus: json['wanStatus'],
      wanIPv6Status: json['wanIPv6Status'],
      wanConnection: json['wanConnection'] == null
          ? null
          : WANConnectionInfo.fromJson(json['wanConnection']),
      wanIPv6Connection: json['wanIPv6Connection'] == null
          ? null
          : WANIPv6ConnectionInfo.fromJson(json['wanIPv6Connection']),
      supportedWANTypes: List.from(json['supportedWANTypes']),
    );
  }

  @override
  List<Object?> get props => [
        macAddress,
        detectedWANType,
        wanIPv6Status,
        wanStatus,
        wanConnection,
        wanIPv6Connection,
        supportedWANTypes,
      ];
}

class WANConnectionInfo extends Equatable {
  final String wanType;
  final String ipAddress;
  final int networkPrefixLength;
  final String gateway;
  final int mtu;
  final int? dhcpLeaseMinutes;
  final String dnsServer1;
  final String? dnsServer2;
  final String? dnsServer3;

  @override
  List<Object?> get props => [
        wanType,
        ipAddress,
        networkPrefixLength,
        gateway,
        mtu,
        dhcpLeaseMinutes,
        dnsServer1,
        dnsServer2,
        dnsServer3,
      ];

  const WANConnectionInfo({
    required this.wanType,
    required this.ipAddress,
    required this.networkPrefixLength,
    required this.gateway,
    required this.mtu,
    this.dhcpLeaseMinutes,
    required this.dnsServer1,
    this.dnsServer2,
    this.dnsServer3,
  });

  WANConnectionInfo copyWith({
    String? wanType,
    String? ipAddress,
    int? networkPrefixLength,
    String? gateway,
    int? mtu,
    int? dhcpLeaseMinutes,
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
  }) {
    return WANConnectionInfo(
      wanType: wanType ?? this.wanType,
      ipAddress: ipAddress ?? this.ipAddress,
      networkPrefixLength: networkPrefixLength ?? this.networkPrefixLength,
      gateway: gateway ?? this.gateway,
      mtu: mtu ?? this.mtu,
      dhcpLeaseMinutes: dhcpLeaseMinutes ?? this.dhcpLeaseMinutes,
      dnsServer1: dnsServer1 ?? this.dnsServer1,
      dnsServer2: dnsServer2 ?? this.dnsServer2,
      dnsServer3: dnsServer3 ?? this.dnsServer3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wanType': wanType,
      'ipAddress': ipAddress,
      'networkPrefixLength': networkPrefixLength,
      'gateway': gateway,
      'mtu': mtu,
      'dhcpLeaseMinutes': dhcpLeaseMinutes,
      'dnsServer1': dnsServer1,
      'dnsServer2': dnsServer2,
      'dnsServer3': dnsServer3,
    }..removeWhere((key, value) => value == null);
  }

  factory WANConnectionInfo.fromJson(Map<String, dynamic> json) {
    return WANConnectionInfo(
      wanType: json['wanType'],
      ipAddress: json['ipAddress'],
      networkPrefixLength: json['networkPrefixLength'],
      gateway: json['gateway'],
      mtu: json['mtu'],
      dhcpLeaseMinutes: json['dhcpLeaseMinutes'],
      dnsServer1: json['dnsServer1'],
      dnsServer2: json['dnsServer2'],
      dnsServer3: json['dnsServer3'],
    );
  }
}

class WANIPv6ConnectionInfo extends Equatable {
  final String wanType;
  final IPv6NetworkInfo? networkInfo;

  @override
  List<Object?> get props => throw UnimplementedError();

  const WANIPv6ConnectionInfo({
    required this.wanType,
    this.networkInfo,
  });

  WANIPv6ConnectionInfo copyWith({
    String? wanType,
    IPv6NetworkInfo? networkInfo,
  }) {
    return WANIPv6ConnectionInfo(
      wanType: wanType ?? this.wanType,
      networkInfo: networkInfo ?? this.networkInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wanType': wanType,
      'networkInfo': networkInfo,
    }..removeWhere((key, value) => value == null);
  }

  factory WANIPv6ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return WANIPv6ConnectionInfo(
      wanType: json['wanType'],
      networkInfo: json['networkInfo'] == null
          ? null
          : IPv6NetworkInfo.fromJson(json['networkInfo']),
    );
  }
}

class IPv6NetworkInfo extends Equatable {
  final String ipAddress;
  final String? gateway;
  final int? dhcpLeaseMinutes;
  final String? dnsServer1;
  final String? dnsServer2;
  final String? dnsServer3;

  @override
  List<Object?> get props => [
        ipAddress,
        gateway,
        dhcpLeaseMinutes,
        dnsServer1,
        dnsServer2,
        dnsServer3,
      ];

  const IPv6NetworkInfo({
    required this.ipAddress,
    this.gateway,
    this.dhcpLeaseMinutes,
    this.dnsServer1,
    this.dnsServer2,
    this.dnsServer3,
  });

  IPv6NetworkInfo copyWith({
    String? ipAddress,
    String? gateway,
    int? dhcpLeaseMinutes,
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
  }) {
    return IPv6NetworkInfo(
      ipAddress: ipAddress ?? this.ipAddress,
      gateway: gateway ?? this.gateway,
      dhcpLeaseMinutes: dhcpLeaseMinutes ?? this.dhcpLeaseMinutes,
      dnsServer1: dnsServer1 ?? this.dnsServer1,
      dnsServer2: dnsServer2 ?? this.dnsServer2,
      dnsServer3: dnsServer3 ?? this.dnsServer3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'gateway': gateway,
      'dhcpLeaseMinutes': dhcpLeaseMinutes,
      'dnsServer1': dnsServer1,
      'dnsServer2': dnsServer2,
      'dnsServer3': dnsServer3,
    };
  }

  factory IPv6NetworkInfo.fromJson(Map<String, dynamic> json) {
    return IPv6NetworkInfo(
      ipAddress: json['ipAddress'],
      gateway: json['gateway'],
      dhcpLeaseMinutes: json['dhcpLeaseMinutes'],
      dnsServer1: json['dnsServer1'],
      dnsServer2: json['dnsServer2'],
      dnsServer3: json['dnsServer3'],
    );
  }
}
