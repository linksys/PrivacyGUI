import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for PollingService tests.
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
///
/// Per constitution Section 1.6.2
class PollingTestData {
  // === Device Mode ===

  /// Create getDeviceMode success response
  static JNAPSuccess createDeviceModeSuccess({
    String mode = 'Master',
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'mode': mode,
        },
      );

  // === Core Transaction Responses ===

  /// Create getDeviceInfo success response
  static JNAPSuccess createDeviceInfoSuccess({
    String serialNumber = 'TEST123456',
    String modelNumber = 'MX5300',
    String firmwareVersion = '1.0.0',
    List<String>? services,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'serialNumber': serialNumber,
          'modelNumber': modelNumber,
          'firmwareVersion': firmwareVersion,
          'hardwareVersion': '1',
          'manufacturer': 'Linksys',
          'description': 'Test Router',
          'firmwareDate': '2025-01-01T00:00:00Z',
          'services': services ?? ['http://linksys.com/jnap/core/Core'],
        },
      );

  /// Create getRadioInfo success response
  static JNAPSuccess createRadioInfoSuccess() => JNAPSuccess(
        result: 'OK',
        output: const {
          'isBandSteeringSupported': true,
          'radios': [
            {
              'radioID': 'RADIO_2.4GHz',
              'band': '2.4GHz',
              'settings': {'isEnabled': true, 'ssid': 'TestNetwork'},
            },
          ],
        },
      );

  /// Create getNetworkConnections success response
  static JNAPSuccess createNetworkConnectionsSuccess({
    int connectionCount = 3,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'connections': List.generate(
            connectionCount,
            (i) => {
              'macAddress': 'AA:BB:CC:DD:EE:0$i',
              'ipAddress': '192.168.1.${100 + i}',
            },
          ),
        },
      );

  /// Create getWANStatus success response
  static JNAPSuccess createWANStatusSuccess({
    String wanStatus = 'Connected',
    String wanConnection = 'DHCP',
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'wanStatus': wanStatus,
          'wanConnection': wanConnection,
          'wanIPAddress': '203.0.113.1',
        },
      );

  /// Create getSystemStats success response
  static JNAPSuccess createSystemStatsSuccess({
    int uptimeSeconds = 86400,
    int cpuLoad = 25,
    int memoryLoad = 50,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'uptimeSeconds': uptimeSeconds,
          'CPULoad': cpuLoad,
          'MemoryLoad': memoryLoad,
        },
      );

  /// Create getLocalTime success response
  static JNAPSuccess createLocalTimeSuccess({
    String? currentTime,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'currentTime': currentTime ?? '2025-01-01T12:00:00Z',
        },
      );

  /// Create getEthernetPortConnections success response
  static JNAPSuccess createEthernetPortConnectionsSuccess({
    List<String>? lanPortConnections,
    String wanPortConnection = 'Up',
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'lanPortConnections':
              lanPortConnections ?? ['Up', 'Down', 'Down', 'Down'],
          'wanPortConnection': wanPortConnection,
        },
      );

  /// Create getFirmwareUpdateSettings success response
  static JNAPSuccess createFirmwareUpdateSettingsSuccess({
    bool autoUpdateEnabled = true,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'autoUpdateEnabled': autoUpdateEnabled,
        },
      );

  /// Create getFirmwareUpdateStatus success response
  static JNAPSuccess createFirmwareUpdateStatusSuccess({
    String updateStatus = 'NoUpdateAvailable',
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'updateStatus': updateStatus,
        },
      );

  /// Create getDevices success response
  static JNAPSuccess createDevicesSuccess({
    int deviceCount = 5,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'devices': List.generate(
            deviceCount,
            (i) => {
              'deviceID': 'device-$i',
              'model': {'deviceType': 'Infrastructure'},
              'connections': [],
            },
          ),
        },
      );

  /// Create getMACFilterSettings success response
  static JNAPSuccess createMACFilterSettingsSuccess({
    bool isEnabled = false,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'isEnabled': isEnabled,
          'macAddresses': const <String>[],
        },
      );

  // === Transaction Builders ===

