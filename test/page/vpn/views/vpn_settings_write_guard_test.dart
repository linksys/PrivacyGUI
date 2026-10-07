import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/views/vpn_settings_page.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/vpn_notifier_mocks.dart';
import '../../../test_data/vpn_test_state.dart';

void main() {
  mockDependencyRegister();

  late MockVPNNotifier vpn;

  Future<void> pumpPage(WidgetTester tester,
      {AccessPolicy policy = AccessPolicy.full}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    vpn = MockVPNNotifier();
    when(vpn.build()).thenReturn(VPNTestState.defaultState);
    when(vpn.fetch()).thenAnswer((_) async => VPNTestState.defaultState);
    when(vpn.testVPNConnection())
        .thenAnswer((_) async => VPNTestState.testResultState);

    await tester.pumpWidget(testableSingleRoute(
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 12),
        noNaviRail: true,
      ),
      locale: const Locale('en'),
      overrides: [
        vpnProvider.overrideWith(() => vpn),
        accessPolicyProvider.overrideWithValue(policy),
      ],
      child: const VPNSettingsPage(),
    ));
    await tester.pumpAndSettle();
  }

  // #1637: "Test again" makes the router run a connection test, and saves any
  // unsaved changes first, so it is blocked before it gets that far.
  group('test again', () {
    final testAgain = find.byKey(const ValueKey('testAgain'));

    testWidgets('is blocked in read-only mode', (tester) async {
      await pumpPage(tester, policy: const AccessPolicy(canWrite: false));

      expect(
          find.ancestor(
              of: testAgain,
              matching:
                  find.byTooltip('This feature is unavailable in remote mode')),
          findsOneWidget);

      await tester.tap(testAgain, warnIfMissed: false);
      await tester.pumpAndSettle();

      verifyNever(vpn.testVPNConnection());
    });

    testWidgets('runs the test with full access', (tester) async {
      await pumpPage(tester);

      await tester.tap(testAgain);
      await tester.pumpAndSettle();

      verify(vpn.testVPNConnection()).called(1);
    });
  });
}
