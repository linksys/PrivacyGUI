import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for InstantTopologyService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// Supports partial override pattern via named parameters.
class InstantTopologyTestData {
  /// Create successful reboot response for master node
  static JNAPSuccess createRebootSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create successful reboot transaction response for multiple nodes
  static JNAPTransactionSuccessWrap createMultiNodeRebootSuccess(
    List<String> deviceUUIDs,
  ) {
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: deviceUUIDs.reversed
          .map((uuid) => MapEntry(
                JNAPAction.reboot2,
                const JNAPSuccess(result: 'ok', output: {}),
              ))
          .toList(),
    );
  }

  /// Create successful factory reset response for master node
  static JNAPSuccess createFactoryResetSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create successful factory reset transaction response for multiple nodes
  static JNAPTransactionSuccessWrap createMultiNodeFactoryResetSuccess(
    List<String> deviceUUIDs,
  ) {
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: deviceUUIDs.reversed
          .map((uuid) => MapEntry(
                JNAPAction.factoryReset2,
                const JNAPSuccess(result: 'ok', output: {}),
              ))
          .toList(),
    );
  }

  /// Create successful start LED blink response
  static JNAPSuccess createStartBlinkSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create successful stop LED blink response
  static JNAPSuccess createStopBlinkSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create getDevices response with specified online/offline devices
  ///
  /// [onlineDeviceIds] - list of device IDs that should appear online
  /// [offlineDeviceIds] - list of device IDs that should appear offline
  static JNAPSuccess createGetDevicesResponse({
    List<String> onlineDeviceIds = const [],
    List<String> offlineDeviceIds = const [],
  }) {
    final devices = <Map<String, dynamic>>[];

    for (final deviceId in onlineDeviceIds) {
      devices.add(_createDeviceMap(deviceId: deviceId, isOnline: true));
    }

    for (final deviceId in offlineDeviceIds) {
      devices.add(_createDeviceMap(deviceId: deviceId, isOnline: false));
    }

    return JNAPSuccess(
      result: 'ok',
      output: {'devices': devices},
    );
  }

  /// Create getDevices response with all nodes offline
  static JNAPSuccess createAllNodesOfflineResponse(List<String> deviceIds) {
    return createGetDevicesResponse(offlineDeviceIds: deviceIds);
  }

  /// Create getDevices response with all nodes online (for timeout testing)
  static JNAPSuccess createAllNodesOnlineResponse(List<String> deviceIds) {
    return createGetDevicesResponse(onlineDeviceIds: deviceIds);
  }

  /// Create generic JNAP error
  static JNAPError createGenericError({
    String errorCode = 'ErrorUnknown',
    String? errorMessage,
  }) {
    return JNAPError(
      result: errorCode,
      error: errorMessage,
    );
  }

  /// Create reboot error for a specific device
  static JNAPError createRebootError({
    String errorCode = 'ErrorRebootFailed',
    String? deviceUUID,
  }) {
    return JNAPError(
      result: errorCode,
      error: deviceUUID != null ? '{"deviceUUID": "$deviceUUID"}' : null,
    );
  }

  /// Create LED blink error
  static JNAPError createBlinkError({
    String errorCode = 'ErrorBlinkFailed',
    String? deviceId,
  }) {
    return JNAPError(
      result: errorCode,
      error: deviceId != null ? '{"deviceID": "$deviceId"}' : null,
    );
  }

  /// Private helper to create a device map for getDevices response
  static Map<String, dynamic> _createDeviceMap({
    required String deviceId,
    required bool isOnline,
    String? location,
    String? nodeType,
  }) {
    return {
      'deviceID': deviceId,
      'friendlyName': location ?? 'Device $deviceId',
      'knownInterfaces': <Map<String, dynamic>>[],
      'connections': isOnline
          ? [
              {
                'ipAddress': '192.168.1.${deviceId.hashCode % 255}',
                'macAddress': 'AA:BB:CC:DD:EE:FF',
                'parentDeviceID': '',
                'isGuest': false,
              }
            ]
          : <Map<String, dynamic>>[],
      'properties': <Map<String, dynamic>>[],
      'unit': {
        'serialNumber': 'SN$deviceId',
        'firmwareVersion': '1.0.0',
        'firmwareDate': '2024-01-01T00:00:00Z',
        'operatingSystem': 'Linux',
      },
      'model': {
        'deviceType': 'Infrastructure',
        'manufacturer': 'Linksys',
        'modelNumber': 'MR7500',
        'hardwareVersion': '1',
        'modelDescription': 'Test Router',
      },
      'isAuthority': deviceId.contains('master'),
      'nodeType': nodeType,
      'lastChangeRevision': 1,
      'maxAllowedProperties': 10,
    };
  }
}
