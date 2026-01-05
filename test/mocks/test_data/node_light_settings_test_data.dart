import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for NodeLightSettingsService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class NodeLightSettingsTestData {
  /// Create a successful JNAP response for getLedNightModeSetting action
  /// with night mode enabled (8PM-8AM)
  static JNAPSuccess createNightModeSettings({
    bool enable = true,
    int startHour = 20,
    int endHour = 8,
    bool? allDayOff,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'Enable': enable,
          'StartingTime': startHour,
          'EndingTime': endHour,
          if (allDayOff != null) 'AllDayOff': allDayOff,
        },
      );

  /// Create a successful JNAP response for LED always on setting
  static JNAPSuccess createLedOnSettings() => const JNAPSuccess(
        result: 'ok',
        output: {
          'Enable': false,
        },
      );

  /// Create a successful JNAP response for LED always off setting
  static JNAPSuccess createLedOffSettings() => const JNAPSuccess(
        result: 'ok',
        output: {
          'Enable': true,
          'StartingTime': 0,
          'EndingTime': 24,
        },
      );

  /// Create a successful JNAP response for setLedNightModeSetting action
  static JNAPSuccess createSaveSuccess() => const JNAPSuccess(
        result: 'ok',
        output: {},
      );

  /// Create an unauthorized error response
  static JNAPError createUnauthorizedError() => const JNAPError(
        result: '_ErrorUnauthorized',
        error: null,
      );

  /// Create an unexpected error response with custom message
  static JNAPError createUnexpectedError([String? message]) => JNAPError(
        result: message ?? 'ErrorUnknown',
        error: null,
      );
}
