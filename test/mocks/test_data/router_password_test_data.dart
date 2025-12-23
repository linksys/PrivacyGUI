import 'dart:convert';

import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for RouterPasswordService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// Supports partial override pattern via named parameters.
class RouterPasswordTestData {
  /// Create successful fetchIsConfigured response
  static JNAPTransactionSuccessWrap createFetchConfiguredSuccess({
    bool isAdminPasswordDefault = false,
    bool isAdminPasswordSetByUser = true,
  }) {
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.isAdminPasswordDefault,
          JNAPSuccess(
            result: 'ok',
            output: {'isAdminPasswordDefault': isAdminPasswordDefault},
          ),
        ),
        MapEntry(
          JNAPAction.isAdminPasswordSetByUser,
          JNAPSuccess(
            result: 'ok',
            output: {'isAdminPasswordSetByUser': isAdminPasswordSetByUser},
          ),
        ),
      ],
    );
  }

  /// Create successful getAdminPasswordHint response
  static JNAPSuccess createPasswordHintSuccess({
    String hint = '',
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {'passwordHint': hint},
    );
  }

  /// Create successful password set response (generic)
  static JNAPSuccess createSetPasswordSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create successful recovery code verification response
  static JNAPSuccess createVerifyCodeSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create error response for invalid recovery code
  static JNAPError createVerifyCodeError({
    int attemptsRemaining = 2,
    String errorCode = 'ErrorInvalidResetCode',
  }) {
    return JNAPError(
      result: errorCode,
      error: jsonEncode({'attemptsRemaining': attemptsRemaining}),
    );
  }

  /// Create error response for exhausted recovery code attempts
  static JNAPError createVerifyCodeExhaustedError() {
    return JNAPError(
      result: 'ErrorConsecutiveInvalidResetCodeEntered',
      error: null,
    );
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
}
