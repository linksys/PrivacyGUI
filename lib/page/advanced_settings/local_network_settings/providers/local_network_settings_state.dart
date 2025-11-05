import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/utils.dart';

enum LocalNetworkErrorPrompt {
  hostName,
  hostNameInvalid,
  startIpAddress,
  startIpAddressRange,
  ipAddress,
  maxUserAllowed,
  subnetMask,
  leaseTime,
  dns1,
  dns2,
  dns3,
  wins;

  static LocalNetworkErrorPrompt? resolve(String? error) {
    return LocalNetworkErrorPrompt.values.firstWhereOrNull((element) => element.name == error);
  }

  static String? getErrorText({required BuildContext context,
      LocalNetworkErrorPrompt? error, String? ipAddress, String? subnetMask}) {
    if (error == null) {
      return null;
    }
    return switch (error) {
      LocalNetworkErrorPrompt.startIpAddress =>
        loc(context).invalidIpOrSameAsHostIp,
      LocalNetworkErrorPrompt.startIpAddressRange =>
        startIpAddressInvalidMessage(
            context, ipAddress ?? '', subnetMask ?? ''),
      LocalNetworkErrorPrompt.ipAddress => loc(context).invalidIpAddress,
      LocalNetworkErrorPrompt.maxUserAllowed => loc(context).invalidNumber,
      LocalNetworkErrorPrompt.subnetMask => loc(context).invalidSubnetMask,
      LocalNetworkErrorPrompt.leaseTime => loc(context).invalidNumber,
      LocalNetworkErrorPrompt.dns1 => loc(context).invalidIpAddress,
      LocalNetworkErrorPrompt.dns2 => loc(context).invalidIpAddress,
      LocalNetworkErrorPrompt.dns3 => loc(context).invalidIpAddress,
      LocalNetworkErrorPrompt.wins => loc(context).invalidIpAddress,
      LocalNetworkErrorPrompt.hostName => loc(context).hostNameCannotEmpty,
      LocalNetworkErrorPrompt.hostNameInvalid => loc(context).invalidHostname,
    };
  }

  static String startIpAddressInvalidMessage(
      BuildContext context, String routerIp, String subnetMask) {
    final routerIPAddressNum = NetworkUtils.ipToNum(routerIp);
    final subnetMaskNum = NetworkUtils.ipToNum(subnetMask);
    final routerSubnet = (routerIPAddressNum & subnetMaskNum) >>> 0;
    final routerBroadcast = (~subnetMaskNum | routerSubnet) >>> 0;
    final startIpAddress = NetworkUtils.numToIp(routerSubnet + 1);
    final endIpAddress = NetworkUtils.numToIp(routerBroadcast - 1);

    return '${loc(context).invalidIPAddressSubnet} [$startIpAddress - $endIpAddress]';
  }
}

class LocalNetworkSettings extends Equatable {
  final String hostName;
  final String ipAddress;
  final String subnetMask;
  final bool isDHCPEnabled;
  final String firstIPAddress;
  final String lastIPAddress;
  final int maxUserAllowed;
  final int clientLeaseTime;
  final String? dns1;
  final String? dns2;
  final String? dns3;
  final String? wins;

  const LocalNetworkSettings({
    required this.hostName,
    required this.ipAddress,
    required this.subnetMask,
    required this.isDHCPEnabled,
    required this.firstIPAddress,
    required this.lastIPAddress,
    required this.maxUserAllowed,
    required this.clientLeaseTime,
    this.dns1,
    this.dns2,
    this.dns3,
    this.wins,
  });

  factory LocalNetworkSettings.init() => const LocalNetworkSettings(
        hostName: '',
        ipAddress: '',
        subnetMask: '',
        isDHCPEnabled: false,
        firstIPAddress: '',
        lastIPAddress: '',
        maxUserAllowed: 0,
        clientLeaseTime: 0,
      );

  @override
  List<Object?> get props => [
        hostName,
        ipAddress,
        subnetMask,
        isDHCPEnabled,
        firstIPAddress,
        lastIPAddress,
        maxUserAllowed,
        clientLeaseTime,
        dns1,
        dns2,
        dns3,
        wins,
      ];

