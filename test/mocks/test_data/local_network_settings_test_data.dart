import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for LocalNetworkSettingsService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class LocalNetworkSettingsTestData {
  /// Create default RouterLANSettings success response
  static JNAPSuccess createGetLANSettingsSuccess({
    String ipAddress = '192.168.1.1',
    int networkPrefixLength = 24,
    String hostName = 'TestRouter',
    bool isDHCPEnabled = true,
    String firstClientIP = '192.168.1.100',
    String lastClientIP = '192.168.1.150',
    int leaseMinutes = 1440,
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
    String? winsServer,
    List<Map<String, dynamic>>? reservations,
    int minNetworkPrefixLength = 16,
    int maxNetworkPrefixLength = 30,
    int minAllowedDHCPLeaseMinutes = 1,
    int maxAllowedDHCPLeaseMinutes = 525600,
    int maxDHCPReservationDescriptionLength = 63,
  }) {
    return JNAPSuccess(
      result: 'OK',
      output: {
        'ipAddress': ipAddress,
        'networkPrefixLength': networkPrefixLength,
        'hostName': hostName,
        'isDHCPEnabled': isDHCPEnabled,
        'minNetworkPrefixLength': minNetworkPrefixLength,
        'maxNetworkPrefixLength': maxNetworkPrefixLength,
        'minAllowedDHCPLeaseMinutes': minAllowedDHCPLeaseMinutes,
        'maxAllowedDHCPLeaseMinutes': maxAllowedDHCPLeaseMinutes,
        'maxDHCPReservationDescriptionLength':
            maxDHCPReservationDescriptionLength,
        'dhcpSettings': {
          'firstClientIPAddress': firstClientIP,
          'lastClientIPAddress': lastClientIP,
          'leaseMinutes': leaseMinutes,
          if (dnsServer1 != null) 'dnsServer1': dnsServer1,
          if (dnsServer2 != null) 'dnsServer2': dnsServer2,
          if (dnsServer3 != null) 'dnsServer3': dnsServer3,
          if (winsServer != null) 'winsServer': winsServer,
          'reservations': reservations ?? [],
        },
      },
    );
  }

  /// Create DHCP reservation map for test data
  static Map<String, dynamic> createReservationMap({
    required String macAddress,
    required String ipAddress,
    required String description,
  }) {
    return {
      'macAddress': macAddress,
      'ipAddress': ipAddress,
      'description': description,
    };
  }

  /// Create default test reservations
  static List<Map<String, dynamic>> createDefaultReservations() {
    return [
      createReservationMap(
        macAddress: '00:11:22:33:44:55',
        ipAddress: '192.168.1.10',
        description: 'Test Device 1',
      ),
      createReservationMap(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        ipAddress: '192.168.1.20',
        description: 'Test Device 2',
      ),
    ];
  }

  /// Create empty LAN settings response (no reservations)
  static JNAPSuccess createEmptyLANSettingsSuccess() {
    return createGetLANSettingsSuccess(
      reservations: [],
    );
  }

  /// Create LAN settings response with reservations
  static JNAPSuccess createLANSettingsWithReservations() {
    return createGetLANSettingsSuccess(
      reservations: createDefaultReservations(),
    );
  }
}
