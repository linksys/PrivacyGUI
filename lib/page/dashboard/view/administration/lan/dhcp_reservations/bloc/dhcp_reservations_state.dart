import 'package:equatable/equatable.dart';

class DHCPReservationsState extends Equatable {
  final String ipAddress;
  final String subnetMask;
  final bool isDHCPEnabled;
  final String firstIPAddress;
  final String lastIPAddress;
  final int maxNumUsers;
  final int clientLeaseTime;
  final int maxAllowDHCPLeaseMinutes;
  final int minAllowDHCPLeaseMinutes;
  final int minNetworkPrefixLength;
  final int maxNetworkPrefixLength;
  final bool isAutoDNS;
  final String? dns1;
  final String? dns2;
  final String? dns3;
  final Map<String, String> errors;

  @override
  List<Object?> get props => [
        ipAddress,
        subnetMask,
        isDHCPEnabled,
        firstIPAddress,
        lastIPAddress,
        maxNumUsers,
        clientLeaseTime,
        maxAllowDHCPLeaseMinutes,
        minAllowDHCPLeaseMinutes,
        minNetworkPrefixLength,
        maxNetworkPrefixLength,
        isAutoDNS,
        dns1,
        dns2,
        dns3,
        errors,
      ];

  const DHCPReservationsState({
    required this.ipAddress,
    required this.subnetMask,
    required this.isDHCPEnabled,
    required this.firstIPAddress,
    required this.lastIPAddress,
    required this.maxNumUsers,
    required this.clientLeaseTime,
    required this.maxAllowDHCPLeaseMinutes,
    required this.minAllowDHCPLeaseMinutes,
    required this.minNetworkPrefixLength,
    required this.maxNetworkPrefixLength,
    required this.isAutoDNS,
    this.dns1,
    this.dns2,
    this.dns3,
    this.errors = const {},
  });

  factory DHCPReservationsState.init() {
    return const DHCPReservationsState(
      ipAddress: '',
      subnetMask: '',
      isDHCPEnabled: false,
      firstIPAddress: '',
      lastIPAddress: '',
      maxNumUsers: 0,
      clientLeaseTime: 0,
      maxAllowDHCPLeaseMinutes: 0,
      minAllowDHCPLeaseMinutes: 0,
      minNetworkPrefixLength: 8,
      maxNetworkPrefixLength: 30,
      isAutoDNS: false,
      dns1: '',
      dns2: '',
      dns3: '',
      errors: {},
    );
  }

  DHCPReservationsState copyWith({
    String? ipAddress,
    String? subnetMask,
    bool? isDHCPEnabled,
    String? firstIPAddress,
    String? lastIPAddress,
    int? maxNumUsers,
    int? clientLeaseTime,
    int? maxAllowDHCPLeaseMinutes,
    int? minAllowDHCPLeaseMinutes,
    int? minNetworkPrefixLength,
    int? maxNetworkPrefixLength,
    bool? isAutoDNS,
    String? dns1,
    String? dns2,
    String? dns3,
    Map<String, String>? errors,
  }) {
    return DHCPReservationsState(
      ipAddress: ipAddress ?? this.ipAddress,
      subnetMask: subnetMask ?? this.subnetMask,
      isDHCPEnabled: isDHCPEnabled ?? this.isDHCPEnabled,
      firstIPAddress: firstIPAddress ?? this.firstIPAddress,
      lastIPAddress: lastIPAddress ?? this.lastIPAddress,
      maxNumUsers: maxNumUsers ?? this.maxNumUsers,
      clientLeaseTime: clientLeaseTime ?? this.clientLeaseTime,
      maxAllowDHCPLeaseMinutes:
          maxAllowDHCPLeaseMinutes ?? this.maxAllowDHCPLeaseMinutes,
      minAllowDHCPLeaseMinutes:
          minAllowDHCPLeaseMinutes ?? this.minAllowDHCPLeaseMinutes,
      minNetworkPrefixLength:
          minNetworkPrefixLength ?? this.minNetworkPrefixLength,
      maxNetworkPrefixLength:
          maxNetworkPrefixLength ?? this.maxNetworkPrefixLength,
      isAutoDNS: isAutoDNS ?? this.isAutoDNS,
      dns1: dns1 ?? this.dns1,
      dns2: dns2 ?? this.dns2,
      dns3: dns3 ?? this.dns3,
      errors: errors ?? this.errors,
    );
  }
}
