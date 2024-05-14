// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';

// {
//   "ipAddress": "192.0.2.1",
//   "networkPrefixLength": 24,
//   "hostName": "myrouter",
//   "isDHCPEnabled": true,
//   "dhcpSettings": {
//     "leaseMinutes": 1440,
//     "firstClientIPAddress": "192.0.2.100",
//     "lastClientIPAddress": "192.0.2.150",
//     "dnsServer1": "203.0.113.103",
//     "reservations": [
//       {
//         "macAddress": "00:22:5F:A1:73:C1",
//         "ipAddress": "192.0.2.99",
//         "description": "webcam"
//       }
//     ]
//   }
// }

class SetRouterLANSettings extends Equatable {
  final String ipAddress;
  final int networkPrefixLength;
  final String hostName;
  final bool isDHCPEnabled;
  final DHCPSettings? dhcpSettings;

  const SetRouterLANSettings({
    required this.ipAddress,
    required this.networkPrefixLength,
    required this.hostName,
    required this.isDHCPEnabled,
    this.dhcpSettings,
  });

  @override
  List<Object?> get props {
    return [
      ipAddress,
      networkPrefixLength,
      hostName,
      isDHCPEnabled,
      dhcpSettings,
    ];
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ipAddress': ipAddress,
      'networkPrefixLength': networkPrefixLength,
      'hostName': hostName,
      'isDHCPEnabled': isDHCPEnabled,
      'dhcpSettings': dhcpSettings?.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  factory SetRouterLANSettings.fromMap(Map<String, dynamic> map) {
    return SetRouterLANSettings(
      ipAddress: map['ipAddress'] as String,
      networkPrefixLength: map['networkPrefixLength'] as int,
      hostName: map['hostName'] as String,
      isDHCPEnabled: map['isDHCPEnabled'] as bool,
      dhcpSettings: map['dhcpSettings'] != null
          ? DHCPSettings.fromMap(map['dhcpSettings'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SetRouterLANSettings.fromJson(String source) =>
      SetRouterLANSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  SetRouterLANSettings copyWith({
    String? ipAddress,
    int? networkPrefixLength,
    String? hostName,
    bool? isDHCPEnabled,
    DHCPSettings? dhcpSettings,
  }) {
    return SetRouterLANSettings(
      ipAddress: ipAddress ?? this.ipAddress,
      networkPrefixLength: networkPrefixLength ?? this.networkPrefixLength,
      hostName: hostName ?? this.hostName,
      isDHCPEnabled: isDHCPEnabled ?? this.isDHCPEnabled,
      dhcpSettings: dhcpSettings ?? this.dhcpSettings,
    );
  }
}
