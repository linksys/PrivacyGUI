import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';

void main() {
  // #1637: the body linksys-cloud2 sends from LexRemoteSessionExpiredException
  // (#94). The auth error handler acts on the code, so it has to come out of
  // both shapes a LexError is serialised in.
  group('SESSION_EXPIRED', () {
    test('is read from a flat LexError', () {
      final error = ErrorResponse.fromJson(400, {
        'code': 'SESSION_EXPIRED',
        'errorMessage': 'Remote Assistance session has expired',
        'parameters': [],
      });

      expect(error.code, errorRemoteSessionExpired);
      expect(error.status, 400);
    });

    test('is read from an errors list', () {
      final error = ErrorResponse.fromJson(400, {
        'errors': [
          {
            'error': {'code': 'SESSION_EXPIRED', 'message': 'expired'}
          }
        ],
      });

      expect(error.code, errorRemoteSessionExpired);
    });
  });
}
