import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class InternetSettingsState
    extends FeatureState<InternetSettings, InternetSettingsStatus> {
  const InternetSettingsState({
    required super.settings,
    required super.status,
  });

  factory InternetSettingsState.init() {
    return InternetSettingsState(
      settings: Preservable(
          original: InternetSettings.init(), current: InternetSettings.init()),
      status: InternetSettingsStatus.init(),
    );
  }

  factory InternetSettingsState.fromJson(String source) =>
      InternetSettingsState.fromMap(json.decode(source));

  factory InternetSettingsState.fromMap(Map<String, dynamic> map) {
    return InternetSettingsState(
      settings: Preservable.fromMap(
          map['settings'],
          (dynamic json) =>
              InternetSettings.fromMap(json as Map<String, dynamic>)),
      status:
          InternetSettingsStatus.fromMap(map['status'] as Map<String, dynamic>),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((value) => value.toMap()),
      'status': status.toMap(),
    };
  }

  @override
  InternetSettingsState copyWith({
    Preservable<InternetSettings>? settings,
    InternetSettingsStatus? status,
  }) {
    return InternetSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }
}

class InternetSettings extends Equatable {
  final Ipv4Setting ipv4Setting;
  final Ipv6Setting ipv6Setting;
  // MAC Clone
  final bool macClone;
  final String? macCloneAddress;

  @override
  List<Object?> get props => [
        ipv4Setting,
        ipv6Setting,
        macClone,
        macCloneAddress,
      ];

  const InternetSettings({
    required this.ipv4Setting,
    required this.ipv6Setting,
    required this.macClone,
    this.macCloneAddress,
  });

