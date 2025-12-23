import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for InstantSafetyService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class InstantSafetyTestData {
  // DNS Configuration Constants (matching service)
  static const fortinetDns1 = '208.91.114.155';
  static const openDnsDns1 = '208.67.222.123';
  static const openDnsDns2 = '208.67.220.123';

  /// Create default LAN settings response with no safe browsing configured
  static JNAPSuccess createLANSettingsSuccess({
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
    String ipAddress = '192.168.1.1',
    int networkPrefixLength = 24,
    String hostName = 'Linksys00001',
    bool isDHCPEnabled = true,
    String firstClientIPAddress = '192.168.1.100',
    String lastClientIPAddress = '192.168.1.254',
    int leaseMinutes = 1440,
  }) {
    final dhcpSettings = <String, dynamic>{
      'firstClientIPAddress': firstClientIPAddress,
      'lastClientIPAddress': lastClientIPAddress,
      'leaseMinutes': leaseMinutes,
      'reservations': <Map<String, dynamic>>[],
    };

    if (dnsServer1 != null) dhcpSettings['dnsServer1'] = dnsServer1;
    if (dnsServer2 != null) dhcpSettings['dnsServer2'] = dnsServer2;
    if (dnsServer3 != null) dhcpSettings['dnsServer3'] = dnsServer3;

    return JNAPSuccess(
      result: 'OK',
      output: {
        'ipAddress': ipAddress,
        'networkPrefixLength': networkPrefixLength,
        'hostName': hostName,
        'isDHCPEnabled': isDHCPEnabled,
        'dhcpSettings': dhcpSettings,
        'minNetworkPrefixLength': 16,
        'maxNetworkPrefixLength': 30,
        'minAllowedDHCPLeaseMinutes': 1,
        'maxDHCPReservationDescriptionLength': 63,
      },
    );
  }

  /// Create LAN settings response with Fortinet DNS configured
  static JNAPSuccess createLANSettingsWithFortinet({
    String ipAddress = '192.168.1.1',
  }) {
    return createLANSettingsSuccess(
      dnsServer1: fortinetDns1,
      ipAddress: ipAddress,
    );
  }

  /// Create LAN settings response with OpenDNS configured
  static JNAPSuccess createLANSettingsWithOpenDNS({
    String ipAddress = '192.168.1.1',
  }) {
    return createLANSettingsSuccess(
      dnsServer1: openDnsDns1,
      dnsServer2: openDnsDns2,
      ipAddress: ipAddress,
    );
  }

  /// Create LAN settings response with no safe browsing (off)
  static JNAPSuccess createLANSettingsWithSafeBrowsingOff({
    String ipAddress = '192.168.1.1',
  }) {
    return createLANSettingsSuccess(
      ipAddress: ipAddress,
    );
  }

  /// Create device info map for compatibility testing
  static Map<String, dynamic> createDeviceInfo({
    String modelNumber = 'MR9600',
    String firmwareVersion = '1.0.0.0',
    String hardwareVersion = '1',
    String manufacturer = 'Linksys',
    String serialNumber = 'ABC123456789',
  }) {
    return {
      'modelNumber': modelNumber,
      'firmwareVersion': firmwareVersion,
      'hardwareVersion': hardwareVersion,
      'manufacturer': manufacturer,
      'serialNumber': serialNumber,
      'description': 'Linksys Router',
      'firmwareDate': '2024-01-01T00:00:00Z',
      'services': <String>[],
    };
  }

  /// Create JNAP error response
  static JNAPError createJNAPError({
    String result = '_ErrorUnknown',
    String error = 'Unknown error occurred',
  }) {
    return JNAPError(result: result, error: error);
  }
}
