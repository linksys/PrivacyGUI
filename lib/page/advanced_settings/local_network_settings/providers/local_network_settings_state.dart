// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/utils.dart';

enum LocalNetworkErrorPrompt {
  hostName,
  startIpAddress,
  startIpAddressRange,
  ipAddress,
  maxUserAllowed,
  subnetMask,
  leaseTime,
  dns1,
  dns2,
  dns3,
  wins,
  hostNameStartWithHyphen,
  hostNameEndWithHyphen,
  hostNameInvalidCharacters,
  hostNameLengthError;

  static LocalNetworkErrorPrompt? resolve(String? error) {
    return LocalNetworkErrorPrompt.values
        .firstWhereOrNull((element) => element.name == error);
  }

  static String? getErrorText(
      {required BuildContext context,
      LocalNetworkErrorPrompt? error,
      String? ipAddress,
      String? subnetMask,
      String? invalidChars}) {
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
      LocalNetworkErrorPrompt.hostNameStartWithHyphen =>
        loc(context).hostNameStartWithHyphen,
      LocalNetworkErrorPrompt.hostNameEndWithHyphen =>
        loc(context).hostNameEndWithHyphen,
      LocalNetworkErrorPrompt.hostNameInvalidCharacters =>
        loc(context).hostNameInvalidCharacters(invalidChars ?? ''),
      LocalNetworkErrorPrompt.hostNameLengthError =>
        loc(context).hostNameLengthError,
      _ => null,
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

class LocalNetworkSettingsState extends Equatable {
  final String hostName;
  final String ipAddress;
  final String subnetMask;
  final bool isDHCPEnabled;
  final String firstIPAddress;
  final String lastIPAddress;
  final int maxUserLimit;
  final int maxUserAllowed;
  final int clientLeaseTime;
  final int minAllowDHCPLeaseMinutes;
  final int maxAllowDHCPLeaseMinutes;
  final int minNetworkPrefixLength;
  final int maxNetworkPrefixLength;
  final String? dns1;
  final String? dns2;
  final String? dns3;
  final String? wins;
  final List<DHCPReservation> dhcpReservationList;
  final Map<String, String> errorTextMap;
  final bool hasErrorOnHostNameTab;
  final bool hasErrorOnIPAddressTab;
  final bool hasErrorOnDhcpServerTab;
  final String? hostNameInvalidChars;

  @override
  List<Object?> get props {
    return [
      hostName,
      ipAddress,
      subnetMask,
      isDHCPEnabled,
      firstIPAddress,
      lastIPAddress,
      maxUserLimit,
      maxUserAllowed,
      clientLeaseTime,
      minAllowDHCPLeaseMinutes,
      maxAllowDHCPLeaseMinutes,
      minNetworkPrefixLength,
      maxNetworkPrefixLength,
      dns1,
      dns2,
      dns3,
      wins,
      dhcpReservationList,
      errorTextMap,
      hasErrorOnHostNameTab,
      hasErrorOnIPAddressTab,
      hasErrorOnDhcpServerTab,
      hostNameInvalidChars,
    ];
  }

  const LocalNetworkSettingsState({
    required this.hostName,
    required this.ipAddress,
    required this.subnetMask,
    required this.isDHCPEnabled,
    required this.firstIPAddress,
    required this.lastIPAddress,
    required this.maxUserLimit,
    required this.maxUserAllowed,
    required this.clientLeaseTime,
    required this.minAllowDHCPLeaseMinutes,
    required this.maxAllowDHCPLeaseMinutes,
    required this.minNetworkPrefixLength,
    required this.maxNetworkPrefixLength,
    this.dns1,
    this.dns2,
    this.dns3,
    this.wins,
    this.dhcpReservationList = const [],
    this.errorTextMap = const {},
    this.hasErrorOnHostNameTab = false,
    this.hasErrorOnIPAddressTab = false,
    this.hasErrorOnDhcpServerTab = false,
    this.hostNameInvalidChars,
  });

  factory LocalNetworkSettingsState.init() => const LocalNetworkSettingsState(
        hostName: '',
        ipAddress: '',
        subnetMask: '',
        isDHCPEnabled: false,
        firstIPAddress: '',
        lastIPAddress: '',
        maxUserLimit: 0,
        maxUserAllowed: 0,
        clientLeaseTime: 0,
        minAllowDHCPLeaseMinutes: 0,
        maxAllowDHCPLeaseMinutes: 0,
        minNetworkPrefixLength: 8,
        maxNetworkPrefixLength: 30,
      );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hostName': hostName,
      'ipAddress': ipAddress,
      'subnetMask': subnetMask,
      'isDHCPEnabled': isDHCPEnabled,
      'firstIPAddress': firstIPAddress,
      'lastIPAddress': lastIPAddress,
      'maxUserLimit': maxUserLimit,
      'maxUserAllowed': maxUserAllowed,
      'clientLeaseTime': clientLeaseTime,
      'minAllowDHCPLeaseMinutes': minAllowDHCPLeaseMinutes,
      'maxAllowDHCPLeaseMinutes': maxAllowDHCPLeaseMinutes,
      'minNetworkPrefixLength': minNetworkPrefixLength,
      'maxNetworkPrefixLength': maxNetworkPrefixLength,
      'dns1': dns1,
      'dns2': dns2,
      'dns3': dns3,
      'wins': wins,
      'dhcpReservationList': dhcpReservationList.map((x) => x.toMap()).toList(),
      'errorTextMap': errorTextMap,
      'hasErrorOnHostNameTab': hasErrorOnHostNameTab,
      'hasErrorOnIPAddressTab': hasErrorOnIPAddressTab,
      'hasErrorOnDhcpServerTab': hasErrorOnDhcpServerTab,
      'hostNameInvalidChars': hostNameInvalidChars,
    };
  }

