import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/prototype_shell.dart';
import 'package:privacy_gui/route/constants.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import 'instant_test_harness.dart';

// The local-build preview shows the same pages, with the top bar, on mock
// data, and navigates between them under its own route names.
void main() {
  mockDependencyRegister();

  Future<GoRouter> open(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
        initialLocation: location, routes: [instantPrototypeRoute()]);
    addTearDown(router.dispose);
    await tester.pumpWidget(testableRouter(router: router));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('preview pages navigate like the menu route', (tester) async {
    final router = await open(tester, RoutePath.instantPrototype);
    expect(find.byType(TopBar), findsOneWidget);
    expect(find.text('Instant-Test'), findsOneWidget);
    expect(find.text('Demo controls'), findsOneWidget);
    // Nothing underneath the preview home, so no back arrow.
    expect(backButton, findsNothing);

    await tapText(tester, 'Whole internet is slow');
    expect(topRoute(router), RouteNamed.instantPrototypeHelp);
    expect(topLocation(router).toString(), '/instant-prototype/help?flow=2');
    expect(find.text('My internet is slow'), findsOneWidget);
    expect(find.text('Demo controls'), findsOneWidget);

    // A lateral flow pushes another help page; Back returns to the origin.
    await tapText(tester, 'Check my speed');
    await tapText(tester, 'Just one specific device');
    expect(find.text('One device is slow'), findsOneWidget);
    await tapBack(tester);
    expect(find.text('My internet is slow'), findsOneWidget);

    // Check again returns to the preview home.
    await tapText(tester, 'Check again');
    expect(topRoute(router), RouteNamed.instantPrototype);
  });

  testWidgets('preview help and details are addressable', (tester) async {
    final router = await open(tester, '/instant-prototype/help?flow=4');
    expect(find.text("WiFi doesn't reach a room"), findsOneWidget);
    await tapBack(tester);
    expect(topRoute(router), RouteNamed.instantPrototype);
    router.go('/instant-prototype/devices');
    await tester.pumpAndSettle();
    expect(find.text('Device details'), findsOneWidget);
    router.go('/instant-prototype/network');
    await tester.pumpAndSettle();
    expect(find.text('Network details'), findsOneWidget);
  });
}
