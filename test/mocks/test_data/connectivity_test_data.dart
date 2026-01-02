import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for ConnectivityService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// Supports partial override pattern via named parameters.
class ConnectivityTestData {
  /// Create successful getDeviceInfo response with serial number
  static JNAPSuccess createGetDeviceInfoSuccess({
    String serialNumber = 'ABC123456789',
    String modelNumber = 'MR7500',
    String hardwareVersion = '1',
    String firmwareVersion = '1.0.0',
    String firmwareDate = '2024-01-01T00:00:00Z',
    String description = 'Linksys Router',
    String manufacturer = 'Linksys',
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'serialNumber': serialNumber,
        'modelNumber': modelNumber,
        'hardwareVersion': hardwareVersion,
        'firmwareVersion': firmwareVersion,
        'firmwareDate': firmwareDate,
        'description': description,
        'manufacturer': manufacturer,
        'services': const <String>[],
      },
    );
  }

  /// Create getDeviceInfo response with empty serial number
  static JNAPSuccess createGetDeviceInfoEmptySerial() {
    return const JNAPSuccess(
      result: 'ok',
      output: {
        'serialNumber': '',
        'modelNumber': 'MR7500',
        'hardwareVersion': '1',
        'firmwareVersion': '1.0.0',
        'firmwareDate': '2024-01-01T00:00:00Z',
        'description': 'Linksys Router',
        'manufacturer': 'Linksys',
        'services': <String>[],
      },
    );
  }

  /// Create JNAP error for getDeviceInfo failure
  static JNAPError createGetDeviceInfoError({
    String errorCode = '_ErrorUnauthorized',
  }) {
    return JNAPError(
      result: errorCode,
      error: null,
    );
  }

  /// Create successful fetchIsConfigured response for router configuration check
  static List<MapEntry<JNAPAction, JNAPResult>> createFetchConfiguredSuccess({
    bool isAdminPasswordDefault = false,
    bool isAdminPasswordSetByUser = true,
  }) {
    return [
      MapEntry(
        JNAPAction.isAdminPasswordDefault,
        JNAPSuccess(
          result: 'ok',
          output: {
            'isAdminPasswordDefault': isAdminPasswordDefault,
            'isAdminPasswordSetByUser': isAdminPasswordSetByUser,
          },
        ),
      ),
    ];
  }

  /// Create fetchIsConfigured response with default password state
  static List<MapEntry<JNAPAction, JNAPResult>>
      createFetchConfiguredDefaultPassword() {
    return createFetchConfiguredSuccess(
      isAdminPasswordDefault: true,
      isAdminPasswordSetByUser: false,
    );
  }

  /// Create fetchIsConfigured response with user-set password state
  static List<MapEntry<JNAPAction, JNAPResult>>
      createFetchConfiguredUserSetPassword() {
    return createFetchConfiguredSuccess(
      isAdminPasswordDefault: false,
      isAdminPasswordSetByUser: true,
    );
  }

  /// Create JNAP error for fetchIsConfigured failure
  static JNAPError createFetchConfiguredError({
    String errorCode = '_ErrorUnauthorized',
  }) {
    return JNAPError(
      result: errorCode,
      error: null,
    );
  }
}
