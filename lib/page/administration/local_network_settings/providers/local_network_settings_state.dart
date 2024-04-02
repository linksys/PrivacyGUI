import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';

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

  @override
  List<Object?> get props => [
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
        // isAutoDNS,
      ];

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
    String? dns1,
    String? dns2,
    String? dns3,
    String? wins,
    List<DHCPReservation>? dhcpReservationList,
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
      dns1: dns1 ?? this.dns1,
      dns2: dns2 ?? this.dns2,
      dns3: dns3 ?? this.dns3,
      wins: wins ?? this.wins,
      dhcpReservationList: dhcpReservationList ?? this.dhcpReservationList,
    );
  }
}