  factory InternetSettings.init() {
    return const InternetSettings(
      ipv4Setting: Ipv4Setting(
        ipv4ConnectionType: '',
        mtu: 0,
      ),
      ipv6Setting: Ipv6Setting(
        ipv6ConnectionType: '',
        isIPv6AutomaticEnabled: true,
      ),
      macClone: false,
      macCloneAddress: '',
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

  factory InternetSettings.fromMap(Map<String, dynamic> map) {
    return InternetSettings(
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

  factory InternetSettings.fromJson(String source) =>
      InternetSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  InternetSettings copyWith({
    Ipv4Setting? ipv4Setting,
    Ipv6Setting? ipv6Setting,
    bool? macClone,
    ValueGetter<String?>? macCloneAddress,
  }) {
    return InternetSettings(
      ipv4Setting: ipv4Setting ?? this.ipv4Setting,
      ipv6Setting: ipv6Setting ?? this.ipv6Setting,
      macClone: macClone ?? this.macClone,
      macCloneAddress:
          macCloneAddress != null ? macCloneAddress() : this.macCloneAddress,
    );
  }
}

class InternetSettingsStatus extends Equatable {
  final List<String> supportedIPv4ConnectionType;
  final List<SupportedWANCombination> supportedWANCombinations;
  final List<String> supportedIPv6ConnectionType;
  final String duid;
  final String? redirection;
  final String? hostname;

  const InternetSettingsStatus({
    required this.supportedIPv4ConnectionType,
    required this.supportedWANCombinations,
    required this.supportedIPv6ConnectionType,
    required this.duid,
    this.redirection,
    this.hostname,
  });

  factory InternetSettingsStatus.init() {
    return const InternetSettingsStatus(
      supportedIPv4ConnectionType: [],
      supportedWANCombinations: [],
      supportedIPv6ConnectionType: [],
      duid: '',
      hostname: null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'supportedIPv4ConnectionType': supportedIPv4ConnectionType,
      'supportedWANCombinations':
          supportedWANCombinations.map((x) => x.toMap()).toList(),
      'supportedIPv6ConnectionType': supportedIPv6ConnectionType,
      'duid': duid,
      'redirection': redirection,
      'hostname': hostname,
    }..removeWhere((key, value) => value == null);
  }

  factory InternetSettingsStatus.fromMap(Map<String, dynamic> map) {
    return InternetSettingsStatus(
      supportedIPv4ConnectionType:
          List<String>.from(map['supportedIPv4ConnectionType']),
      supportedWANCombinations: List<SupportedWANCombination>.from(
        map['supportedWANCombinations'].map(
          (x) => SupportedWANCombination.fromMap(x),
        ),
      ),
      supportedIPv6ConnectionType:
          List<String>.from(map['supportedIPv6ConnectionType']),
      duid: map['duid'] as String,
      redirection:
          map['redirection'] != null ? map['redirection'] as String : null,
      hostname: map['hostname'] != null ? map['hostname'] as String : null,
    );
  }

  @override
  List<Object?> get props => [
        supportedIPv4ConnectionType,
        supportedWANCombinations,
        supportedIPv6ConnectionType,
        duid,
        redirection,
        hostname,
      ];

  InternetSettingsStatus copyWith({
    List<String>? supportedIPv4ConnectionType,
    List<SupportedWANCombination>? supportedWANCombinations,
    List<String>? supportedIPv6ConnectionType,
    String? duid,
    ValueGetter<String?>? redirection,
    ValueGetter<String?>? hostname,
  }) {
    return InternetSettingsStatus(
      supportedIPv4ConnectionType:
          supportedIPv4ConnectionType ?? this.supportedIPv4ConnectionType,
      supportedWANCombinations:
          supportedWANCombinations ?? this.supportedWANCombinations,
      supportedIPv6ConnectionType:
          supportedIPv6ConnectionType ?? this.supportedIPv6ConnectionType,
      duid: duid ?? this.duid,
      redirection: redirection != null ? redirection() : this.redirection,
      hostname: hostname != null ? hostname() : this.hostname,
    );
  }
}

class Ipv4Setting extends Equatable {
  final String ipv4ConnectionType;
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
  // Wan Tagging Settings
  final bool? wanTaggingSettingsEnable;
  final int? vlanId;

  const Ipv4Setting({
    required this.ipv4ConnectionType,
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
    this.wanTaggingSettingsEnable,
    this.vlanId,
  });

  @override
  List<Object?> get props {
    return [
      ipv4ConnectionType,
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
      wanTaggingSettingsEnable,
      vlanId,
    ];
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ipv4ConnectionType': ipv4ConnectionType,
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
      'wanTaggingSettingsEnable': wanTaggingSettingsEnable,
      'vlanId': vlanId,
    }..removeWhere((key, value) => value == null);
  }

  factory Ipv4Setting.fromMap(Map<String, dynamic> map) {
    return Ipv4Setting(
      ipv4ConnectionType: map['ipv4ConnectionType'],
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

  Ipv4Setting copyWith({
    String? ipv4ConnectionType,
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
    ValueGetter<bool?>? wanTaggingSettingsEnable,
    ValueGetter<int?>? vlanId,
  }) {
    return Ipv4Setting(
      ipv4ConnectionType: ipv4ConnectionType ?? this.ipv4ConnectionType,
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
      wanTaggingSettingsEnable: wanTaggingSettingsEnable != null
          ? wanTaggingSettingsEnable()
          : this.wanTaggingSettingsEnable,
      vlanId: vlanId != null ? vlanId() : this.vlanId,
    );
  }
}

class Ipv6Setting extends Equatable {
  final String ipv6ConnectionType;
  final bool isIPv6AutomaticEnabled;
  final IPv6rdTunnelMode? ipv6rdTunnelMode;
  final String? ipv6Prefix;
  final int? ipv6PrefixLength;
  final String? ipv6BorderRelay;
  final int? ipv6BorderRelayPrefixLength;

  const Ipv6Setting({
    required this.ipv6ConnectionType,
    required this.isIPv6AutomaticEnabled,
    this.ipv6rdTunnelMode,
    this.ipv6Prefix,
    this.ipv6PrefixLength,
    this.ipv6BorderRelay,
    this.ipv6BorderRelayPrefixLength,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ipv6ConnectionType': ipv6ConnectionType,
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
      isIPv6AutomaticEnabled,
      ipv6rdTunnelMode,
      ipv6Prefix,
      ipv6PrefixLength,
      ipv6BorderRelay,
      ipv6BorderRelayPrefixLength,
    ];
  }

  Ipv6Setting copyWith({
    String? ipv6ConnectionType,
    bool? isIPv6AutomaticEnabled,
    ValueGetter<IPv6rdTunnelMode?>? ipv6rdTunnelMode,
    ValueGetter<String?>? ipv6Prefix,
    ValueGetter<int?>? ipv6PrefixLength,
    ValueGetter<String?>? ipv6BorderRelay,
    ValueGetter<int?>? ipv6BorderRelayPrefixLength,
  }) {
    return Ipv6Setting(
      ipv6ConnectionType: ipv6ConnectionType ?? this.ipv6ConnectionType,
      isIPv6AutomaticEnabled:
          isIPv6AutomaticEnabled ?? this.isIPv6AutomaticEnabled,
      ipv6rdTunnelMode:
          ipv6rdTunnelMode != null ? ipv6rdTunnelMode() : this.ipv6rdTunnelMode,
      ipv6Prefix: ipv6Prefix != null ? ipv6Prefix() : this.ipv6Prefix,
      ipv6PrefixLength:
          ipv6PrefixLength != null ? ipv6PrefixLength() : this.ipv6PrefixLength,
      ipv6BorderRelay:
          ipv6BorderRelay != null ? ipv6BorderRelay() : this.ipv6BorderRelay,
      ipv6BorderRelayPrefixLength: ipv6BorderRelayPrefixLength != null
          ? ipv6BorderRelayPrefixLength()
          : this.ipv6BorderRelayPrefixLength,
    );
  }
}
