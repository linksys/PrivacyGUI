// The local login routes (route_local_login.dart): the password login and
// the recovery flow under it.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacy_gui/page/login/views/local_router_recovery_view.dart';
import 'package:privacy_gui/page/login/views/login_local_view.dart';
import 'package:privacy_gui/route/constants.dart';

import 'app_route_builder.dart';

void main() {
  late AppRoutes routes;

  setUp(() => routes = AppRoutes());
  tearDown(() => routes.dispose());

  group('localLoginPassword', () {
    // The prepare page sends a failed login back here with ?error=.
    testWidgets('hands the login page its URL query over what it was pushed '
        'with', (tester) async {
      final built = await routes.build(tester, RouteNamed.localLoginPassword,
          extra: {'error': 'from-push', 'keep': 1},
          query: {'error': 'Unexpected'});

      expect(built, isA<LoginLocalView>());
      expect(argsOf(built), {'error': 'Unexpected', 'keep': 1});
    });

    testWidgets('opened by its URL alone, hands it no arguments',
        (tester) async {
      expect(argsOf(await routes.build(tester, RouteNamed.localLoginPassword)),
          isEmpty);
    });
  });

  testWidgets('localRouterRecovery builds the recovery page', (tester) async {
    expect(await routes.build(tester, RouteNamed.localRouterRecovery),
        isA<LocalRouterRecoveryView>());
  });

  testWidgets(
      'localPasswordReset hands the reset page the arguments it was pushed '
      'with', (tester) async {
    final extra = <String, dynamic>{'token': 'recovery-key'};

    final built = await routes.build(tester, RouteNamed.localPasswordReset,
        extra: extra);

    expect(built, isA<LocalResetRouterPasswordView>());
    expect(argsOf(built), extra);
  });
}
