import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for NodeDetailService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class NodeDetailTestData {
  /// Create a successful JNAP response for startBlinkNodeLed action
  static JNAPSuccess createBlinkNodeSuccess() => const JNAPSuccess(
        result: 'ok',
        output: {},
      );

  /// Create a successful JNAP response for stopBlinkNodeLed action
  static JNAPSuccess createStopBlinkNodeSuccess() => const JNAPSuccess(
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
