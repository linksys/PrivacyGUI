import 'package:equatable/equatable.dart';

///
/// {
///   "minNetworkPrefixLength": 16,
///   "maxNetworkPrefixLength": 30,
///   "minAllowedDHCPLeaseMinutes": 1,
///   "dhcpSettings": {
///     "lastClientIPAddress": "10.135.1.254",
///     "leaseMinutes": 1440,
///     "reservations": [
///
///     ],
///     "firstClientIPAddress": "10.135.1.10"
///   },
///   "hostName": "Linksys00005",
///   "maxDHCPReservationDescriptionLength": 63,
///   "isDHCPEnabled": true,
///   "networkPrefixLength": 24,
///   "ipAddress": "10.135.1.1",
///   "maxAllowedDHCPLeaseMinutes": 525600
/// }
///
class RouterLANSettings extends Equatable {
  final int minNetworkPrefixLength;
  final int maxNetworkPrefixLength;
  final int minAllowedDHCPLeaseMinutes;
  final DHCPSettings dhcpSettings;
  final String hostName;
  final int maxDHCPReservationDescriptionLength;
  final bool isDHCPEnabled;
  final int networkPrefixLength;
  final String ipAddress;
  final int? maxAllowedDHCPLeaseMinutes;

  @override
  List<Object?> get props => [
        minNetworkPrefixLength,
        maxNetworkPrefixLength,
        minAllowedDHCPLeaseMinutes,
        dhcpSettings,
        hostName,
        maxDHCPReservationDescriptionLength,
        isDHCPEnabled,
        networkPrefixLength,
        ipAddress,
        maxAllowedDHCPLeaseMinutes,
      ];

  const RouterLANSettings({
    required this.minNetworkPrefixLength,
    required this.maxNetworkPrefixLength,
    required this.minAllowedDHCPLeaseMinutes,
    required this.dhcpSettings,
    required this.hostName,
    required this.maxDHCPReservationDescriptionLength,
    required this.isDHCPEnabled,
    required this.networkPrefixLength,
    required this.ipAddress,
    this.maxAllowedDHCPLeaseMinutes,
  });

  RouterLANSettings copyWith({
    int? minNetworkPrefixLength,
    int? maxNetworkPrefixLength,
    int? minAllowedDHCPLeaseMinutes,
    DHCPSettings? dhcpSettings,
    String? hostName,
    int? maxDHCPReservationDescriptionLength,
    bool? isDHCPEnabled,
    int? networkPrefixLength,
    String? ipAddress,
    int? maxAllowedDHCPLeaseMinutes,
  }) {
    return RouterLANSettings(
      minNetworkPrefixLength:
          minNetworkPrefixLength ?? this.minNetworkPrefixLength,
      maxNetworkPrefixLength:
          maxNetworkPrefixLength ?? this.maxNetworkPrefixLength,
      minAllowedDHCPLeaseMinutes:
          minAllowedDHCPLeaseMinutes ?? this.minAllowedDHCPLeaseMinutes,
      dhcpSettings: dhcpSettings ?? this.dhcpSettings,
      hostName: hostName ?? this.hostName,
      maxDHCPReservationDescriptionLength:
          maxDHCPReservationDescriptionLength ??
              this.maxDHCPReservationDescriptionLength,
      isDHCPEnabled: isDHCPEnabled ?? this.isDHCPEnabled,
      networkPrefixLength: networkPrefixLength ?? this.networkPrefixLength,
      ipAddress: ipAddress ?? this.ipAddress,
      maxAllowedDHCPLeaseMinutes:
          maxAllowedDHCPLeaseMinutes ?? this.maxAllowedDHCPLeaseMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minNetworkPrefixLength': minNetworkPrefixLength,
      'maxNetworkPrefixLength': maxNetworkPrefixLength,
      'minAllowedDHCPLeaseMinutes': minAllowedDHCPLeaseMinutes,
      'dhcpSettings': dhcpSettings.toJson(),
      'hostName': hostName,
      'maxDHCPReservationDescriptionLength':
          maxDHCPReservationDescriptionLength,
      'isDHCPEnabled': isDHCPEnabled,
      'networkPrefixLength': networkPrefixLength,
      'ipAddress': ipAddress,
      'maxAllowedDHCPLeaseMinutes': maxAllowedDHCPLeaseMinutes,
    }..removeWhere((key, value) => value == null);
  }

