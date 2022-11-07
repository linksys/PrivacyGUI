
class RouterWANSettings {
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
  final StaticSettings? staticSettings;
  final String? domainName;
  final int mtu;
  final SinglePortVLANTaggingSettings? wanTaggingSettings;

  const RouterWANSettings({
    required this.wanType,
    this.pppoeSettings,
    this.staticSettings,
    this.domainName,
    required this.mtu,
    this.wanTaggingSettings,
  });

  RouterWANSettings copyWith({
    String? wanType,
    PPPoESettings? pppoeSettings,
    StaticSettings? staticSettings,
    String? domainName,
    int? mtu,
    SinglePortVLANTaggingSettings? wanTaggingSettings,
  }) {
    return RouterWANSettings(
      wanType: wanType ?? this.wanType,
      pppoeSettings: pppoeSettings ?? this.pppoeSettings,
      staticSettings: staticSettings ?? this.staticSettings,
      domainName: domainName ?? this.domainName,
      mtu: mtu ?? this.mtu,
      wanTaggingSettings: wanTaggingSettings ?? this.wanTaggingSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wanType': wanType,
      'pppoeSettings': pppoeSettings?.toJson(),
      'staticSettings': staticSettings?.toJson(),
      'domainName': domainName,
      'mtu': mtu,
      'wanTaggingSettings': wanTaggingSettings?.toJson(),
    }..removeWhere((key, value) => value == null);
  }

  factory RouterWANSettings.fromJson(Map<String, dynamic> json) {
    return RouterWANSettings(
      wanType: json['wanType'],
      pppoeSettings: PPPoESettings.fromJson(json['pppoeSettings']),
      staticSettings: StaticSettings.fromJson(json['staticSettings']),
      domainName: json['domainName'],
      mtu: json['mtu'],
      wanTaggingSettings: json['wanTaggingSettings'] == null ? null : SinglePortVLANTaggingSettings.fromJson(json['wanTaggingSettings']),
    );
  }
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
    }..removeWhere((key, value) => value == null);
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
    }..removeWhere((key, value) => value == null);
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
    }..removeWhere((key, value) => value == null);
  }

  factory SinglePortVLANTaggingSettings.fromJson(Map<String, dynamic> json) {
    return SinglePortVLANTaggingSettings(
      isEnabled: json['isEnabled'],
      vlanTaggingSettings: json['vlanTaggingSettings'] == null ? null : PortTaggingSettings.fromJson(json['vlanTaggingSettings']),
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