  LocalNetworkSettings copyWith({
    String? hostName,
    String? ipAddress,
    String? subnetMask,
    bool? isDHCPEnabled,
    String? firstIPAddress,
    String? lastIPAddress,
    int? maxUserAllowed,
    int? clientLeaseTime,
    ValueGetter<String?>? dns1,
    ValueGetter<String?>? dns2,
    ValueGetter<String?>? dns3,
    ValueGetter<String?>? wins,
  }) {
    return LocalNetworkSettings(
      hostName: hostName ?? this.hostName,
      ipAddress: ipAddress ?? this.ipAddress,
      subnetMask: subnetMask ?? this.subnetMask,
      isDHCPEnabled: isDHCPEnabled ?? this.isDHCPEnabled,
      firstIPAddress: firstIPAddress ?? this.firstIPAddress,
      lastIPAddress: lastIPAddress ?? this.lastIPAddress,
      maxUserAllowed: maxUserAllowed ?? this.maxUserAllowed,
      clientLeaseTime: clientLeaseTime ?? this.clientLeaseTime,
      dns1: dns1 != null ? dns1() : this.dns1,
      dns2: dns2 != null ? dns2() : this.dns2,
      dns3: dns3 != null ? dns3() : this.dns3,
      wins: wins != null ? wins() : this.wins,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hostName': hostName,
      'ipAddress': ipAddress,
      'subnetMask': subnetMask,
      'isDHCPEnabled': isDHCPEnabled,
      'firstIPAddress': firstIPAddress,
      'lastIPAddress': lastIPAddress,
      'maxUserAllowed': maxUserAllowed,
      'clientLeaseTime': clientLeaseTime,
      'dns1': dns1,
      'dns2': dns2,
      'dns3': dns3,
      'wins': wins,
    }..removeWhere((key, value) => value == null);
  }

  factory LocalNetworkSettings.fromMap(Map<String, dynamic> map) {
    return LocalNetworkSettings(
      hostName: map['hostName'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
      subnetMask: map['subnetMask'] ?? '',
      isDHCPEnabled: map['isDHCPEnabled'] ?? false,
      firstIPAddress: map['firstIPAddress'] ?? '',
      lastIPAddress: map['lastIPAddress'] ?? '',
      maxUserAllowed: map['maxUserAllowed']?.toInt() ?? 0,
      clientLeaseTime: map['clientLeaseTime']?.toInt() ?? 0,
      dns1: map['dns1'],
      dns2: map['dns2'],
      dns3: map['dns3'],
      wins: map['wins'],
    );
  }

  String toJson() => json.encode(toMap());

  factory LocalNetworkSettings.fromJson(String source) =>
      LocalNetworkSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}

class LocalNetworkStatus extends Equatable {
  final int maxUserLimit;
  final int minAllowDHCPLeaseMinutes;
  final int maxAllowDHCPLeaseMinutes;
  final int minNetworkPrefixLength;
  final int maxNetworkPrefixLength;
  final List<DHCPReservation> dhcpReservationList;
  final Map<String, String> errorTextMap;
  final bool hasErrorOnHostNameTab;
  final bool hasErrorOnIPAddressTab;
  final bool hasErrorOnDhcpServerTab;

  const LocalNetworkStatus({
    required this.maxUserLimit,
    required this.minAllowDHCPLeaseMinutes,
    required this.maxAllowDHCPLeaseMinutes,
    required this.minNetworkPrefixLength,
    required this.maxNetworkPrefixLength,
    this.dhcpReservationList = const [],
    this.errorTextMap = const {},
    this.hasErrorOnHostNameTab = false,
    this.hasErrorOnIPAddressTab = false,
    this.hasErrorOnDhcpServerTab = false,
  });

  factory LocalNetworkStatus.init() => const LocalNetworkStatus(
        maxUserLimit: 0,
        minAllowDHCPLeaseMinutes: 0,
        maxAllowDHCPLeaseMinutes: 0,
        minNetworkPrefixLength: 8,
        maxNetworkPrefixLength: 30,
      );

  @override
  List<Object?> get props => [
        maxUserLimit,
        minAllowDHCPLeaseMinutes,
        maxAllowDHCPLeaseMinutes,
        minNetworkPrefixLength,
        maxNetworkPrefixLength,
        dhcpReservationList,
        errorTextMap,
        hasErrorOnHostNameTab,
        hasErrorOnIPAddressTab,
        hasErrorOnDhcpServerTab,
      ];

