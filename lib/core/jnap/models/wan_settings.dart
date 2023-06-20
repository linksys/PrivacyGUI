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

  Map<String, dynamic> toJson() {
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
    }
      ..removeWhere((key, value) => value == null);
  }

  factory RouterWANSettings.fromJson(Map<String, dynamic> json) {
    return RouterWANSettings(
      wanType: json['wanType'],
      pppoeSettings: json['pppoeSettings'] == null
          ? null
          : PPPoESettings.fromJson(json['pppoeSettings']),
      tpSettings: json['tpSettings'] == null
          ? null
          : TPSettings.fromJson(json['tpSettings']),
      telstraSettings: json['telstraSettings'] == null
          ? null
          : TelstraSettings.fromJson(json['telstraSettings']),
      staticSettings: json['staticSettings'] == null
          ? null
          : StaticSettings.fromJson(json['staticSettings']),
      bridgeSettings: json['bridgeSettings'] == null
          ? null
          : BridgeSettings.fromJson(json['bridgeSettings']),
      dsliteSettings: json['dsliteSettings'] == null
          ? null
          : DSLiteSettings.fromJson(json['dsliteSettings']),
      wirelessModeSettings: json['wirelessModeSettings'] == null
          ? null
          : WirelessModeSettings.fromJson(json['wirelessModeSettings']),
      domainName: json['domainName'],
      mtu: json['mtu'],
      wanTaggingSettings:
      json['wanTaggingSettings'] as SinglePortVLANTaggingSettings,
    );
  }

  @override
  List<Object?> get props =>
      [
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

  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'networkPrefixLength': networkPrefixLength,
      'gateway': gateway,
      'dnsServer1': dnsServer1,
      'dnsServer2': dnsServer2,
      'dnsServer3': dnsServer3,
      'domainName': domainName,
    }
      ..removeWhere((key, value) => value == null);
  }

  factory StaticSettings.fromJson(Map<String, dynamic> json) {
    return StaticSettings(
      ipAddress: json['ipAddress'],
      networkPrefixLength: json['networkPrefixLength'],
      gateway: json['gateway'],
      dnsServer1: json['dnsServer1'],
      dnsServer2: json['dnsServer2'],
      dnsServer3: json['dnsServer3'],
      domainName: json['domainName'],
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'serviceName': serviceName,
      'behavior': behavior,
      'maxIdleMinutes': maxIdleMinutes,
      'reconnectAfterSeconds': reconnectAfterSeconds,
    }
      ..removeWhere((key, value) => value == null);
  }

  factory PPPoESettings.fromJson(Map<String, dynamic> json) {
    return PPPoESettings(
      username: json['username'],
      password: json['password'],
      serviceName: json['serviceName'],
      behavior: json['behavior'],
      maxIdleMinutes: json['maxIdleMinutes'],
      reconnectAfterSeconds: json['reconnectAfterSeconds'],
    );
  }
}

class TPSettings extends Equatable {
  final bool useStaticSettings;
  final StaticSettings? staticSettings;
  final String server;
  final String username;
  final String password;
  final String behavior;
  final int? maxIdleMinute;
  final int? reconnectAfterSeconds;

  const TPSettings({
    required this.useStaticSettings,
    this.staticSettings,
    required this.server,
    required this.username,
    required this.password,
    required this.behavior,
    this.maxIdleMinute,
    this.reconnectAfterSeconds,
  });

  TPSettings copyWith({
    bool? useStaticSettings,
    StaticSettings? staticSettings,
    String? server,
    String? username,
    String? password,
    String? behavior,
    int? maxIdleMinute,
    int? reconnectAfterSeconds,
  }) {
    return TPSettings(
      useStaticSettings: useStaticSettings ?? this.useStaticSettings,
      staticSettings: staticSettings ?? this.staticSettings,
      server: server ?? this.server,
      username: username ?? this.username,
      password: password ?? this.password,
      behavior: behavior ?? this.behavior,
      maxIdleMinute: maxIdleMinute ?? this.maxIdleMinute,
      reconnectAfterSeconds:
      reconnectAfterSeconds ?? this.reconnectAfterSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useStaticSettings': useStaticSettings,
      'staticSettings': staticSettings,
      'server': server,
      'username': username,
      'password': password,
      'behavior': behavior,
      'maxIdleMinute': maxIdleMinute,
      'reconnectAfterSeconds': reconnectAfterSeconds,
    }
      ..removeWhere((key, value) => value == null);
  }

  factory TPSettings.fromJson(Map<String, dynamic> json) {
    return TPSettings(
      useStaticSettings: json['useStaticSettings'],
      staticSettings: json['staticSettings'] == null
          ? null
          : StaticSettings.fromJson(json['staticSettings']),
      server: json['server'],
      username: json['username'],
      password: json['password'],
      behavior: json['behavior'],
      maxIdleMinute: json['maxIdleMinute'],
      reconnectAfterSeconds: json['reconnectAfterSeconds'],
    );
  }

