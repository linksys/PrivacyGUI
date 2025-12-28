import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for DeviceManagerService tests.
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// Supports partial override pattern via named parameters.
///
/// Usage:
/// ```dart
/// // Create complete polling data for service tests
/// final pollingData = DeviceManagerTestData.createCompletePollingData();
///
/// // Create with custom device list
/// final customPollingData = DeviceManagerTestData.createCompletePollingData(
///   devices: [DeviceManagerTestData.createMasterDevice()],
/// );
/// ```
class DeviceManagerTestData {
  // ============================================
  // Individual JNAP Action Responses
  // ============================================

  /// Create successful getDevices JNAP response
  static JNAPSuccess createGetDevicesSuccess({
    List<Map<String, dynamic>>? devices,
  }) {
    return JNAPSuccess(
      result: 'OK',
      output: {
        'devices': devices ?? _defaultDeviceList,
      },
    );
  }

  /// Create successful getNetworkConnections JNAP response
  static JNAPSuccess createGetNetworkConnectionsSuccess({
    List<Map<String, dynamic>>? connections,
  }) {
    return JNAPSuccess(
      result: 'OK',
      output: {
        'connections': connections ?? _defaultNetworkConnections,
      },
    );
  }

  /// Create successful getNodesWirelessNetworkConnections JNAP response
  static JNAPSuccess createGetNodesWirelessNetworkConnectionsSuccess({
    List<Map<String, dynamic>>? nodeWirelessConnections,
  }) {
    return JNAPSuccess(
      result: 'OK',
      output: {
        'nodeWirelessConnections':
            nodeWirelessConnections ?? _defaultNodeWirelessConnections,
      },
    );
  }

  /// Create successful getRadioInfo JNAP response
  static JNAPSuccess createGetRadioInfoSuccess({
    List<Map<String, dynamic>>? radios,
  }) {
    return JNAPSuccess(
      result: 'OK',
      output: {
        'radios': radios ?? _defaultRadios,
      },
    );
  }

  /// Create successful getGuestRadioSettings JNAP response
  static JNAPSuccess createGetGuestRadioSettingsSuccess({
    bool isGuestNetworkEnabled = true,
    bool isGuestNetworkACaptivePortal = false,
    List<Map<String, dynamic>>? radios,
  }) {
    return JNAPSuccess(
      result: 'OK',
      output: {
        'isGuestNetworkACaptivePortal': isGuestNetworkACaptivePortal,
        'isGuestNetworkEnabled': isGuestNetworkEnabled,
        'radios': radios ?? _defaultGuestRadios,
      },
    );
  }

  /// Create successful getWANStatus JNAP response
  static JNAPSuccess createGetWANStatusSuccess({
    String wanStatus = 'Connected',
    String wanIPv6Status = 'Disconnected',
    String detectedWANType = 'DHCP',
    String macAddress = 'AA:BB:CC:DD:EE:00',
    String? ipAddress,
  }) {
    return JNAPSuccess(
      result: 'OK',
      output: {
        'macAddress': macAddress,
        'detectedWANType': detectedWANType,
        'wanStatus': wanStatus,
        'wanIPv6Status': wanIPv6Status,
        'supportedWANTypes': const ['DHCP', 'Static', 'PPPoE'],
        'supportedIPv6WANTypes': const <String>[],
        'supportedWANCombinations': const <Map<String, dynamic>>[],
        'wanConnection': {
          'wanType': detectedWANType,
          'ipAddress': ipAddress ?? '192.168.1.100',
          'networkPrefixLength': 24,
          'gateway': '192.168.1.1',
          'mtu': 1500,
          'dnsServer1': '8.8.8.8',
          'dnsServer2': '8.8.4.4',
          'dnsServer3': null,
        },
      },
    );
  }

  /// Create successful getBackhaulInfo JNAP response
  static JNAPSuccess createGetBackhaulInfoSuccess({
    List<Map<String, dynamic>>? backhaulDevices,
  }) {
    return JNAPSuccess(
      result: 'OK',
      output: {
        'backhaulDevices': backhaulDevices ?? _defaultBackhaulDevices,
      },
    );
  }

  // ============================================
  // Complete Polling Data
  // ============================================

