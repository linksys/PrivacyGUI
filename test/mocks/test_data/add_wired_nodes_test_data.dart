import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for AddWiredNodesService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class AddWiredNodesTestData {
  /// Create wired auto-onboarding settings success response
  static JNAPSuccess createWiredAutoOnboardingSettingsSuccess({
    bool isEnabled = false,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {'isAutoOnboardingEnabled': isEnabled},
      );

  /// Create backhaul info success response
  static JNAPSuccess createBackhaulInfoSuccess({
    List<Map<String, dynamic>>? devices,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {'backhaulDevices': devices ?? []},
      );

  /// Create getDevices success response
  static JNAPSuccess createDevicesSuccess({
    List<Map<String, dynamic>>? devices,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {'devices': devices ?? []},
      );

  /// Create a backhaul device data map compatible with BackHaulInfoData.fromMap
  ///
  /// BackHaulInfoData requires:
  /// - deviceUUID (String)
  /// - ipAddress (String)
  /// - parentIPAddress (String)
  /// - connectionType (String)
  /// - speedMbps (String)
  /// - timestamp (String)
  static Map<String, dynamic> createBackhaulDevice({
    String deviceUUID = 'test-uuid-123',
    String connectionType = 'Wired',
    String? timestamp,
    String ipAddress = '192.168.1.100',
    String parentIPAddress = '192.168.1.1',
    String speedMbps = '1000',
  }) =>
      {
        'deviceUUID': deviceUUID,
        'connectionType': connectionType,
        'timestamp': timestamp ?? DateTime.now().toIso8601String(),
        'ipAddress': ipAddress,
        'parentIPAddress': parentIPAddress,
        'speedMbps': speedMbps,
      };

  /// Create a complete device map that is compatible with LinksysDevice.fromMap
  ///
  /// This method creates a device with all required nested structures:
  /// - connections (List)
  /// - properties (List)
  /// - unit (Map)
  /// - model (Map)
  /// - knownInterfaces (List)
  static Map<String, dynamic> createDevice({
    String deviceID = 'device-123',
    String? friendlyName,
    String? nodeType = 'Slave',
    bool isAuthority = false,
    List<Map<String, dynamic>>? connections,
    List<Map<String, dynamic>>? knownInterfaces,
  }) =>
      {
        'deviceID': deviceID,
        'friendlyName': friendlyName ?? 'Node-$deviceID',
        if (nodeType != null) 'nodeType': nodeType,
        'isAuthority': isAuthority,
        'lastChangeRevision': 1,
        'maxAllowedProperties': 32,
        'connections': connections ?? <Map<String, dynamic>>[],
        'properties': <Map<String, dynamic>>[],
        'unit': {
          'serialNumber': 'SN-$deviceID',
          'firmwareVersion': '1.0.0',
          'firmwareDate': '2024-01-01',
          'operatingSystem': 'Linux',
        },
        'model': {
          'deviceType': 'Infrastructure',
          'manufacturer': 'Linksys',
          'modelNumber': 'MX5300',
          'hardwareVersion': '1',
          'modelDescription': 'Velop Mesh Router',
        },
        'knownInterfaces': knownInterfaces ?? <Map<String, dynamic>>[],
      };

  /// Create JNAP error
  static JNAPError createJNAPError({String result = 'ErrorUnknown'}) =>
      JNAPError(result: result);
}
