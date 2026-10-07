import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/connectivity_notifier_mocks.dart';
import '../../../test_data/_index.dart';

const _restartMessage =
    'Reboot Parent and All Child Nodes Restarting the mesh WiFi system will '
    'temporarily disconnect it from the Internet. If you have multiple nodes, '
    'all will restart. Connected devices will also experience a temporary '
    'disconnection but will automatically reconnect once the system is back '
    'online.';

// #1637: Restart network is the one menu row that changes the router, so it is
// the one marked isWrite; the rest only navigate.
void main() {
  mockDependencyRegister();

  Future<void> pumpMenu(WidgetTester tester, AccessPolicy policy) async {
    SharedPreferences.setMockInitialValues({});
    initBetterActions();
    final privacy = MockInstantPrivacyNotifier();
    when(privacy.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    final safety = MockInstantSafetyNotifier();
    when(safety.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState));
    final connectivity = MockConnectivityNotifier();
    when(connectivity.build()).thenReturn(ConnectivityState(
        hasInternet: true,
        connectivityInfo:
            ConnectivityInfo(routerType: RouterType.behindManaged)));
    final dashboardHome = MockDashboardHomeNotifier();
    when(dashboardHome.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeCherry7TestState));

    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableRouteShellWidget(
      locale: const Locale('en'),
      child: const DashboardMenuView(),
      overrides: [
        accessPolicyProvider.overrideWithValue(policy),
        instantPrivacyProvider.overrideWith(() => privacy),
        instantSafetyProvider.overrideWith(() => safety),
        connectivityProvider.overrideWith(() => connectivity),
        dashboardHomeProvider.overrideWith(() => dashboardHome),
      ],
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapRestart(WidgetTester tester) async {
    await tester.tap(find.text('Restart Network'), warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('Restart network is blocked in read-only mode', (tester) async {
    await pumpMenu(tester, const AccessPolicy(canWrite: false));

    await tapRestart(tester);

    expect(find.text(_restartMessage), findsNothing,
        reason: 'the restart confirmation never opens');
    expect(find.byTooltip('This feature is unavailable in remote mode'),
        findsOneWidget);
  });

  testWidgets('Restart network asks to confirm with full access',
      (tester) async {
    await pumpMenu(tester, AccessPolicy.full);

    await tapRestart(tester);

    expect(find.text(_restartMessage), findsOneWidget);
  });
}
