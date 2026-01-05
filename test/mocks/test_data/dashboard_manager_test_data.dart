import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for DashboardManagerService tests.
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
///
/// Per constitution Section 1.6.2
class DashboardManagerTestData {
  // === Individual JNAP Response Builders ===

  /// Create default getDeviceInfo success response
  static JNAPSuccess createDeviceInfoSuccess({
    String serialNumber = 'TEST123456',
    String modelNumber = 'MX5300',
    String firmwareVersion = '1.0.0',
    String hardwareVersion = '1',
    String manufacturer = 'Linksys',
    String description = 'Test Router',
    String firmwareDate = '2025-01-01T00:00:00Z',
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'serialNumber': serialNumber,
          'modelNumber': modelNumber,
          'firmwareVersion': firmwareVersion,
          'hardwareVersion': hardwareVersion,
          'manufacturer': manufacturer,
          'description': description,
          'firmwareDate': firmwareDate,
          'services': const ['http://linksys.com/jnap/core/Core'],
        },
      );

  /// Create default getRadioInfo success response
  static JNAPSuccess createRadioInfoSuccess({
    List<Map<String, dynamic>>? radios,
    bool isBandSteeringSupported = true,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'isBandSteeringSupported': isBandSteeringSupported,
          'radios': radios ?? _defaultRadios,
        },
      );