  @override
  List<Object?> get props =>
      [
        useStaticSettings,
        staticSettings,
        server,
        username,
        password,
        behavior,
        maxIdleMinute,
        reconnectAfterSeconds,
      ];
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

  Map<String, dynamic> toJson() {
    return {
      'server': server,
      'username': username,
      'password': password,
    };
  }

  factory TelstraSettings.fromJson(Map<String, dynamic> json) {
    return TelstraSettings(
      server: json['server'],
      username: json['username'],
      password: json['password'],
    );
  }

  @override
  List<Object> get props => [server, username, password];
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

  Map<String, dynamic> toJson() {
    return {
      'useStaticSettings': useStaticSettings,
      'staticSettings': staticSettings,
    }
      ..removeWhere((key, value) => value == null);
  }

  factory BridgeSettings.fromJson(Map<String, dynamic> json) {
    return BridgeSettings(
      useStaticSettings: json['useStaticSettings'],
      staticSettings: json['staticSettings'] == null
          ? null
          : StaticSettings.fromJson(json['staticSettings']),
    );
  }

  @override
  List<Object?> get props => [useStaticSettings, staticSettings];
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

  Map<String, dynamic> toJson() {
    return {
      'useManualSettings': useManualSettings,
      'manualSettings': manualSettings,
    }
      ..removeWhere((key, value) => value == null);
  }

  factory DSLiteSettings.fromJson(Map<String, dynamic> json) {
    return DSLiteSettings(
      useManualSettings: json['useManualSettings'],
      manualSettings: json['manualSettings'] == null
          ? null
          : AFTRSettings.fromJson(json['manualSettings']),
    );
  }

  @override
  List<Object?> get props => [useManualSettings, manualSettings];
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

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'bssid': bssid,
      'band': band,
      'security': security,
      'password': password,
    };
  }

  factory WirelessModeSettings.fromJson(Map<String, dynamic> json) {
    return WirelessModeSettings(
      ssid: json['ssid'],
      bssid: json['bssid'],
      band: json['band'],
      security: json['security'],
      password: json['password'],
    );
  }

  @override
  List<Object?> get props => [ssid, bssid, band, security, password];
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

  Map<String, dynamic> toJson() {
    return {
      'aftrURL': aftrURL,
      'afterAddress': afterAddress,
    };
  }

  factory AFTRSettings.fromJson(Map<String, dynamic> json) {
    return AFTRSettings(
      aftrURL: json['aftrURL'],
      afterAddress: json['afterAddress'],
    );
  }

  @override
  List<Object?> get props => [aftrURL, afterAddress];
}

class SinglePortVLANTaggingSettings {
  final bool isEnabled;
  final PortTaggingSettings? vlanTaggingSettings;

  const SinglePortVLANTaggingSettings({
    required this.isEnabled,
    this.vlanTaggingSettings,
  });

  SinglePortVLANTaggingSettings copyWith({
    bool? isEnabled,
    PortTaggingSettings? vlanTaggingSettings,
  }) {
    return SinglePortVLANTaggingSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      vlanTaggingSettings: vlanTaggingSettings ?? this.vlanTaggingSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'vlanTaggingSettings': vlanTaggingSettings?.toJson(),
    }
      ..removeWhere((key, value) => value == null);
  }

  factory SinglePortVLANTaggingSettings.fromJson(Map<String, dynamic> json) {
    return SinglePortVLANTaggingSettings(
      isEnabled: json['isEnabled'],
      vlanTaggingSettings: json['vlanTaggingSettings'] == null
          ? null
          : PortTaggingSettings.fromJson(json['vlanTaggingSettings']),
    );
  }
}

class PortTaggingSettings {
  final int vlanID;
  final int vlanLowerLimit;
  final int vlanUpperLimit;

  ///
  /// Tagged/Untagged
  ///
  final String vlanStatus;

  const PortTaggingSettings({
    required this.vlanID,
    required this.vlanLowerLimit,
    required this.vlanUpperLimit,
    required this.vlanStatus,
  });

  PortTaggingSettings copyWith({
    int? vlanID,
    int? vlanLowerLimit,
    int? vlanUpperLimit,
    String? vlanStatus,
  }) {
    return PortTaggingSettings(
      vlanID: vlanID ?? this.vlanID,
      vlanLowerLimit: vlanLowerLimit ?? this.vlanLowerLimit,
      vlanUpperLimit: vlanUpperLimit ?? this.vlanUpperLimit,
      vlanStatus: vlanStatus ?? this.vlanStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vlanID': vlanID,
      'vlanLowerLimit': vlanLowerLimit,
      'vlanUpperLimit': vlanUpperLimit,
      'vlanStatus': vlanStatus,
    };
  }

  factory PortTaggingSettings.fromJson(Map<String, dynamic> json) {
    return PortTaggingSettings(
      vlanID: json['vlanID'],
      vlanLowerLimit: json['vlanLowerLimit'],
      vlanUpperLimit: json['vlanUpperLimit'],
      vlanStatus: json['vlanStatus'],
    );
  }
}
