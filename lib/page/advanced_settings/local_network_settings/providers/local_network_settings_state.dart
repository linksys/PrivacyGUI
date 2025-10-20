// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/feature_state.dart';
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
    return LocalNetworkErrorPrompt.values
        .firstWhereOrNull((element) => element.name == error);
  }

  static String? getErrorText(
      {required BuildContext context,
      LocalNetworkErrorPrompt? error,
      String? ipAddress,
      String? subnetMask}) {
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
  final List<DHCPReservation> dhcpReservationList;
  final Map<String, String> errorTextMap;
  final bool hasErrorOnHostNameTab;
  final bool hasErrorOnIPAddressTab;
  final bool hasErrorOnDhcpServerTab;

  @override
  List<Object?> get props {
    return [
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
      dhcpReservationList,
      errorTextMap,
      hasErrorOnHostNameTab,
      hasErrorOnIPAddressTab,
      hasErrorOnDhcpServerTab,
    ];
  }

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
    this.dhcpReservationList = const [],
    this.errorTextMap = const {},
    this.hasErrorOnHostNameTab = false,
    this.hasErrorOnIPAddressTab = false,
    this.hasErrorOnDhcpServerTab = false,
  });

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
      'dhcpReservationList':
          dhcpReservationList.map((x) => x.toMap()).toList(),
      'errorTextMap': errorTextMap,
      'hasErrorOnHostNameTab': hasErrorOnHostNameTab,
      'hasErrorOnIPAddressTab': hasErrorOnIPAddressTab,
      'hasErrorOnDhcpServerTab': hasErrorOnDhcpServerTab,
    };
  }

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
    List<DHCPReservation>? dhcpReservationList,
    Map<String, String>? errorTextMap,
    bool? hasErrorOnHostNameTab,
    bool? hasErrorOnIPAddressTab,
    bool? hasErrorOnDhcpServerTab,
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
      dhcpReservationList:
          dhcpReservationList ?? this.dhcpReservationList,
      errorTextMap: errorTextMap ?? this.errorTextMap,
      hasErrorOnHostNameTab:
          hasErrorOnHostNameTab ?? this.hasErrorOnHostNameTab,
      hasErrorOnIPAddressTab:
          hasErrorOnIPAddressTab ?? this.hasErrorOnIPAddressTab,
      hasErrorOnDhcpServerTab:
          hasErrorOnDhcpServerTab ?? this.hasErrorOnDhcpServerTab,
    );
  }
}

class LocalNetworkStatus extends Equatable {
  final int maxUserLimit;
  final int minAllowDHCPLeaseMinutes;
  final int maxAllowDHCPLeaseMinutes;
  final int minNetworkPrefixLength;
  final int maxNetworkPrefixLength;

  const LocalNetworkStatus({
    required this.maxUserLimit,
    required this.minAllowDHCPLeaseMinutes,
    required this.maxAllowDHCPLeaseMinutes,
    required this.minNetworkPrefixLength,
    required this.maxNetworkPrefixLength,
  });

  @override
  List<Object?> get props => [
        maxUserLimit,
        minAllowDHCPLeaseMinutes,
        maxAllowDHCPLeaseMinutes,
        minNetworkPrefixLength,
        maxNetworkPrefixLength,
      ];

  Map<String, dynamic> toMap() {
    return {
      'maxUserLimit': maxUserLimit,
      'minAllowDHCPLeaseMinutes': minAllowDHCPLeaseMinutes,
      'maxAllowDHCPLeaseMinutes': maxAllowDHCPLeaseMinutes,
      'minNetworkPrefixLength': minNetworkPrefixLength,
      'maxNetworkPrefixLength': maxNetworkPrefixLength,
    };
  }
}

class LocalNetworkSettingsState
    extends FeatureState<LocalNetworkSettings, LocalNetworkStatus> {
  const LocalNetworkSettingsState({
    required super.settings,
    required super.status,
  });

  factory LocalNetworkSettingsState.init() => const LocalNetworkSettingsState(
        settings: LocalNetworkSettings(
          hostName: '',
          ipAddress: '',
          subnetMask: '',
          isDHCPEnabled: false,
          firstIPAddress: '',
          lastIPAddress: '',
          maxUserAllowed: 0,
          clientLeaseTime: 0,
        ),
        status: LocalNetworkStatus(
          maxUserLimit: 0,
          minAllowDHCPLeaseMinutes: 0,
          maxAllowDHCPLeaseMinutes: 0,
          minNetworkPrefixLength: 8,
          maxNetworkPrefixLength: 30,
        ),
      );

  @override
  LocalNetworkSettingsState copyWith({
    LocalNetworkSettings? settings,
    LocalNetworkStatus? status,
  }) {
    return LocalNetworkSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'settings': settings.toMap(),
      'status': status.toMap(),
    };
  }
}