  /// Create complete CoreTransactionData for testing transformPollingData
  static CoreTransactionData createCompletePollingData({
    List<Map<String, dynamic>>? devices,
    List<Map<String, dynamic>>? connections,
    List<Map<String, dynamic>>? nodeWirelessConnections,
    List<Map<String, dynamic>>? radios,
    List<Map<String, dynamic>>? guestRadios,
    List<Map<String, dynamic>>? backhaulDevices,
    String? wanStatus,
    int lastUpdate = 1234567890,
    bool isReady = true,
  }) {
    return CoreTransactionData(
      lastUpdate: lastUpdate,
      isReady: isReady,
      data: {
        JNAPAction.getDevices: createGetDevicesSuccess(devices: devices),
        JNAPAction.getNetworkConnections:
            createGetNetworkConnectionsSuccess(connections: connections),
        JNAPAction.getNodesWirelessNetworkConnections:
            createGetNodesWirelessNetworkConnectionsSuccess(
          nodeWirelessConnections: nodeWirelessConnections,
        ),
        JNAPAction.getRadioInfo: createGetRadioInfoSuccess(radios: radios),
        JNAPAction.getGuestRadioSettings:
            createGetGuestRadioSettingsSuccess(radios: guestRadios),
        JNAPAction.getWANStatus:
            createGetWANStatusSuccess(wanStatus: wanStatus ?? 'Connected'),
        JNAPAction.getBackhaulInfo:
            createGetBackhaulInfoSuccess(backhaulDevices: backhaulDevices),
      },
    );
  }

  /// Create null polling data (simulates initial load)
  static CoreTransactionData? createNullPollingData() {
    return null;
  }

  /// Create partial error polling data (some actions failed)
  static CoreTransactionData createPartialErrorPollingData({
    JNAPAction errorAction = JNAPAction.getBackhaulInfo,
    String errorCode = 'ErrorUnknown',
    int lastUpdate = 1234567890,
  }) {
    final Map<JNAPAction, JNAPResult> data = {
      JNAPAction.getDevices: createGetDevicesSuccess(),
      JNAPAction.getNetworkConnections: createGetNetworkConnectionsSuccess(),
      JNAPAction.getRadioInfo: createGetRadioInfoSuccess(),
      JNAPAction.getWANStatus: createGetWANStatusSuccess(),
    };

    // Add the error action
    data[errorAction] = JNAPError(result: errorCode, error: 'Test error');

    return CoreTransactionData(
      lastUpdate: lastUpdate,
      isReady: true,
      data: data,
    );
  }

  /// Create empty polling data (no devices)
  static CoreTransactionData createEmptyPollingData({
    int lastUpdate = 1234567890,
  }) {
    return CoreTransactionData(
      lastUpdate: lastUpdate,
      isReady: true,
      data: {
        JNAPAction.getDevices: const JNAPSuccess(
          result: 'OK',
          output: {'devices': <Map<String, dynamic>>[]},
        ),
        JNAPAction.getNetworkConnections: const JNAPSuccess(
          result: 'OK',
          output: {'connections': <Map<String, dynamic>>[]},
        ),
        JNAPAction.getRadioInfo: const JNAPSuccess(
          result: 'OK',
          output: {'radios': <Map<String, dynamic>>[]},
        ),
        JNAPAction.getWANStatus: createGetWANStatusSuccess(),
        JNAPAction.getBackhaulInfo: const JNAPSuccess(
          result: 'OK',
          output: {'backhaulDevices': <Map<String, dynamic>>[]},
        ),
      },
    );
  }

  // ============================================
  // Device Factory Methods
  // ============================================

