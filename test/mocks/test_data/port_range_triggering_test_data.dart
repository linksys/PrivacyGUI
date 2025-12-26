import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for Port Range Triggering Service tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class PortRangeTriggeringTestData {
  /// Create a default single rule (Xbox Live example)
  static Map<String, dynamic> createDefaultRule({
    bool isEnabled = true,
    int firstTriggerPort = 3074,
    int lastTriggerPort = 3074,
    int firstForwardedPort = 3074,
    int lastForwardedPort = 3074,
    String description = 'XBox Live',
  }) {
    return {
      'isEnabled': isEnabled,
      'firstTriggerPort': firstTriggerPort,
      'lastTriggerPort': lastTriggerPort,
      'firstForwardedPort': firstForwardedPort,
      'lastForwardedPort': lastForwardedPort,
      'description': description,
    };
  }

  /// Create a port range rule (multiple ports)
  static Map<String, dynamic> createPortRangeRule({
    bool isEnabled = true,
    int firstTriggerPort = 6000,
    int lastTriggerPort = 6100,
    int firstForwardedPort = 7000,
    int lastForwardedPort = 7100,
    String description = 'Game Server',
  }) {
    return {
      'isEnabled': isEnabled,
      'firstTriggerPort': firstTriggerPort,
      'lastTriggerPort': lastTriggerPort,
      'firstForwardedPort': firstForwardedPort,
      'lastForwardedPort': lastForwardedPort,
      'description': description,
    };
  }

  /// Create a disabled rule
  static Map<String, dynamic> createDisabledRule() {
    return createDefaultRule(
      isEnabled: false,
      description: 'Disabled Rule',
    );
  }

  /// Create default GetPortRangeTriggeringRules success response
  static JNAPSuccess createGetRulesSuccess({
    List<Map<String, dynamic>>? rules,
    int maxRules = 50,
    int maxDescriptionLength = 32,
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'rules': rules ??
            [
              createDefaultRule(),
              createPortRangeRule(),
            ],
        'maxRules': maxRules,
        'maxDescriptionLength': maxDescriptionLength,
      },
    );
  }

  /// Create empty rules response
  static JNAPSuccess createEmptyRulesSuccess({
    int maxRules = 50,
    int maxDescriptionLength = 32,
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'rules': [],
        'maxRules': maxRules,
        'maxDescriptionLength': maxDescriptionLength,
      },
    );
  }

  /// Create SetPortRangeTriggeringRules success response
  static JNAPSuccess createSetRulesSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: <String, dynamic>{},
    );
  }

  /// Create JNAP error response for unauthorized access
  static JNAPError createUnauthorizedError() {
    return const JNAPError(
      result: '_ErrorUnauthorized',
      error: 'Unauthorized access',
    );
  }

  /// Create JNAP error response for invalid input
  static JNAPError createInvalidInputError({String? message}) {
    return JNAPError(
      result: 'ErrorInvalidInput',
      error: message ?? 'Invalid input data',
    );
  }

  /// Create JNAP error response for rule overlap
  static JNAPError createRuleOverlapError() {
    return const JNAPError(
      result: 'ErrorRuleOverlap',
      error: 'Port triggering rules overlap',
    );
  }

  /// Create a complete successful JNAP transaction response
  ///
  /// Supports partial override design: only specify fields that need to change
  static JNAPTransactionSuccessWrap createSuccessfulTransaction({
    Map<String, dynamic>? portRules,
  }) {
    final defaultPortRules = {
      'rules': [
        createDefaultRule(),
      ],
      'maxRules': 50,
      'maxDescriptionLength': 32,
    };

    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.getPortRangeTriggeringRules,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultPortRules, ...?portRules},
          ),
        ),
      ],
    );
  }

  /// Create a partial error transaction (for error handling tests)
  static JNAPTransactionSuccessWrap createPartialErrorTransaction({
    required JNAPAction errorAction,
    String errorMessage = 'Operation failed',
  }) {
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          errorAction,
          JNAPError(
            result: 'Error',
            error: errorMessage,
          ),
        ),
      ],
    );
  }
}
