import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for AutoParentFirstLoginService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class AutoParentFirstLoginTestData {
  /// Create a successful internet connection status response
  static JNAPSuccess createInternetConnectionStatusSuccess({
    String connectionStatus = 'InternetConnected',
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {'connectionStatus': connectionStatus},
      );

  /// Create a successful firmware update settings GET response
  static JNAPSuccess createFirmwareUpdateSettingsSuccess({
    String updatePolicy = 'AutoUpdate',
    int startMinute = 0,
    int durationMinutes = 240,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'updatePolicy': updatePolicy,
          'autoUpdateWindow': {
            'startMinute': startMinute,
            'durationMinutes': durationMinutes,
          },
        },
      );

  /// Create a successful SET response (empty output)
  static JNAPSuccess createSetSuccess() => const JNAPSuccess(
        result: 'OK',
        output: {},
      );

  /// Create a JNAP error for testing error handling
  static JNAPError createJnapError({
    String result = 'ErrorUnknown',
    String? error,
  }) =>
      JNAPError(
        result: result,
        error: error,
      );
}