  /// Create a master node device
  static Map<String, dynamic> createMasterDevice({
    String deviceId = 'master-device-id-001',
    String friendlyName = 'Master Router',
    String ipAddress = '192.168.1.1',
    bool isOnline = true,
  }) {
    return {
      'deviceID': deviceId,
      'friendlyName': friendlyName,
      'isAuthority': true,
      'nodeType': 'Master',
      'model': {
        'deviceType': 'Infrastructure',
        'manufacturer': 'Linksys',
        'modelNumber': 'MX5300',
        'hardwareVersion': '1.0',
      },
      'unit': {
        'serialNumber': 'SN123456789',
        'firmwareVersion': '1.0.0',
        'firmwareDate': '2024-01-01',
        'operatingSystem': 'Linux',
      },
      'connections': [
        {
          'macAddress': 'AA:BB:CC:DD:EE:01',
          'ipAddress': ipAddress,
          'parentDeviceID': null,
          'isGuest': false,
        }
      ],
      'properties': [
        {'name': 'userDeviceName', 'value': friendlyName},
      ],
      'maxAllowedProperties': 10,
      'lastChangeRevision': 1,
      'knownInterfaces': [
        {
          'macAddress': 'AA:BB:CC:DD:EE:01',
          'interfaceType': 'Wired',
        }
      ],
    };
  }

  /// Create a slave node device
  static Map<String, dynamic> createSlaveDevice({
    String deviceId = 'slave-device-id-001',
    String friendlyName = 'Slave Node',
    String ipAddress = '192.168.1.2',
    String parentDeviceId = 'master-device-id-001',
    bool isOnline = true,
  }) {
    return {
      'deviceID': deviceId,
      'friendlyName': friendlyName,
      'isAuthority': false,
      'nodeType': 'Slave',
      'model': {
        'deviceType': 'Infrastructure',
        'manufacturer': 'Linksys',
        'modelNumber': 'MX5300',
        'hardwareVersion': '1.0',
      },
      'unit': {
        'serialNumber': 'SN987654321',
        'firmwareVersion': '1.0.0',
        'firmwareDate': '2024-01-01',
        'operatingSystem': 'Linux',
      },
      'connections': [
        {
          'macAddress': 'AA:BB:CC:DD:EE:02',
          'ipAddress': ipAddress,
          'parentDeviceID': parentDeviceId,
          'isGuest': false,
        }
      ],
      'properties': [
        {'name': 'userDeviceName', 'value': friendlyName},
      ],
      'maxAllowedProperties': 10,
      'lastChangeRevision': 1,
      'knownInterfaces': [
        {
          'macAddress': 'AA:BB:CC:DD:EE:02',
          'interfaceType': 'Wireless',
          'band': '5GHz',
        }
      ],
    };
  }

  /// Create an external (client) device
  static Map<String, dynamic> createExternalDevice({
    String deviceId = 'external-device-id-001',
    String friendlyName = 'iPhone',
    String macAddress = 'AA:BB:CC:DD:EE:10',
    String ipAddress = '192.168.1.100',
    String parentDeviceId = 'master-device-id-001',
    bool isGuest = false,
  }) {
    return {
      'deviceID': deviceId,
      'friendlyName': friendlyName,
      'isAuthority': false,
      'nodeType': null,
      'model': {
        'deviceType': 'Mobile',
        'manufacturer': 'Apple',
        'modelNumber': 'iPhone',
        'hardwareVersion': '1.0',
      },
      'unit': {
        'serialNumber': '',
        'firmwareVersion': '',
        'firmwareDate': '',
        'operatingSystem': 'iOS',
      },
      'connections': [
        {
          'macAddress': macAddress,
          'ipAddress': ipAddress,
          'parentDeviceID': parentDeviceId,
          'isGuest': isGuest,
        }
      ],
      'properties': [
        {'name': 'userDeviceName', 'value': friendlyName},
      ],
      'maxAllowedProperties': 10,
      'lastChangeRevision': 1,
      'knownInterfaces': [
        {
          'macAddress': macAddress,
          'interfaceType': 'Wireless',
          'band': '5GHz',
        }
      ],
    };
  }

  // ============================================
  // Error Responses
  // ============================================

  /// Create JNAP error response
  static JNAPError createJnapError({
    String result = 'ErrorUnknown',
    String? error,
  }) {
    return JNAPError(
      result: result,
      error: error ?? 'Operation failed',
    );
  }

  // ============================================
  // Default Test Data
  // ============================================

  static List<Map<String, dynamic>> get _defaultDeviceList => [
        createMasterDevice(),
        createSlaveDevice(),
        createExternalDevice(),
        createExternalDevice(
          deviceId: 'external-device-id-002',
          friendlyName: 'MacBook',
          macAddress: 'AA:BB:CC:DD:EE:11',
          ipAddress: '192.168.1.101',
        ),
      ];

