import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/auth/auth_service.dart';

void main() {
  late AuthService service;

  setUp(() {
    service = AuthService();
  });

  group('AuthService — clearAllCredentials', () {
    test('completes without error (no-op)', () async {
      // clearAllCredentials is now a no-op since token storage
      // is handled by UspAuthCoordinator
      await expectLater(service.clearAllCredentials(), completes);
    });
  });
}
