import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_verify_view.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/instant_verify_notifier_mocks.dart';
import '../../../test_data/_index.dart';
import '../../../test_data/instant_verify_test_state.dart';

void main() {
  mockDependencyRegister();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpVerify(
    WidgetTester tester, {
    required InternetStatus internetStatus,
    required bool hasWanConnection,
  }) async {
    await tester.setScreenSize(device1440w.copyWith(height: 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final dashboardHome = MockDashboardHomeNotifier();
    final firmware = MockFirmwareUpdateNotifier();
    final deviceManager = MockDeviceManagerNotifier();
    final privacy = MockInstantPrivacyNotifier();
    final topology = MockInstantTopologyNotifier();
    final verify = MockInstantVerifyNotifier();
    final dashboardManager = MockDashboardManagerNotifier();
    when(dashboardHome.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeCherry7TestState));
    when(firmware.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(deviceManager.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(privacy.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(topology.build())
        .thenReturn(TopologyTestData().testTopology2SlavesDaisyState);
    when(verify.build()).thenReturn(InstantVerifyState.fromMap(hasWanConnection
        ? instantVerifyTestState
        : (Map<String, dynamic>.from(instantVerifyTestState)
          ..remove('wanConnection'))));
    when(dashboardManager.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        dashboardHomeProvider.overrideWith(() => dashboardHome),
        firmwareUpdateProvider.overrideWith(() => firmware),
        deviceManagerProvider.overrideWith(() => deviceManager),
        internetStatusProvider.overrideWith((ref) => internetStatus),
        instantPrivacyProvider.overrideWith(() => privacy),
        instantTopologyProvider.overrideWith(() => topology),
        instantVerifyProvider.overrideWith(() => verify),
        dashboardManagerProvider.overrideWith(() => dashboardManager),
      ],
      child: const InstantVerifyView(),
    ));
    await tester.pumpAndSettle();
  }

  /// The status circle in the connectivity card's Internet row.
  Icon internetIndicator(WidgetTester tester) {
    final row = find
        .ancestor(of: find.text('Internet'), matching: find.byType(Row))
        .first;
    return tester
        .widget<Icon>(find.descendant(of: row, matching: find.byType(Icon)));
  }

  /// The value shown under a WAN info label, e.g. 'WAN' or 'Gateway'.
  Finder wanInfoValue(String label, String value) => find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(Wrap)),
        matching: find.text(value),
      );

  Color green(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(InstantVerifyView)))
          .colorSchemeExt
          .green!;

  // #1764: the Internet indicator follows the same internetStatusProvider as
  // the Dashboard, so the two pages agree. The WAN info below it still comes
  // from GetWANStatus' wanConnection, which the router omits while the WAN
  // (e.g. a PPTP session) is still connecting, even when
  // GetInternetConnectionStatus already reports InternetConnected.
  group('Internet indicator', () {
    testWidgets(
        'is green when the Internet is online, even without a WAN '
        'connection', (tester) async {
      await pumpVerify(tester,
          internetStatus: InternetStatus.online, hasWanConnection: false);

      expect(internetIndicator(tester).color, green(tester));
      expect(wanInfoValue('WAN', '--'), findsOneWidget);
      expect(wanInfoValue('Gateway', '--'), findsOneWidget);
      expect(wanInfoValue('Connection Type', '--'), findsOneWidget);
    });

    testWidgets(
        'is not green when the Internet is offline, even with a WAN '
        'connection', (tester) async {
      await pumpVerify(tester,
          internetStatus: InternetStatus.offline, hasWanConnection: true);

      expect(internetIndicator(tester).color, isNot(green(tester)));
      expect(wanInfoValue('WAN', '192.168.50.105'), findsOneWidget);
    });
  });
}
