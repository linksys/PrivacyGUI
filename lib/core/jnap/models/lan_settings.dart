// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

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
  List<Object?> get props {
    return [
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
  }

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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'minNetworkPrefixLength': minNetworkPrefixLength,
      'maxNetworkPrefixLength': maxNetworkPrefixLength,
      'minAllowedDHCPLeaseMinutes': minAllowedDHCPLeaseMinutes,
      'dhcpSettings': dhcpSettings.toMap(),
      'hostName': hostName,
      'maxDHCPReservationDescriptionLength': maxDHCPReservationDescriptionLength,
      'isDHCPEnabled': isDHCPEnabled,
      'networkPrefixLength': networkPrefixLength,
      'ipAddress': ipAddress,
      'maxAllowedDHCPLeaseMinutes': maxAllowedDHCPLeaseMinutes,
    }..removeWhere((key, value) => value == null);
  }

  factory RouterLANSettings.fromMap(Map<String, dynamic> map) {
    return RouterLANSettings(
      minNetworkPrefixLength: map['minNetworkPrefixLength'] as int,
      maxNetworkPrefixLength: map['maxNetworkPrefixLength'] as int,
      minAllowedDHCPLeaseMinutes: map['minAllowedDHCPLeaseMinutes'] as int,
      dhcpSettings: DHCPSettings.fromMap(map['dhcpSettings'] as Map<String,dynamic>),
      hostName: map['hostName'] as String,
      maxDHCPReservationDescriptionLength: map['maxDHCPReservationDescriptionLength'] as int,
      isDHCPEnabled: map['isDHCPEnabled'] as bool,
      networkPrefixLength: map['networkPrefixLength'] as int,
      ipAddress: map['ipAddress'] as String,
      maxAllowedDHCPLeaseMinutes: map['maxAllowedDHCPLeaseMinutes'] != null ? map['maxAllowedDHCPLeaseMinutes'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RouterLANSettings.fromJson(String source) => RouterLANSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
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
  List<Object?> get props {
    return [
      lastClientIPAddress,
      leaseMinutes,
      reservations,
      firstClientIPAddress,
      dnsServer1,
      dnsServer2,
      dnsServer3,
      winsServer,
      firstClientIPAddress,
    ];
  }

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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lastClientIPAddress': lastClientIPAddress,
      'leaseMinutes': leaseMinutes,
      'reservations': reservations.map((x) => x.toMap()).toList(),
      'firstClientIPAddress': firstClientIPAddress,
      'dnsServer1': dnsServer1,
      'dnsServer2': dnsServer2,
      'dnsServer3': dnsServer3,
      'winsServer': winsServer,
    }..removeWhere((key, value) => value == null);
  }

  factory DHCPSettings.fromMap(Map<String, dynamic> map) {
    return DHCPSettings(
      lastClientIPAddress: map['lastClientIPAddress'] as String,
      leaseMinutes: map['leaseMinutes'] as int,
      reservations: List<DHCPReservation>.from((map['reservations']).map<DHCPReservation>((x) => DHCPReservation.fromMap(x as Map<String,dynamic>),),),
      firstClientIPAddress: map['firstClientIPAddress'] as String,
      dnsServer1: map['dnsServer1'] != null ? map['dnsServer1'] as String : null,
      dnsServer2: map['dnsServer2'] != null ? map['dnsServer2'] as String : null,
      dnsServer3: map['dnsServer3'] != null ? map['dnsServer3'] as String : null,
      winsServer: map['winsServer'] != null ? map['winsServer'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DHCPSettings.fromJson(String source) => DHCPSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class DHCPReservation extends Equatable {
  final String macAddress;
  final String ipAddress;
  final String description;

  @override
  List<Object> get props => [macAddress, ipAddress, description];

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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'macAddress': macAddress,
      'ipAddress': ipAddress,
      'description': description,
    };
  }

  factory DHCPReservation.fromMap(Map<String, dynamic> map) {
    return DHCPReservation(
      macAddress: map['macAddress'] as String,
      ipAddress: map['ipAddress'] as String,
      description: map['description'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory DHCPReservation.fromJson(String source) =>
      DHCPReservation.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