  factory RouterLANSettings.fromJson(Map<String, dynamic> json) {
    return RouterLANSettings(
      minNetworkPrefixLength: json['minNetworkPrefixLength'],
      maxNetworkPrefixLength: json['maxNetworkPrefixLength'],
      minAllowedDHCPLeaseMinutes: json['minAllowedDHCPLeaseMinutes'],
      dhcpSettings: DHCPSettings.fromJson(json['dhcpSettings']),
      hostName: json['hostName'],
      maxDHCPReservationDescriptionLength:
          json['maxDHCPReservationDescriptionLength'],
      isDHCPEnabled: json['isDHCPEnabled'],
      networkPrefixLength: json['networkPrefixLength'],
      ipAddress: json['ipAddress'],
      maxAllowedDHCPLeaseMinutes: json['maxAllowedDHCPLeaseMinutes'],
    );
  }
}

class DHCPSettings extends Equatable {
  final String lastClientIPAddress;
  final int leaseMinutes;
  final List<DHCPReservation> reservations;
  final String firstClientIPAddress;
  final String? dnsServer1;
  final String? dnsServer2;
  final String? dnsServer3;
  final String? winsServer;

  @override
  List<Object?> get props =>
      [lastClientIPAddress, leaseMinutes, reservations, firstClientIPAddress];

  const DHCPSettings({
    required this.lastClientIPAddress,
    required this.leaseMinutes,
    required this.reservations,
    required this.firstClientIPAddress,
    this.dnsServer1,
    this.dnsServer2,
    this.dnsServer3,
    this.winsServer,
  });

  DHCPSettings copyWith({
    String? lastClientIPAddress,
    int? leaseMinutes,
    List<DHCPReservation>? reservations,
    String? firstClientIPAddress,
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
    String? winsServer,
  }) {
    return DHCPSettings(
      lastClientIPAddress: lastClientIPAddress ?? this.lastClientIPAddress,
      leaseMinutes: leaseMinutes ?? this.leaseMinutes,
      reservations: reservations ?? this.reservations,
      firstClientIPAddress: firstClientIPAddress ?? this.firstClientIPAddress,
      dnsServer1: dnsServer1 ?? this.dnsServer1,
      dnsServer2: dnsServer2 ?? this.dnsServer2,
      dnsServer3: dnsServer3 ?? this.dnsServer3,
      winsServer: winsServer ?? this.winsServer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastClientIPAddress': lastClientIPAddress,
      'leaseMinutes': leaseMinutes,
      'reservations': reservations.map((e) => e.toJson()).toList(),
      'firstClientIPAddress': firstClientIPAddress,
      'dnsServer1': dnsServer1,
      'dnsServer2': dnsServer2,
      'dnsServer3': dnsServer3,
      'winsServer': winsServer,
    }..removeWhere((key, value) => value == null);
  }

  factory DHCPSettings.fromJson(Map<String, dynamic> json) {
    return DHCPSettings(
      lastClientIPAddress: json['lastClientIPAddress'],
      leaseMinutes: json['leaseMinutes'],
      reservations: List.from(json['reservations'])
          .map((e) => DHCPReservation.fromJson(e))
          .toList(),
      firstClientIPAddress: json['firstClientIPAddress'],
      dnsServer1: json['dnsServer1'],
      dnsServer2: json['dnsServer2'],
      dnsServer3: json['dnsServer3'],
      winsServer: json['winsServer'],
    );
  }
}

class DHCPReservation extends Equatable {
  final String macAddress;
  final String ipAddress;
  final String description;

  @override
  List<Object?> get props => [macAddress, ipAddress, description];

  const DHCPReservation({
    required this.macAddress,
    required this.ipAddress,
    required this.description,
  });

  DHCPReservation copyWith({
    String? macAddress,
    String? ipAddress,
    String? description,
  }) {
    return DHCPReservation(
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macAddress': macAddress,
      'ipAddress': ipAddress,
      'description': description,
    };
  }

  factory DHCPReservation.fromJson(Map<String, dynamic> json) {
    return DHCPReservation(
      macAddress: json['macAddress'],
      ipAddress: json['ipAddress'],
      description: json['description'],
    );
  }
}