  /// Default radios configuration matching the full RouterRadio structure
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
          'supportedSecurityTypes': const [
            'None',
            'WPA2-Personal',
            'WPA3-Personal'
          ],
          'maxRADIUSSharedKeyLength': 64,
          'settings': {
            'isEnabled': true,
            'mode': '802.11b/g/n',
            'ssid': 'TestNetwork',
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
          'supportedSecurityTypes': const [
            'None',
            'WPA2-Personal',
            'WPA3-Personal'
          ],
          'maxRADIUSSharedKeyLength': 64,
          'settings': {
            'isEnabled': true,
            'mode': '802.11a/n/ac',
            'ssid': 'TestNetwork',
            'broadcastSSID': true,
            'channelWidth': 'Auto',
            'channel': 36,
            'security': 'WPA2-Personal',
          },
        },
      ];

  /// Create default getGuestRadioSettings success response
  static JNAPSuccess createGuestRadioSettingsSuccess({
    bool isGuestNetworkEnabled = false,
    bool isGuestNetworkACaptivePortal = false,
    List<Map<String, dynamic>>? radios,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'isGuestNetworkACaptivePortal': isGuestNetworkACaptivePortal,
          'isGuestNetworkEnabled': isGuestNetworkEnabled,
          'radios': radios ??
              [
                {
                  'radioID': 'RADIO_2.4GHz',
                  'isEnabled': false,
                  'broadcastGuestSSID': true,
                  'guestSSID': 'Guest-2.4GHz',
                  'guestPassword': '',
                  'canEnableRadio': true,
                },
                {
                  'radioID': 'RADIO_5GHz',
                  'isEnabled': false,
                  'broadcastGuestSSID': true,
                  'guestSSID': 'Guest-5GHz',
                  'guestPassword': '',
                  'canEnableRadio': true,
                },
              ],
        },
      );

  /// Create default getSystemStats success response
  static JNAPSuccess createSystemStatsSuccess({
    int uptimeSeconds = 86400,
    String? cpuLoad,
    String? memoryLoad,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'uptimeSeconds': uptimeSeconds,
          if (cpuLoad != null) 'CPULoad': cpuLoad,
          if (memoryLoad != null) 'MemoryLoad': memoryLoad,
        },
      );

  /// Create default getEthernetPortConnections success response
  static JNAPSuccess createEthernetPortConnectionsSuccess({
    List<String> lanPortConnections = const ['Linked-1000Mbps', 'None', 'None'],
    String wanPortConnection = 'Linked-1000Mbps',
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'lanPortConnections': lanPortConnections,
          'wanPortConnection': wanPortConnection,
        },
      );

  /// Create default getLocalTime success response
  static JNAPSuccess createLocalTimeSuccess({
    String? currentTime,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'currentTime': currentTime ?? '2025-01-01T12:00:00Z',
        },
      );

  /// Create default getSoftSKUSettings success response
  static JNAPSuccess createSoftSKUSettingsSuccess({
    String modelNumber = 'MX5300-SKU',
    bool isSoftSKUEnabled = true,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'modelNumber': modelNumber,
          'isSoftSKUEnabled': isSoftSKUEnabled,
        },
      );

  // === Combined Polling Data Builders ===

  /// Create a complete successful polling data with all JNAP responses.
  ///
  /// Supports partial override design: only specify fields that need to change,
  /// other fields use default values.
  static CoreTransactionData createSuccessfulPollingData({
    JNAPSuccess? deviceInfo,
    JNAPSuccess? radioInfo,
    JNAPSuccess? guestRadioSettings,
    JNAPSuccess? systemStats,
    JNAPSuccess? ethernetPortConnections,
    JNAPSuccess? localTime,
    JNAPSuccess? softSKUSettings,
    int? lastUpdate,
    bool isReady = true,
  }) {
    final data = <JNAPAction, JNAPResult>{
      JNAPAction.getDeviceInfo: deviceInfo ?? createDeviceInfoSuccess(),
      JNAPAction.getRadioInfo: radioInfo ?? createRadioInfoSuccess(),
      JNAPAction.getGuestRadioSettings:
          guestRadioSettings ?? createGuestRadioSettingsSuccess(),
      JNAPAction.getSystemStats: systemStats ?? createSystemStatsSuccess(),
      JNAPAction.getEthernetPortConnections:
          ethernetPortConnections ?? createEthernetPortConnectionsSuccess(),
      JNAPAction.getLocalTime: localTime ?? createLocalTimeSuccess(),
      JNAPAction.getSoftSKUSettings:
          softSKUSettings ?? createSoftSKUSettingsSuccess(),
    };

    return CoreTransactionData(
      data: data,
      lastUpdate: lastUpdate ?? DateTime.now().millisecondsSinceEpoch,
      isReady: isReady,
    );
  }

  /// Create polling data with some actions failed.
  ///
  /// [failedActions] - Set of JNAP actions that should return errors
  static CoreTransactionData createPartialErrorPollingData({
    Set<JNAPAction> failedActions = const {},
    String errorMessage = 'Operation failed',
    bool isReady = true,
  }) {
    final data = <JNAPAction, JNAPResult>{};

    // Add successful or failed results based on failedActions set
    void addResult(JNAPAction action, JNAPSuccess successResult) {
      if (failedActions.contains(action)) {
        data[action] = JNAPError(result: 'ErrorUnknown', error: errorMessage);
      } else {
        data[action] = successResult;
      }
    }

    addResult(JNAPAction.getDeviceInfo, createDeviceInfoSuccess());
    addResult(JNAPAction.getRadioInfo, createRadioInfoSuccess());
    addResult(
        JNAPAction.getGuestRadioSettings, createGuestRadioSettingsSuccess());
    addResult(JNAPAction.getSystemStats, createSystemStatsSuccess());
    addResult(JNAPAction.getEthernetPortConnections,
        createEthernetPortConnectionsSuccess());
    addResult(JNAPAction.getLocalTime, createLocalTimeSuccess());
    addResult(JNAPAction.getSoftSKUSettings, createSoftSKUSettingsSuccess());

    return CoreTransactionData(
      data: data,
      lastUpdate: DateTime.now().millisecondsSinceEpoch,
      isReady: isReady,
    );
  }

  /// Create polling data with invalid time format for testing fallback behavior
  static CoreTransactionData createPollingDataWithInvalidTime() {
    return createSuccessfulPollingData(
      localTime: JNAPSuccess(
        result: 'OK',
        output: const {
          'currentTime': 'invalid-time-format',
        },
      ),
    );
  }
}
