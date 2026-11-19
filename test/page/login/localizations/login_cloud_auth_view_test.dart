import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/page/login/views/login_cloud_auth_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

/// A Remote Assistance session that the cloud answers for at once.
class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthState(loginType: LoginType.none);

  @override
  Future<GRASessionInfo?> testSessionAuthentication(
          {required String token, required String session}) async =>
      const GRASessionInfo(
        id: 'session-1',
        serialNumber: '65G10M27E03041',
        modelNumber: 'LN12',
        status: GRASessionStatus.active,
        expiredIn: 1800,
        createdAt: 0,
        statusChangedAt: 0,
        currentTime: 0,
      );
}

// The page Remote Assistance opens with the session in its query parameters.
void main() {
  mockDependencyRegister();

  for (final (name, args) in [
    ('no session', <String, dynamic>{}),
    ('active session', {'token': 'token', 'session': 'session-1'}),
    ('error', {'error': 'The session has expired.'}),
  ]) {
    testLocalizations('Login cloud auth view - $name', (tester, locale) async {
      await tester.pumpWidget(testableSingleRoute(
        overrides: [authProvider.overrideWith(_Auth.new)],
        locale: locale,
        child: LoginCloudAuthView(args: args),
      ));
    });
  }
}
