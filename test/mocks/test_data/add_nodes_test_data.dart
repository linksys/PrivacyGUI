import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for AddNodesService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class AddNodesTestData {
  /// Create auto-onboarding settings success response
  static JNAPSuccess createAutoOnboardingSettingsSuccess({
    bool isEnabled = true,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {'isAutoOnboardingEnabled': isEnabled},
      );

  /// Create auto-onboarding status success response
  static JNAPSuccess createAutoOnboardingStatusSuccess({
    String status = 'Idle',
    List<Map<String, dynamic>>? deviceOnboardingStatus,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'autoOnboardingStatus': status,
          'deviceOnboardingStatus': deviceOnboardingStatus ?? [],
        },
      );

  /// Create auto-onboarding status with onboarded devices
  static JNAPSuccess createAutoOnboardingStatusWithDevices({
    String status = 'Complete',
    List<String> onboardedMACs = const [],
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'autoOnboardingStatus': status,
          'deviceOnboardingStatus': onboardedMACs
              .map((mac) => {
                    'btMACAddress': mac,
                    'onboardingStatus': 'Onboarded',
                  })
              .toList(),
        },
      );

  /// Create getDevices success response
  static JNAPSuccess createDevicesSuccess({
    List<Map<String, dynamic>>? devices,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {'devices': devices ?? []},
      );

  /// Create a complete device map that is compatible with LinksysDevice.fromMap
  ///
  /// This method creates a device with all required nested structures:
  /// - connections (List<RawDeviceConnection>)
  /// - properties (List<RawDeviceProperty>)
  /// - unit (RawDeviceUnit)
  /// - model (RawDeviceModel)
  /// - knownInterfaces (List<RawDeviceKnownInterface>)
  static Map<String, dynamic> createDeviceData({
    required String deviceID,
    String? friendlyName,
    String nodeType = 'Slave',
    List<Map<String, dynamic>>? knownInterfaces,
    List<Map<String, dynamic>>? connections,
    bool isAuthority = false,
  }) =>
      {
        'deviceID': deviceID,
        'friendlyName': friendlyName ?? 'Node-$deviceID',
        'nodeType': nodeType,
        'isAuthority': isAuthority,
        'lastChangeRevision': 1,
        'maxAllowedProperties': 32,
        'connections': connections ?? [],
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
        'knownInterfaces': knownInterfaces ?? [],
      };

  /// Create a connection map for device data
  static Map<String, dynamic> createConnection({
    required String macAddress,
    String? ipAddress,
    String? parentDeviceID,
    bool isGuest = false,
  }) =>
      {
        'macAddress': macAddress,
        'ipAddress': ipAddress ?? '192.168.1.100',
        'ipv6Address': null,
        'parentDeviceID': parentDeviceID,
        'isGuest': isGuest,
      };

  /// Create a known interface for device data
  static Map<String, dynamic> createKnownInterface({
    required String macAddress,
    String interfaceType = 'Wireless',
    String? band,
  }) =>
      {
        'macAddress': macAddress,
        'interfaceType': interfaceType,
        'band': band,
      };

  /// Create backhaul info success response
  static JNAPSuccess createBackhaulInfoSuccess({
    List<Map<String, dynamic>>? backhaulDevices,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {'backhaulDevices': backhaulDevices ?? []},
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
  /// - wirelessConnectionInfo (optional)
  static Map<String, dynamic> createBackhaulDeviceData({
    required String deviceUUID,
    String connectionType = 'Wireless',
    String ipAddress = '192.168.1.100',
    String parentIPAddress = '192.168.1.1',
    String speedMbps = '866',
    String timestamp = '2024-01-01T00:00:00Z',
    Map<String, dynamic>? wirelessConnectionInfo,
  }) =>
      {
        'deviceUUID': deviceUUID,
        'ipAddress': ipAddress,
        'parentIPAddress': parentIPAddress,
        'connectionType': connectionType,
        'speedMbps': speedMbps,
        'timestamp': timestamp,
        if (wirelessConnectionInfo != null)
          'wirelessConnectionInfo': wirelessConnectionInfo,
      };

  /// Create wireless connection info for backhaul
  ///
  /// Must include all required fields for WirelessConnectionInfo.fromMap:
  /// - radioID, channel, apRSSI, stationRSSI, apBSSID, stationBSSID
  static Map<String, dynamic> createWirelessConnectionInfo({
    String radioID = 'RADIO_5GHz',
    int channel = 36,
    int apRSSI = -50,
    int stationRSSI = -50,
    String apBSSID = 'AA:BB:CC:DD:EE:FF',
    String stationBSSID = '11:22:33:44:55:66',
  }) =>
      {
        'radioID': radioID,
        'channel': channel,
        'apRSSI': apRSSI,
        'stationRSSI': stationRSSI,
        'apBSSID': apBSSID,
        'stationBSSID': stationBSSID,
      };

  /// Create a JNAP error for error handling tests
  static JNAPError createJNAPError({
    String result = 'ErrorUnknown',
    String? error,
  }) =>
      JNAPError(
        result: result,
        error: error,
      );

  /// Create unauthorized error
  static JNAPError createUnauthorizedError() => JNAPError(
        result: '_ErrorUnauthorized',
        error: 'Authentication required',
      );

  /// Create a complete device list scenario for testing pollForNodesOnline
  ///
  /// Creates devices with all required nested structures and proper connections
  /// for the isOnline() check to pass.
  static JNAPSuccess createOnlineNodesResponse({
    List<String> macAddresses = const [],
    bool allOnline = true,
  }) {
    final devices = macAddresses
        .map((mac) => createDeviceData(
              deviceID: 'device-$mac',
              nodeType: 'Slave',
              knownInterfaces: [createKnownInterface(macAddress: mac)],
              connections: allOnline
                  ? [
                      createConnection(
                        macAddress: mac,
                        parentDeviceID: 'master-device',
                      )
                    ]
                  : [],
            ))
        .toList();
    return createDevicesSuccess(devices: devices);
  }

  /// Create a complete backhaul info response for testing pollNodesBackhaulInfo
  static JNAPSuccess createBackhaulInfoForDevices({
    required List<String> deviceUUIDs,
    String connectionType = 'Wireless',
  }) {
    final backhaulDevices = deviceUUIDs
        .map((uuid) => createBackhaulDeviceData(
              deviceUUID: uuid,
              connectionType: connectionType,
              wirelessConnectionInfo: connectionType == 'Wireless'
                  ? createWirelessConnectionInfo()
                  : null,
            ))
        .toList();
    return createBackhaulInfoSuccess(backhaulDevices: backhaulDevices);
  }
}
