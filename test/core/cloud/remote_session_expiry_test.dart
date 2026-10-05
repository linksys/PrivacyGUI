import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/remote_session_expiry.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

void main() {
  group('isRemoteSessionExpired', () {
    // The body linksys-cloud2 sends from LexRemoteSessionExpiredException
    // (#94): a LexError serialised flat, with `code` at the top level.
    test('recognises the cloud refusing a request on an ended session', () {
      final error = ErrorResponse.fromJson(400, {
        'code': 'SESSION_EXPIRED',
        'errorMessage': 'Remote Assistance session has expired',
        'parameters': [],
      });

      expect(isRemoteSessionExpired(error), isTrue);
    });

    test('also recognises the code in the errors-list shape', () {
      final error = ErrorResponse.fromJson(400, {
        'errors': [
          {
            'error': {'code': 'SESSION_EXPIRED', 'message': 'expired'}
          }
        ],
      });

      expect(isRemoteSessionExpired(error), isTrue);
    });

    test('ignores other cloud errors', () {
      expect(
          isRemoteSessionExpired(
              const ErrorResponse(status: 401, code: 'INVALID_SESSION_TOKEN')),
          isFalse);
      expect(
          isRemoteSessionExpired(
              const ErrorResponse(status: 1000, code: 'REQUEST_TIMEOUT')),
          isFalse);
    });

    test('ignores anything that is not a cloud error', () {
      expect(isRemoteSessionExpired(const JNAPError(result: 'SESSION_EXPIRED')),
          isFalse,
          reason: 'a router result is not the cloud ending the session');
      expect(isRemoteSessionExpired(Exception('SESSION_EXPIRED')), isFalse);
      expect(isRemoteSessionExpired(null), isFalse);
    });
  });
}