  LocalNetworkStatus copyWith({
    int? maxUserLimit,
    int? minAllowDHCPLeaseMinutes,
    int? maxAllowDHCPLeaseMinutes,
    int? minNetworkPrefixLength,
    int? maxNetworkPrefixLength,
    List<DHCPReservation>? dhcpReservationList,
    Map<String, String>? errorTextMap,
    bool? hasErrorOnHostNameTab,
    bool? hasErrorOnIPAddressTab,
    bool? hasErrorOnDhcpServerTab,
  }) {
    return LocalNetworkStatus(
      maxUserLimit: maxUserLimit ?? this.maxUserLimit,
      minAllowDHCPLeaseMinutes:
          minAllowDHCPLeaseMinutes ?? this.minAllowDHCPLeaseMinutes,
      maxAllowDHCPLeaseMinutes:
          maxAllowDHCPLeaseMinutes ?? this.maxAllowDHCPLeaseMinutes,
      minNetworkPrefixLength:
          minNetworkPrefixLength ?? this.minNetworkPrefixLength,
      maxNetworkPrefixLength:
          maxNetworkPrefixLength ?? this.maxNetworkPrefixLength,
      dhcpReservationList: dhcpReservationList ?? this.dhcpReservationList,
      errorTextMap: errorTextMap ?? this.errorTextMap,
      hasErrorOnHostNameTab:
          hasErrorOnHostNameTab ?? this.hasErrorOnHostNameTab,
      hasErrorOnIPAddressTab:
          hasErrorOnIPAddressTab ?? this.hasErrorOnIPAddressTab,
      hasErrorOnDhcpServerTab:
          hasErrorOnDhcpServerTab ?? this.hasErrorOnDhcpServerTab,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'maxUserLimit': maxUserLimit,
      'minAllowDHCPLeaseMinutes': minAllowDHCPLeaseMinutes,
      'maxAllowDHCPLeaseMinutes': maxAllowDHCPLeaseMinutes,
      'minNetworkPrefixLength': minNetworkPrefixLength,
      'maxNetworkPrefixLength': maxNetworkPrefixLength,
      'dhcpReservationList': dhcpReservationList.map((x) => x.toMap()).toList(),
      'errorTextMap': errorTextMap,
      'hasErrorOnHostNameTab': hasErrorOnHostNameTab,
      'hasErrorOnIPAddressTab': hasErrorOnIPAddressTab,
      'hasErrorOnDhcpServerTab': hasErrorOnDhcpServerTab,
    };
  }

  factory LocalNetworkStatus.fromMap(Map<String, dynamic> map) {
    return LocalNetworkStatus(
      maxUserLimit: map['maxUserLimit']?.toInt() ?? 0,
      minAllowDHCPLeaseMinutes: map['minAllowDHCPLeaseMinutes']?.toInt() ?? 0,
      maxAllowDHCPLeaseMinutes: map['maxAllowDHCPLeaseMinutes']?.toInt() ?? 0,
      minNetworkPrefixLength: map['minNetworkPrefixLength']?.toInt() ?? 0,
      maxNetworkPrefixLength: map['maxNetworkPrefixLength']?.toInt() ?? 0,
      dhcpReservationList: List<DHCPReservation>.from(
          map['dhcpReservationList']?.map((x) => DHCPReservation.fromMap(x))),
      errorTextMap: Map<String, String>.from(
          map['errorTextMap'] ?? {}),
      hasErrorOnHostNameTab: map['hasErrorOnHostNameTab'] ?? false,
      hasErrorOnIPAddressTab: map['hasErrorOnIPAddressTab'] ?? false,
      hasErrorOnDhcpServerTab: map['hasErrorOnDhcpServerTab'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory LocalNetworkStatus.fromJson(String source) =>
      LocalNetworkStatus.fromMap(json.decode(source) as Map<String, dynamic>);
}

class LocalNetworkSettingsState extends FeatureState<LocalNetworkSettings, LocalNetworkStatus> {
  const LocalNetworkSettingsState({
    required super.settings,
    required super.status,
  });

  factory LocalNetworkSettingsState.init() {
    return LocalNetworkSettingsState(
      settings: Preservable(original: LocalNetworkSettings.init(), current: LocalNetworkSettings.init()),
      status: LocalNetworkStatus.init(),
    );
  }

  @override
  LocalNetworkSettingsState copyWith({
    Preservable<LocalNetworkSettings>? settings,
    LocalNetworkStatus? status,
  }) {
    return LocalNetworkSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((value) => value.toMap()),
      'status': status.toMap(),
    };
  }

  factory LocalNetworkSettingsState.fromMap(Map<String, dynamic> map) {
    return LocalNetworkSettingsState(
      settings: Preservable.fromMap(map['settings'], (dynamic json) => LocalNetworkSettings.fromMap(json as Map<String, dynamic>)),
      status: LocalNetworkStatus.fromMap(map['status'] as Map<String, dynamic>),
    );
  }
  
  @override
  String toJson() => json.encode(toMap());

  factory LocalNetworkSettingsState.fromJson(String source) =>
      LocalNetworkSettingsState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
