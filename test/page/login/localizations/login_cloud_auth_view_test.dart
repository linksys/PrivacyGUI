import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/login/views/login_cloud_auth_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/auth_notifier_mocks.dart';
import '../../../test_data/gra_session_info_test_data.dart';

// The page Remote Assistance opens, with the session in its query
// parameters.
void main() {
  late MockAuthNotifier mockAuthNotifier;

  mockDependencyRegister();

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
    when(mockAuthNotifier.build())
        .thenAnswer((_) async => const AuthState(loginType: LoginType.none));
    when(mockAuthNotifier.testSessionAuthentication(
            token: anyNamed('token'), session: anyNamed('session')))
        .thenAnswer((_) async => graSessionInfoActiveTestData);
  });

  for (final (name, args) in [
    ('no session', <String, dynamic>{}),
    ('active session', {'token': 'token', 'session': 'session-1'}),
    ('error', {'error': 'The session has expired.'}),
  ]) {
    testLocalizations('Login cloud auth view - $name', (tester, locale) async {
      await tester.pumpWidget(testableSingleRoute(
        overrides: [authProvider.overrideWith(() => mockAuthNotifier)],
        locale: locale,
        child: LoginCloudAuthView(args: args),
      ));
    });
  }
}
