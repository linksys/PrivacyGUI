import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

/// Test data builder for DashboardHomeService tests.
///
/// Provides factory methods to create DashboardManagerState and DeviceManagerState
/// with sensible defaults for testing the service transformation logic.
///
/// Per constitution Section 1.6.2
class DashboardHomeTestData {
  // ============================================
  // DashboardManagerState Builders
  // ============================================

  /// Create a DashboardManagerState with default values
  static DashboardManagerState createDashboardManagerState({
    NodeDeviceInfo? deviceInfo,
    List<RouterRadio>? mainRadios,
    List<GuestRadioInfo>? guestRadios,
    bool isGuestNetworkEnabled = false,
    int uptimes = 86400,
    String? wanConnection = 'Linked-1000Mbps',
    List<String> lanConnections = const ['Linked-1000Mbps', 'None', 'None'],
  }) {
    return DashboardManagerState(
      deviceInfo: deviceInfo ?? createNodeDeviceInfo(),
      mainRadios: mainRadios ?? createDefaultMainRadios(),
      guestRadios: guestRadios ?? const [],
      isGuestNetworkEnabled: isGuestNetworkEnabled,
      uptimes: uptimes,
      wanConnection: wanConnection,
      lanConnections: lanConnections,
    );
  }

  /// Create DashboardManagerState with guest network enabled
  static DashboardManagerState createDashboardManagerStateWithGuest({
    NodeDeviceInfo? deviceInfo,
    List<RouterRadio>? mainRadios,
    List<GuestRadioInfo>? guestRadios,
    int uptimes = 86400,
  }) {
    return createDashboardManagerState(
      deviceInfo: deviceInfo,
      mainRadios: mainRadios,
      guestRadios: guestRadios ?? createDefaultGuestRadios(),
      isGuestNetworkEnabled: true,
      uptimes: uptimes,
    );
  }

  /// Create empty DashboardManagerState (no radios)
  static DashboardManagerState createEmptyDashboardManagerState() {
    return const DashboardManagerState(
      mainRadios: [],
      guestRadios: [],
      isGuestNetworkEnabled: false,
      uptimes: 0,
      lanConnections: [],
    );
  }

  // ============================================
  // DeviceManagerState Builders
  // ============================================

  /// Create a DeviceManagerState with default values
  static DeviceManagerState createDeviceManagerState({
    List<LinksysDevice>? deviceList,
    RouterWANStatus? wanStatus,
    int lastUpdateTime = 1234567890,
  }) {
    return DeviceManagerState(
      deviceList: deviceList ?? createDefaultDeviceList(),
      wanStatus: wanStatus ?? createWanStatus(),
      lastUpdateTime: lastUpdateTime,
    );
  }

  /// Create DeviceManagerState for first polling (lastUpdateTime = 0)
  static DeviceManagerState createFirstPollingDeviceManagerState({
    List<LinksysDevice>? deviceList,
  }) {
    return createDeviceManagerState(
      deviceList: deviceList,
      lastUpdateTime: 0,
    );
  }

  /// Create DeviceManagerState with offline nodes
  static DeviceManagerState createDeviceManagerStateWithOfflineNodes() {
    return createDeviceManagerState(
      deviceList: [
        createMasterDevice(),
        createSlaveDevice(isOnline: false),
      ],
    );
  }

  /// Create empty DeviceManagerState
  static DeviceManagerState createEmptyDeviceManagerState() {
    return const DeviceManagerState(
      deviceList: [],
      lastUpdateTime: 0,
    );
  }

  // ============================================
  // RouterRadio Builders
  // ============================================

  /// Create a RouterRadio for testing
  static RouterRadio createRouterRadio({
    String radioID = 'RADIO_2.4GHz',
    String band = '2.4GHz',
    String ssid = 'TestNetwork',
    String passphrase = 'testpassword',
    bool isEnabled = true,
  }) {
    return RouterRadio.fromMap({
      'radioID': radioID,
      'physicalRadioID': 'wl0',
      'bssid': 'AA:BB:CC:DD:EE:01',
      'band': band,
      'supportedModes': const ['802.11b/g/n'],
      'supportedChannelsForChannelWidths': const [
        {
          'channelWidth': 'Auto',
          'channels': [1, 6, 11],
        }
      ],
      'supportedSecurityTypes': const [
        'None',
        'WPA2-Personal',
        'WPA3-Personal'
      ],
      'maxRADIUSSharedKeyLength': 64,
      'settings': {
        'isEnabled': isEnabled,
        'mode': '802.11b/g/n',
        'ssid': ssid,
        'broadcastSSID': true,
        'channelWidth': 'Auto',
        'channel': 6,
        'security': 'WPA2-Personal',
        'wpaPersonalSettings': {
          'passphrase': passphrase,
        },
      },
    });
  }