  /// Create a complete successful core transaction response
  ///
  /// This simulates the response from a full polling transaction
  static JNAPTransactionSuccessWrap createSuccessfulCoreTransaction({
    String? serialNumber,
    String? deviceMode,
  }) {
    return JNAPTransactionSuccessWrap(
      result: 'OK',
      data: [
        MapEntry(
          JNAPAction.getDeviceInfo,
          createDeviceInfoSuccess(serialNumber: serialNumber ?? 'TEST123456'),
        ),
        MapEntry(
          JNAPAction.getRadioInfo,
          createRadioInfoSuccess(),
        ),
        MapEntry(
          JNAPAction.getNetworkConnections,
          createNetworkConnectionsSuccess(),
        ),
        MapEntry(
          JNAPAction.getWANStatus,
          createWANStatusSuccess(),
        ),
        MapEntry(
          JNAPAction.getSystemStats,
          createSystemStatsSuccess(),
        ),
        MapEntry(
          JNAPAction.getLocalTime,
          createLocalTimeSuccess(),
        ),
        MapEntry(
          JNAPAction.getEthernetPortConnections,
          createEthernetPortConnectionsSuccess(),
        ),
        MapEntry(
          JNAPAction.getFirmwareUpdateSettings,
          createFirmwareUpdateSettingsSuccess(),
        ),
        MapEntry(
          JNAPAction.getFirmwareUpdateStatus,
          createFirmwareUpdateStatusSuccess(),
        ),
        MapEntry(
          JNAPAction.getDevices,
          createDevicesSuccess(),
        ),
        MapEntry(
          JNAPAction.getMACFilterSettings,
          createMACFilterSettingsSuccess(),
        ),
        const MapEntry(
          JNAPAction.getNodesWirelessNetworkConnections,
          JNAPSuccess(result: 'OK', output: {'connections': []}),
        ),
        const MapEntry(
          JNAPAction.getPowerTableSettings,
          JNAPSuccess(result: 'OK', output: {}),
        ),
      ],
    );
  }

  /// Create a transaction response with partial failures
  static JNAPTransactionSuccessWrap createPartialErrorTransaction({
    required JNAPAction errorAction,
    String errorResult = 'ErrorUnknown',
  }) {
    final successTransaction = createSuccessfulCoreTransaction();
    final modifiedData = successTransaction.data.map((entry) {
      if (entry.key == errorAction) {
        return MapEntry(
          entry.key,
          JNAPError(result: errorResult, error: 'Test error'),
        );
      }
      return entry;
    }).toList();

    return JNAPTransactionSuccessWrap(
      result: 'OK',
      data: modifiedData,
    );
  }

  // === Default Core Transaction Commands ===

  /// Get the default core transaction commands for testing
  static List<MapEntry<JNAPAction, Map<String, dynamic>>>
      getDefaultCoreTransactionCommands({
    String mode = 'Master',
    bool supportGuestNetwork = false,
    bool supportHealthCheck = false,
    bool supportNodeFirmwareUpdate = false,
    bool supportLedMode = false,
    bool supportSetup = false,
    bool supportProduct = false,
  }) {
    final commands = <MapEntry<JNAPAction, Map<String, dynamic>>>[
      const MapEntry(JNAPAction.getNodesWirelessNetworkConnections, {}),
      const MapEntry(JNAPAction.getNetworkConnections, {}),
      const MapEntry(JNAPAction.getRadioInfo, {}),
      if (supportGuestNetwork)
        const MapEntry(JNAPAction.getGuestRadioSettings, {}),
      const MapEntry(JNAPAction.getDevices, {}),
      const MapEntry(JNAPAction.getFirmwareUpdateSettings, {}),
      if (mode == 'Master') const MapEntry(JNAPAction.getBackhaulInfo, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
      const MapEntry(JNAPAction.getEthernetPortConnections, {}),
      const MapEntry(JNAPAction.getSystemStats, {}),
      const MapEntry(JNAPAction.getPowerTableSettings, {}),
      const MapEntry(JNAPAction.getLocalTime, {}),
      const MapEntry(JNAPAction.getDeviceInfo, {}),
    ];

    if (supportSetup) {
      commands.add(const MapEntry(JNAPAction.getInternetConnectionStatus, {}));
    }

    if (supportHealthCheck) {
      commands.add(const MapEntry(JNAPAction.getHealthCheckResults, {
        'includeModuleResults': true,
        'lastNumberOfResults': 5,
      }));
      commands
          .add(const MapEntry(JNAPAction.getSupportedHealthCheckModules, {}));
    }

    if (supportNodeFirmwareUpdate) {
      commands.add(const MapEntry(JNAPAction.getNodesFirmwareUpdateStatus, {}));
    } else {
      commands.add(const MapEntry(JNAPAction.getFirmwareUpdateStatus, {}));
    }

    if (supportProduct) {
      commands.add(const MapEntry(JNAPAction.getSoftSKUSettings, {}));
    }

    if (supportLedMode) {
      commands.add(const MapEntry(JNAPAction.getLedNightModeSetting, {}));
    }

    commands.add(const MapEntry(JNAPAction.getMACFilterSettings, {}));

    return commands;
  }
}
