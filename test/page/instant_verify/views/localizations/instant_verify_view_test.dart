import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_verify_view.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common/_index.dart';
import '../../../../mocks/_index.dart';
import '../../../../mocks/instant_verify_notifier_mocks.dart';
import '../../../../mocks/jnap_service_supported_mocks.dart';
import '../../../../test_data/_index.dart';
import '../../../../test_data/instant_verify_test_state.dart';

void main() {
  late DashboardHomeNotifier mockDashboardHomeNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late DeviceManagerNotifier mockDeviceManagerNotifier;
  late InstantPrivacyNotifier mockInstantPrivacyNotifier;
  late InstantTopologyNotifier mockInstantTopologyNotifier;
  late InstantVerifyNotifier mockInstantVerifyNotifier;
  late DashboardManagerNotifier mockDashboardManagerNotifier;

  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockInstantTopologyNotifier = MockInstantTopologyNotifier();
    mockInstantVerifyNotifier = MockInstantVerifyNotifier();
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();

    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeStateData));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerTestData));
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockInstantTopologyNotifier.build())
        .thenReturn(testTopology2SlavesDaisyState);
    when(mockInstantVerifyNotifier.build())
        .thenReturn(InstantVerifyState.fromMap(instantVerifyTestState));
    when(mockDashboardManagerNotifier.build())
        .thenReturn(DashboardManagerState.fromMap(dashboardManagerTestState));
  });
  testLocalizations(
    'Instant verify view - topology',
    (tester, locale) async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(InstantVerifyView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
      final topologyTabFinder = find.byType(Tab).last;

      await tester.tap(topologyTabFinder);

      await tester.pumpAndSettle();
    },
  );

  testLocalizations('Instant verify view - mobile basic',
      (tester, locale) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
      await tester.pumpAndSettle();
    });
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant verify view - mobile - firmware update available',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
      await tester.pumpAndSettle();
    });
  }, screens: responsiveMobileScreens);

  testLocalizations(
      'Instant verify view - mobile basic - scroll to connectivity',
      (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantTopologyProvider
              .overrideWith(() => mockInstantTopologyNotifier),
          instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(Scrollable).last));
    // Manual scroll
    await gesture.moveBy(const Offset(0, -100));
    await gesture.moveBy(Offset(0, -(tester.view.physicalSize.height - 240)));

    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
    });
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant verify view - mobile basic - internet off',
      (tester, locale) async {
    final testState =
        InstantVerifyState.fromMap(instantVerifyInternetOffTestState);
    when(mockInstantVerifyNotifier.build()).thenReturn(testState);
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantTopologyProvider
              .overrideWith(() => mockInstantTopologyNotifier),
          instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(Scrollable).last));
    // Manual scroll
    await gesture.moveBy(const Offset(0, -100));
    await gesture.moveBy(Offset(0, -(tester.view.physicalSize.height - 240)));

    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
    });
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);
  testLocalizations('Instant verify view - mobile basic - all WiFi off',
      (tester, locale) async {
    final testState =
        InstantVerifyState.fromMap(instantVerifyAllWiFiOffTestState);
    when(mockInstantVerifyNotifier.build()).thenReturn(testState);
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantTopologyProvider
              .overrideWith(() => mockInstantTopologyNotifier),
          instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(Scrollable).last));
    // Manual scroll
    await gesture.moveBy(const Offset(0, -100));
    await gesture.moveBy(Offset(0, -(tester.view.physicalSize.height - 240)));

    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
    });
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant verify view - mobile basic - scroll to speedtest',
      (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantTopologyProvider
              .overrideWith(() => mockInstantTopologyNotifier),
          instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(Scrollable).last));
    // Manual scroll
    await gesture.moveBy(const Offset(0, -100));
    await gesture.moveBy(Offset(0, -(tester.view.physicalSize.height - 240)));
    await gesture.moveBy(Offset(0, -(tester.view.physicalSize.height - 240)));

    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
    });
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant verify view - mobile basic - scroll to port',
      (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantTopologyProvider
              .overrideWith(() => mockInstantTopologyNotifier),
          instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
    });
    await tester.pumpAndSettle();
    final secondCardFinder = find.byKey(const ValueKey('portCard'));

    await tester.scrollUntilVisible(secondCardFinder, 100,
        scrollable: find
            .descendant(
                of: find.byType(StyledAppTabPageView),
                matching: find.byType(Scrollable))
            .last);

    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant verify view - desktop basic',
      (tester, locale) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
      await tester.pumpAndSettle();
    });
  }, screens: responsiveDesktopScreens);

  testLocalizations('Instant verify view - desktop - firmware update available',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final secondCardFinder = find.byKey(const ValueKey('portCard'));

      await tester.scrollUntilVisible(secondCardFinder, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppTabPageView),
                  matching: find.byType(Scrollable))
              .last);

      await tester.pumpAndSettle();
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
      await tester.pumpAndSettle();
    });
  }, screens: responsiveDesktopScreens);
  testLocalizations('Instant verify view - desktop - internet off',
      (tester, locale) async {
    final testState =
        InstantVerifyState.fromMap(instantVerifyInternetOffTestState);
    when(mockInstantVerifyNotifier.build()).thenReturn(testState);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
      await tester.pumpAndSettle();
    });
  }, screens: responsiveDesktopScreens);
  testLocalizations('Instant verify view - desktop - all WiFi off',
      (tester, locale) async {
    final testState =
        InstantVerifyState.fromMap(instantVerifyAllWiFiOffTestState);
    when(mockInstantVerifyNotifier.build()).thenReturn(testState);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
      await tester.pumpAndSettle();
    });
  }, screens: responsiveDesktopScreens);
  testLocalizations('Instant verify view - desktop - scroll to port',
      (tester, locale) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(InstantVerifyView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerWhw03, context);
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMr7500, context);
      await tester.pumpAndSettle();
      final secondCardFinder = find.byKey(const ValueKey('portCard'));

      await tester.scrollUntilVisible(secondCardFinder, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppTabPageView),
                  matching: find.byType(Scrollable))
              .last);

      await tester.pumpAndSettle();
    });
  }, screens: responsiveDesktopScreens);
}