  /// Create default main radios (2.4GHz and 5GHz)
  static List<RouterRadio> createDefaultMainRadios() {
    return [
      createRouterRadio(
        radioID: 'RADIO_2.4GHz',
        band: '2.4GHz',
        ssid: 'TestNetwork',
        passphrase: 'password123',
      ),
      createRouterRadio(
        radioID: 'RADIO_5GHz',
        band: '5GHz',
        ssid: 'TestNetwork',
        passphrase: 'password123',
      ),
    ];
  }

  // ============================================
  // GuestRadioInfo Builders
  // ============================================

  /// Create a GuestRadioInfo for testing
  static GuestRadioInfo createGuestRadioInfo({
    String radioID = 'RADIO_2.4GHz',
    String guestSSID = 'Guest-Network',
    String? guestWPAPassphrase = 'guestpass',
    bool isEnabled = true,
  }) {
    return GuestRadioInfo.fromMap({
      'radioID': radioID,
      'isEnabled': isEnabled,
      'broadcastGuestSSID': true,
      'guestSSID': guestSSID,
      'guestWPAPassphrase': guestWPAPassphrase,
      'canEnableRadio': true,
    });
  }

  /// Create default guest radios
  static List<GuestRadioInfo> createDefaultGuestRadios() {
    return [
      createGuestRadioInfo(
        radioID: 'RADIO_2.4GHz',
        guestSSID: 'Guest-Network',
        guestWPAPassphrase: 'guestpass123',
      ),
      createGuestRadioInfo(
        radioID: 'RADIO_5GHz',
        guestSSID: 'Guest-Network',
        guestWPAPassphrase: 'guestpass123',
      ),
    ];
  }

  // ============================================
  // LinksysDevice Builders
  // ============================================

  /// Create a master device
  static LinksysDevice createMasterDevice({
    String deviceId = 'master-device-001',
    String friendlyName = 'Master Router',
    String modelNumber = 'MX5300',
    String hardwareVersion = '1',
    bool isOnline = true,
  }) {
    return LinksysDevice(
      deviceID: deviceId,
      friendlyName: friendlyName,
      isAuthority: true,
      nodeType: 'Master',
      lastChangeRevision: 1,
      maxAllowedProperties: 10,
      model: RawDeviceModel(
        deviceType: 'Infrastructure',
        manufacturer: 'Linksys',
        modelNumber: modelNumber,
        hardwareVersion: hardwareVersion,
      ),
      unit: const RawDeviceUnit(
        serialNumber: 'SN123456789',
        firmwareVersion: '1.0.0',
        firmwareDate: '2024-01-01',
        operatingSystem: 'Linux',
      ),
      connections: [
        RawDeviceConnection(
          macAddress: 'AA:BB:CC:DD:EE:01',
          ipAddress: isOnline ? '192.168.1.1' : null,
          parentDeviceID: null,
          isGuest: false,
        ),
      ],
      properties: const [],
    );
  }

  /// Create a slave device
  static LinksysDevice createSlaveDevice({
    String deviceId = 'slave-device-001',
    String friendlyName = 'Slave Node',
    bool isOnline = true,
  }) {
    return LinksysDevice(
      deviceID: deviceId,
      friendlyName: friendlyName,
      isAuthority: false,
      nodeType: 'Slave',
      lastChangeRevision: 1,
      maxAllowedProperties: 10,
      model: const RawDeviceModel(
        deviceType: 'Infrastructure',
        manufacturer: 'Linksys',
        modelNumber: 'MX5300',
        hardwareVersion: '1',
      ),
      unit: const RawDeviceUnit(
        serialNumber: 'SN987654321',
        firmwareVersion: '1.0.0',
        firmwareDate: '2024-01-01',
        operatingSystem: 'Linux',
      ),
      // isOnline() checks connections.isNotEmpty, so offline devices need empty connections
      connections: isOnline
          ? [
              RawDeviceConnection(
                macAddress: 'AA:BB:CC:DD:EE:02',
                ipAddress: '192.168.1.2',
                parentDeviceID: 'master-device-001',
                isGuest: false,
              ),
            ]
          : const [],
      properties: const [],
    );
  }

