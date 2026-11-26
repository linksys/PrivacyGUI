/// `GetLANSettings` output for the advanced settings tests: 192.168.1.1/24.
const routerLan = <String, dynamic>{
  'minNetworkPrefixLength': 16,
  'maxNetworkPrefixLength': 30,
  'minAllowedDHCPLeaseMinutes': 1,
  'maxDHCPReservationDescriptionLength': 63,
  'hostName': 'Linksys00042',
  'ipAddress': '192.168.1.1',
  'networkPrefixLength': 24,
  'isDHCPEnabled': true,
  'dhcpSettings': {
    'firstClientIPAddress': '192.168.1.100',
    'lastClientIPAddress': '192.168.1.149',
    'leaseMinutes': 1440,
    'reservations': <Map<String, dynamic>>[],
  },
};
