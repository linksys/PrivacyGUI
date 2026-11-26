// The account login route (route_cloud_login.dart). After #1849 deleted the
// account login itself, /cloudLoginAuth stays as where a Guardian Remote
// Assistance link lands, and where a login that may not write is sent back
// to (prepare_dashboard_view.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/login/views/login_cloud_auth_view.dart';
import 'package:privacy_gui/route/constants.dart';

import 'app_route_builder.dart';

void main() {
  late AppRoutes routes;

  setUp(() => routes = AppRoutes());
  tearDown(() => routes.dispose());

  testWidgets('hands the page a Guardian link\'s token and session',
      (tester) async {
    final built = await routes.build(tester, RouteNamed.cloudLoginAuth,
        query: {'token': 'ra-token', 'session': 'S-1'});

    expect(built, isA<LoginCloudAuthView>());
    expect(argsOf(built), {'token': 'ra-token', 'session': 'S-1'});
  });

  testWidgets('hands the page its URL query over what it was pushed with',
      (tester) async {
    final built = await routes.build(tester, RouteNamed.cloudLoginAuth,
        extra: <String, dynamic>{'error': 'from-push', 'keep': 1},
        query: {'error': 'Unexpected'});

    expect(argsOf(built), {'error': 'Unexpected', 'keep': 1});
  });
}
