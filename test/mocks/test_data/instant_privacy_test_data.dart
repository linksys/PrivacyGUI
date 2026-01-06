import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for InstantPrivacyService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class InstantPrivacyTestData {
  /// Create a successful MAC filter settings response
  ///
  /// Supports partial override design: only specify fields that need to change.
  static JNAPSuccess createMacFilterSettingsSuccess({
    String macFilterMode = 'Disabled',
    int maxMacAddresses = 32,
    List<String> macAddresses = const [],
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'macFilterMode': macFilterMode,
          'maxMACAddresses': maxMacAddresses,
          'macAddresses': macAddresses,
        },
      );

  /// Create a successful STA BSSIDs response
  static JNAPSuccess createStaBssidsSuccess({
    List<String> staBssids = const [],
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'staBSSIDS': staBssids,
        },
      );

  /// Create a successful local device response
  static JNAPSuccess createLocalDeviceSuccess({
    String deviceId = 'test-device-id',
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'deviceID': deviceId,
        },
      );

  /// Create a LinksysDevice for testing
  ///
  /// Provides minimal required fields with sensible defaults.
  /// Note: getMacAddress() uses knownInterfaces or knownMACAddresses, not connections.
  static LinksysDevice createLinksysDevice({
    String deviceId = 'test-device-id',
    String macAddress = 'AA:BB:CC:DD:EE:FF',
    String? ipAddress = '192.168.1.100',
    String? friendlyName,
  }) =>
      LinksysDevice(
        deviceID: deviceId,
        friendlyName: friendlyName,
        isAuthority: false,
        lastChangeRevision: 1,
        maxAllowedProperties: 10,
        model: const RawDeviceModel(
          deviceType: 'Mobile',
          manufacturer: 'Test',
          modelNumber: 'TestDevice',
          hardwareVersion: '1.0',
        ),
        unit: const RawDeviceUnit(
          serialNumber: '',
          firmwareVersion: '',
          firmwareDate: '',
          operatingSystem: '',
        ),
        connections: [
          RawDeviceConnection(
            macAddress: macAddress,
            ipAddress: ipAddress,
            parentDeviceID: 'router',
            isGuest: false,
          ),
        ],
        properties: const [],
        // getMacAddress() looks for knownInterfaces first, then knownMACAddresses
        knownMACAddresses: [macAddress],
      );
}