  /// Create an external (client) device connected to main WiFi
  static LinksysDevice createMainWifiDevice({
    String deviceId = 'external-device-001',
    String friendlyName = 'iPhone',
    String band = '5GHz',
    bool isOnline = true,
  }) {
    return LinksysDevice(
      deviceID: deviceId,
      friendlyName: friendlyName,
      isAuthority: false,
      nodeType: null,
      lastChangeRevision: 1,
      maxAllowedProperties: 10,
      connectedWifiType: WifiConnectionType.main,
      model: const RawDeviceModel(
        deviceType: 'Mobile',
        manufacturer: 'Apple',
        modelNumber: 'iPhone',
        hardwareVersion: '1.0',
      ),
      unit: const RawDeviceUnit(
        serialNumber: '',
        firmwareVersion: '',
        firmwareDate: '',
        operatingSystem: 'iOS',
      ),
      connections: [
        RawDeviceConnection(
          macAddress: 'AA:BB:CC:DD:EE:10',
          ipAddress: isOnline ? '192.168.1.100' : null,
          parentDeviceID: 'master-device-001',
          isGuest: false,
        ),
      ],
      knownInterfaces: [
        RawDeviceKnownInterface(
          macAddress: 'AA:BB:CC:DD:EE:10',
          interfaceType: 'Wireless',
          band: band,
        ),
      ],
      properties: const [],
    );
  }

  /// Create an external device connected to guest WiFi
  static LinksysDevice createGuestWifiDevice({
    String deviceId = 'guest-device-001',
    String friendlyName = 'Guest iPhone',
    bool isOnline = true,
  }) {
    return LinksysDevice(
      deviceID: deviceId,
      friendlyName: friendlyName,
      isAuthority: false,
      nodeType: null,
      lastChangeRevision: 1,
      maxAllowedProperties: 10,
      connectedWifiType: WifiConnectionType.guest,
      model: const RawDeviceModel(
        deviceType: 'Mobile',
        manufacturer: 'Apple',
        modelNumber: 'iPhone',
        hardwareVersion: '1.0',
      ),
      unit: const RawDeviceUnit(
        serialNumber: '',
        firmwareVersion: '',
        firmwareDate: '',
        operatingSystem: 'iOS',
      ),
      connections: [
        RawDeviceConnection(
          macAddress: 'AA:BB:CC:DD:EE:20',
          ipAddress: isOnline ? '192.168.2.100' : null,
          parentDeviceID: 'master-device-001',
          isGuest: true,
        ),
      ],
      properties: const [],
    );
  }

  /// Create default device list
  static List<LinksysDevice> createDefaultDeviceList() {
    return [
      createMasterDevice(),
      createMainWifiDevice(deviceId: 'device-001', band: '2.4GHz'),
      createMainWifiDevice(deviceId: 'device-002', band: '5GHz'),
    ];
  }

  // ============================================
  // Other Helpers
  // ============================================

  /// Create NodeDeviceInfo for testing
  static NodeDeviceInfo createNodeDeviceInfo({
    String modelNumber = 'MX5300',
    String hardwareVersion = '1',
    String serialNumber = 'SN123456789',
  }) {
    return NodeDeviceInfo.fromJson({
      'serialNumber': serialNumber,
      'modelNumber': modelNumber,
      'hardwareVersion': hardwareVersion,
      'manufacturer': 'Linksys',
      'description': 'Test Router',
      'firmwareVersion': '1.0.0',
      'firmwareDate': '2024-01-01T00:00:00Z',
      'services': const ['http://linksys.com/jnap/core/Core'],
    });
  }

  /// Create RouterWANStatus for testing
  static RouterWANStatus createWanStatus({
    String wanType = 'DHCP',
    String detectedWANType = 'DHCP',
    String wanStatus = 'Connected',
  }) {
    return RouterWANStatus.fromMap({
      'macAddress': 'AA:BB:CC:DD:EE:00',
      'detectedWANType': detectedWANType,
      'wanStatus': wanStatus,
      'wanIPv6Status': 'Disconnected',
      'supportedWANTypes': const ['DHCP', 'Static', 'PPPoE'],
      'supportedIPv6WANTypes': const <String>[],
      'supportedWANCombinations': const <Map<String, dynamic>>[],
      'wanConnection': {
        'wanType': wanType,
        'ipAddress': '192.168.1.100',
        'networkPrefixLength': 24,
        'gateway': '192.168.1.1',
        'mtu': 1500,
        'dnsServer1': '8.8.8.8',
        'dnsServer2': '8.8.4.4',
        'dnsServer3': null,
      },
    });
  }

  /// Create a callback function for getBandForDevice that returns predictable values
  static String Function(LinksysDevice) createGetBandForDeviceCallback({
    String defaultBand = '5GHz',
  }) {
    return (device) {
      // Return band from knownInterfaces if available
      final interface = device.knownInterfaces?.firstOrNull;
      if (interface?.band != null) {
        return interface!.band!;
      }
      return defaultBand;
    };
  }
}
