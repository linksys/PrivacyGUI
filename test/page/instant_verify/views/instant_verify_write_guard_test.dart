import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
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
import 'package:privacy_gui/page/instant_verify/views/components/speed_test_external_widget.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_verify_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/instant_verify_notifier_mocks.dart';
import '../../../test_data/_index.dart';
import '../../../test_data/instant_verify_test_state.dart';

/// The channel the in-app browser opens a page through.
const _browserChannel =
    MethodChannel('com.pichillilorenzo/flutter_inappbrowser');

void main() {
  mockDependencyRegister();

  late List<String> openedUrls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    openedUrls = [];
  });

  Future<void> pumpVerify(WidgetTester tester,
      {bool remoteLogin = false}) async {
    await tester.setScreenSize(device1440w.copyWith(height: 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(_browserChannel, (call) async {
      if (call.method == 'open') {
        final request = (call.arguments as Map)['urlRequest'] as Map;
        openedUrls.add(request['url'] as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(_browserChannel, null));

    final dashboardHome = MockDashboardHomeNotifier();
    final firmware = MockFirmwareUpdateNotifier();
    final deviceManager = MockDeviceManagerNotifier();
    final privacy = MockInstantPrivacyNotifier();
    final topology = MockInstantTopologyNotifier();
    final verify = MockInstantVerifyNotifier();
    final dashboardManager = MockDashboardManagerNotifier();
    // No health check module on this router, so the page offers the external
    // speed tests instead.
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
    when(verify.build())
        .thenReturn(InstantVerifyState.fromMap(instantVerifyTestState));
    when(dashboardManager.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        dashboardHomeProvider.overrideWith(() => dashboardHome),
        firmwareUpdateProvider.overrideWith(() => firmware),
        deviceManagerProvider.overrideWith(() => deviceManager),
        internetStatusProvider.overrideWith((ref) => InternetStatus.online),
        instantPrivacyProvider.overrideWith(() => privacy),
        instantTopologyProvider.overrideWith(() => topology),
        instantVerifyProvider.overrideWith(() => verify),
        dashboardManagerProvider.overrideWith(() => dashboardManager),
        isRemoteLoginProvider.overrideWithValue(remoteLogin),
      ],
      child: const InstantVerifyView(),
    ));
    await tester.pumpAndSettle();
  }

  // #1637: the external speed tests measure the connection of the device the
  // app runs on. Over a remote session that is not the router's network, so the
  // tile is local-only: any remote login is kept out of it, full access or not.
  group('external speed test', () {
    final cloudFlare = find.descendant(
        of: find.byType(SpeedTestExternalWidget),
        matching: find.text('CloudFlare'));

    testWidgets('is blocked on a remote login, even with full access',
        (tester) async {
      await pumpVerify(tester, remoteLogin: true);

      expect(
          find.ancestor(
              of: find.byType(SpeedTestExternalWidget),
              matching:
                  find.byTooltip('This feature is unavailable in remote mode')),
          findsOneWidget);

      await tester.tap(cloudFlare, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(openedUrls, isEmpty);
    });

    testWidgets('opens the speed test on a local login', (tester) async {
      await pumpVerify(tester);

      await tester.tap(cloudFlare);
      await tester.pumpAndSettle();

      expect(openedUrls, ['https://speed.cloudflare.com/']);
    });
  });
}