  factory LocalNetworkSettingsState.fromMap(Map<String, dynamic> map) {
    return LocalNetworkSettingsState(
      hostName: map['hostName'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
      subnetMask: map['subnetMask'] ?? '',
      isDHCPEnabled: map['isDHCPEnabled'] ?? false,
      firstIPAddress: map['firstIPAddress'] ?? '',
      lastIPAddress: map['lastIPAddress'] ?? '',
      maxUserLimit: map['maxUserLimit']?.toInt() ?? 0,
      maxUserAllowed: map['maxUserAllowed']?.toInt() ?? 0,
      clientLeaseTime: map['clientLeaseTime']?.toInt() ?? 0,
      minAllowDHCPLeaseMinutes: map['minAllowDHCPLeaseMinutes']?.toInt() ?? 0,
      maxAllowDHCPLeaseMinutes: map['maxAllowDHCPLeaseMinutes']?.toInt() ?? 0,
      minNetworkPrefixLength: map['minNetworkPrefixLength']?.toInt() ?? 0,
      maxNetworkPrefixLength: map['maxNetworkPrefixLength']?.toInt() ?? 0,
      dns1: map['dns1'],
      dns2: map['dns2'],
      dns3: map['dns3'],
      wins: map['wins'],
      dhcpReservationList: List<DHCPReservation>.from(
          map['dhcpReservationList']?.map((x) => DHCPReservation.fromMap(x))),
      errorTextMap: Map<String, String>.from(map['errorTextMap'] ?? {}),
      hasErrorOnHostNameTab: map['hasErrorOnHostNameTab'] ?? false,
      hasErrorOnIPAddressTab: map['hasErrorOnIPAddressTab'] ?? false,
      hasErrorOnDhcpServerTab: map['hasErrorOnDhcpServerTab'] ?? false,
      hostNameInvalidChars: map['hostNameInvalidChars'],
    );
  }

  String toJson() => json.encode(toMap());

  factory LocalNetworkSettingsState.fromJson(String source) =>
      LocalNetworkSettingsState.fromMap(json.decode(source));

  bool isEqualStateWithoutDhcpReservationList(
      LocalNetworkSettingsState compareState) {
    final stateWithoutList = copyWith(dhcpReservationList: []);
    final compareStateWithoutList =
        compareState.copyWith(dhcpReservationList: []);
    return stateWithoutList == compareStateWithoutList;
  }

  @override
  bool get stringify => true;

  LocalNetworkSettingsState copyWith({
    String? hostName,
    String? ipAddress,
    String? subnetMask,
    bool? isDHCPEnabled,
    String? firstIPAddress,
    String? lastIPAddress,
    int? maxUserLimit,
    int? maxUserAllowed,
    int? clientLeaseTime,
    int? minAllowDHCPLeaseMinutes,
    int? maxAllowDHCPLeaseMinutes,
    int? minNetworkPrefixLength,
    int? maxNetworkPrefixLength,
    ValueGetter<String?>? dns1,
    ValueGetter<String?>? dns2,
    ValueGetter<String?>? dns3,
    ValueGetter<String?>? wins,
    List<DHCPReservation>? dhcpReservationList,
    Map<String, String>? errorTextMap,
    bool? hasErrorOnHostNameTab,
    bool? hasErrorOnIPAddressTab,
    bool? hasErrorOnDhcpServerTab,
    ValueGetter<String?>? hostNameInvalidChars,
  }) {
    return LocalNetworkSettingsState(
      hostName: hostName ?? this.hostName,
      ipAddress: ipAddress ?? this.ipAddress,
      subnetMask: subnetMask ?? this.subnetMask,
      isDHCPEnabled: isDHCPEnabled ?? this.isDHCPEnabled,
      firstIPAddress: firstIPAddress ?? this.firstIPAddress,
      lastIPAddress: lastIPAddress ?? this.lastIPAddress,
      maxUserLimit: maxUserLimit ?? this.maxUserLimit,
      maxUserAllowed: maxUserAllowed ?? this.maxUserAllowed,
      clientLeaseTime: clientLeaseTime ?? this.clientLeaseTime,
      minAllowDHCPLeaseMinutes:
          minAllowDHCPLeaseMinutes ?? this.minAllowDHCPLeaseMinutes,
      maxAllowDHCPLeaseMinutes:
          maxAllowDHCPLeaseMinutes ?? this.maxAllowDHCPLeaseMinutes,
      minNetworkPrefixLength:
          minNetworkPrefixLength ?? this.minNetworkPrefixLength,
      maxNetworkPrefixLength:
          maxNetworkPrefixLength ?? this.maxNetworkPrefixLength,
      dns1: dns1 != null ? dns1() : this.dns1,
      dns2: dns2 != null ? dns2() : this.dns2,
      dns3: dns3 != null ? dns3() : this.dns3,
      wins: wins != null ? wins() : this.wins,
      dhcpReservationList: dhcpReservationList ?? this.dhcpReservationList,
      errorTextMap: errorTextMap ?? this.errorTextMap,
      hasErrorOnHostNameTab:
          hasErrorOnHostNameTab ?? this.hasErrorOnHostNameTab,
      hasErrorOnIPAddressTab:
          hasErrorOnIPAddressTab ?? this.hasErrorOnIPAddressTab,
      hasErrorOnDhcpServerTab:
          hasErrorOnDhcpServerTab ?? this.hasErrorOnDhcpServerTab,
      hostNameInvalidChars: hostNameInvalidChars != null
          ? hostNameInvalidChars()
          : this.hostNameInvalidChars,
    );
  }

  @override
  String toString() {
    return 'LocalNetworkSettingsState(hostName: $hostName, ipAddress: $ipAddress, subnetMask: $subnetMask, isDHCPEnabled: $isDHCPEnabled, firstIPAddress: $firstIPAddress, lastIPAddress: $lastIPAddress, maxUserLimit: $maxUserLimit, maxUserAllowed: $maxUserAllowed, clientLeaseTime: $clientLeaseTime, minAllowDHCPLeaseMinutes: $minAllowDHCPLeaseMinutes, maxAllowDHCPLeaseMinutes: $maxAllowDHCPLeaseMinutes, minNetworkPrefixLength: $minNetworkPrefixLength, maxNetworkPrefixLength: $maxNetworkPrefixLength, dns1: $dns1, dns2: $dns2, dns3: $dns3, wins: $wins, dhcpReservationList: $dhcpReservationList, errorTextMap: $errorTextMap, hasErrorOnHostNameTab: $hasErrorOnHostNameTab, hasErrorOnIPAddressTab: $hasErrorOnIPAddressTab, hasErrorOnDhcpServerTab: $hasErrorOnDhcpServerTab)';
  }
}
