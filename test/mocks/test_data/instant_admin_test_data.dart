import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for InstantAdmin Service tests (Timezone and PowerTable)
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// Supports partial override pattern via named parameters.
class InstantAdminTestData {
  // ============================================
  // Timezone Test Data
  // ============================================

  /// Create successful getTimeSettings JNAP response
  static JNAPSuccess createGetTimeSettingsSuccess({
    String timeZoneID = 'PST8',
    bool autoAdjustForDST = false,
    List<Map<String, dynamic>>? supportedTimeZones,
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'timeZoneID': timeZoneID,
        'autoAdjustForDST': autoAdjustForDST,
        'supportedTimeZones': supportedTimeZones ?? _defaultSupportedTimezones,
      },
    );
  }

  /// Create error response for getTimeSettings
  static JNAPError createGetTimeSettingsError({
    String errorCode = 'ErrorUnknown',
    String? errorMessage,
  }) {
    return JNAPError(
      result: errorCode,
      error: errorMessage,
    );
  }

  /// Create successful setTimeSettings JNAP response
  static JNAPSuccess createSetTimeSettingsSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Default supported timezones list for testing
  static List<Map<String, dynamic>> get _defaultSupportedTimezones => [
        {
          'observesDST': true,
          'timeZoneID': 'PST8',
          'description': 'Pacific Time',
          'utcOffsetMinutes': -480,
        },
        {
          'observesDST': true,
          'timeZoneID': 'EST5',
          'description': 'Eastern Time',
          'utcOffsetMinutes': -300,
        },
        {
          'observesDST': false,
          'timeZoneID': 'UTC0',
          'description': 'UTC',
          'utcOffsetMinutes': 0,
        },
        {
          'observesDST': false,
          'timeZoneID': 'JST-9',
          'description': 'Japan Standard Time',
          'utcOffsetMinutes': 540,
        },
      ];

  /// Create unsorted timezone list for testing sorting behavior
  static List<Map<String, dynamic>> get unsortedTimezones => [
        {
          'observesDST': false,
          'timeZoneID': 'JST-9',
          'description': 'Japan Standard Time',
          'utcOffsetMinutes': 540,
        },
        {
          'observesDST': true,
          'timeZoneID': 'PST8',
          'description': 'Pacific Time',
          'utcOffsetMinutes': -480,
        },
        {
          'observesDST': false,
          'timeZoneID': 'UTC0',
          'description': 'UTC',
          'utcOffsetMinutes': 0,
        },
      ];

  // ============================================
  // Power Table Test Data
  // ============================================

  /// Create successful getPowerTableSettings JNAP response
  static JNAPSuccess createGetPowerTableSettingsSuccess({
    bool isPowerTableSelectable = true,
    List<String>? supportedCountries,
    String? country,
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'isPowerTableSelectable': isPowerTableSelectable,
        'supportedCountries': supportedCountries ?? _defaultSupportedCountries,
        'country': country ?? 'USA',
      },
    );
  }

  /// Create error response for setPowerTableSettings
  static JNAPError createSetPowerTableSettingsError({
    String errorCode = 'ErrorUnknown',
    String? errorMessage,
  }) {
    return JNAPError(
      result: errorCode,
      error: errorMessage,
    );
  }

  /// Create successful setPowerTableSettings JNAP response
  static JNAPSuccess createSetPowerTableSettingsSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create polling data map containing power table settings
  static Map<JNAPAction, JNAPResult> createPollingDataWithPowerTable({
    bool isPowerTableSelectable = true,
    List<String>? supportedCountries,
    String? country,
  }) {
    return {
      JNAPAction.getPowerTableSettings: createGetPowerTableSettingsSuccess(
        isPowerTableSelectable: isPowerTableSelectable,
        supportedCountries: supportedCountries,
        country: country,
      ),
    };
  }

  /// Create empty polling data (no power table)
  static Map<JNAPAction, JNAPResult> get emptyPollingData => {};

  /// Default supported countries list for testing
  static List<String> get _defaultSupportedCountries => [
        'USA',
        'CAN',
        'EEE',
        'JPN',
        'TWN',
      ];

  /// Unsorted countries list for testing sorting behavior
  static List<String> get unsortedCountries => [
        'TWN',
        'USA',
        'JPN',
        'CAN',
      ];

  // ============================================
  // Generic Error Helpers
  // ============================================

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

  /// Create network error
  static JNAPError createNetworkError() {
    return const JNAPError(
      result: 'ErrorNetworkFailure',
      error: 'Network communication failure',
    );
  }
}
