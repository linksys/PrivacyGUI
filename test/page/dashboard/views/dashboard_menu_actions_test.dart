import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/connectivity_notifier_mocks.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../test_data/_index.dart';

// The dashboard menu's page actions with full access: Restart network and Set
// up a new product are both offered, and Restart network still reaches the
// reboot after its confirmation. #1637 blocks Restart network in read-only
// mode (dashboard_menu_write_guard_test.dart).
void main() {
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;
  late MockInstantSafetyNotifier mockInstantSafetyNotifier;
  late MockConnectivityNotifier mockConnectivityNotifier;
  late MockDashboardHomeNotifier mockDashboardHomeNotifier;
  late MockInstantTopologyNotifier mockTopologyNotifier;
  late MockPollingNotifier mockPollingNotifier;

  mockDependencyRegister();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockInstantSafetyNotifier = MockInstantSafetyNotifier();
    mockConnectivityNotifier = MockConnectivityNotifier();
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
    mockTopologyNotifier = MockInstantTopologyNotifier();
    mockPollingNotifier = MockPollingNotifier();

    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState));
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockConnectivityNotifier.build()).thenReturn(const ConnectivityState(
        hasInternet: true,
        connectivityInfo:
            ConnectivityInfo(routerType: RouterType.behindManaged)));
    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeCherry7TestState));
    when(mockTopologyNotifier.build())
        .thenReturn(TopologyTestData().testTopology1SlaveState);
    when(mockTopologyNotifier.reboot(any)).thenAnswer((_) async {});
    initBetterActions();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableRouteShellWidget(
      locale: const Locale('en'),
      child: const DashboardMenuView(),
      overrides: [
        accessPolicyProvider.overrideWithValue(AccessPolicy.full),
        instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
        instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        connectivityProvider.overrideWith(() => mockConnectivityNotifier),
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
        instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        pollingProvider.overrideWith(() => mockPollingNotifier),
      ],
    ));
    await tester.pumpAndSettle();
  }

  List<PageMenuItem> menuItems(WidgetTester tester) => tester
      .widget<StyledAppPageView>(find.byType(StyledAppPageView).first)
      .menu!
      .items;

  testWidgets('offers restart network and set up a new product',
      (tester) async {
    await pump(tester);

    expect(menuItems(tester).map((e) => e.icon),
        [LinksysIcons.restartAlt, LinksysIcons.add]);
    expect(menuItems(tester).every((e) => e.onTap != null), isTrue);
  });

  testWidgets('restart network asks first, then reboots', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(LinksysIcons.restartAlt).last);
    await tester.pumpAndSettle();
    verifyNever(mockTopologyNotifier.reboot(any));

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    verify(mockTopologyNotifier.reboot()).called(1);
  });
}