  static List<Map<String, dynamic>> get _defaultNetworkConnections => [
        {
          'macAddress': 'AA:BB:CC:DD:EE:10',
          'negotiatedMbps': 1000,
          'timestamp': '2024-01-01T00:00:00Z',
          'wireless': {
            'bssid': 'AA:BB:CC:DD:EE:01',
            'isGuest': false,
            'radioID': 'RADIO_5GHz',
            'band': '5GHz',
            'signalDecibels': -45,
          },
        },
        {
          'macAddress': 'AA:BB:CC:DD:EE:11',
          'negotiatedMbps': 1000,
          'timestamp': '2024-01-01T00:00:00Z',
          'wireless': {
            'bssid': 'AA:BB:CC:DD:EE:01',
            'isGuest': false,
            'radioID': 'RADIO_5GHz',
            'band': '5GHz',
            'signalDecibels': -50,
          },
        },
      ];

  static List<Map<String, dynamic>> get _defaultNodeWirelessConnections => [
        {
          'deviceID': 'master-device-id-001',
          'connections': _defaultNetworkConnections,
        }
      ];

  static List<Map<String, dynamic>> get _defaultRadios => [
        {
          'radioID': 'RADIO_2.4GHz',
          'physicalRadioID': 'wl0',
          'bssid': 'AA:BB:CC:DD:EE:01',
          'band': '2.4GHz',
          'supportedModes': const ['802.11b/g/n'],
          'supportedChannelsForChannelWidths': const [
            {
              'channelWidth': 'Auto',
              'channels': [1, 6, 11],
            }
          ],
          'supportedSecurityTypes': const ['None', 'WPA2-Personal', 'WPA3-Personal'],
          'maxRADIUSSharedKeyLength': 64,
          'settings': {
            'isEnabled': true,
            'mode': '802.11b/g/n',
            'ssid': 'MyNetwork_2.4G',
            'broadcastSSID': true,
            'channelWidth': 'Auto',
            'channel': 6,
            'security': 'WPA2-Personal',
          },
        },
        {
          'radioID': 'RADIO_5GHz',
          'physicalRadioID': 'wl1',
          'bssid': 'AA:BB:CC:DD:EE:02',
          'band': '5GHz',
          'supportedModes': const ['802.11a/n/ac'],
          'supportedChannelsForChannelWidths': const [
            {
              'channelWidth': 'Auto',
              'channels': [36, 40, 44, 48],
            }
          ],
          'supportedSecurityTypes': const ['None', 'WPA2-Personal', 'WPA3-Personal'],
          'maxRADIUSSharedKeyLength': 64,
          'settings': {
            'isEnabled': true,
            'mode': '802.11a/n/ac',
            'ssid': 'MyNetwork_5G',
            'broadcastSSID': true,
            'channelWidth': 'Auto',
            'channel': 36,
            'security': 'WPA2-Personal',
          },
        },
      ];

  static List<Map<String, dynamic>> get _defaultGuestRadios => [
        {
          'radioID': 'RADIO_2.4GHz',
          'isEnabled': true,
          'broadcastGuestSSID': true,
          'guestSSID': 'MyNetwork_Guest',
          'guestPassword': 'guestpass123',
        },
        {
          'radioID': 'RADIO_5GHz',
          'isEnabled': true,
          'broadcastGuestSSID': true,
          'guestSSID': 'MyNetwork_Guest',
          'guestPassword': 'guestpass123',
        },
      ];

  static List<Map<String, dynamic>> get _defaultBackhaulDevices => [
        {
          'deviceUUID': 'slave-device-id-001',
          'ipAddress': '192.168.1.2',
          'parentIPAddress': '192.168.1.1',
          'connectionType': 'Wireless',
          'speedMbps': '866',
          'timestamp': '2024-01-01T00:00:00Z',
          'wirelessConnectionInfo': {
            'radioID': '5GHz',
            'channel': 36,
            'apBSSID': 'AA:BB:CC:DD:EE:01',
            'stationBSSID': 'AA:BB:CC:DD:EE:02',
            'stationRSSI': -55,
          },
        },
      ];
}
