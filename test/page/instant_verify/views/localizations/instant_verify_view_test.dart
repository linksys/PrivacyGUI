import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/ethernet_port_connection_provider.dart';
import 'package:privacy_gui/core/jnap/providers/ethernet_port_connection_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_verify_view.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common/_index.dart';
import '../../../../common/di.dart';
import '../../../../mocks/_index.dart';
import '../../../../mocks/ethernet_port_connection_notifier_mocks.dart';
import '../../../../mocks/instant_verify_notifier_mocks.dart';
import '../../../../test_data/_index.dart';
import '../../../../test_data/ethernet_port_connection_test_state.dart';
import '../../../../test_data/instant_verify_test_state.dart';

void main() {
  late DashboardHomeNotifier mockDashboardHomeNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late DeviceManagerNotifier mockDeviceManagerNotifier;
  late InstantPrivacyNotifier mockInstantPrivacyNotifier;
  late InstantTopologyNotifier mockInstantTopologyNotifier;
  late InstantVerifyNotifier mockInstantVerifyNotifier;
  late DashboardManagerNotifier mockDashboardManagerNotifier;
  late EthernetPortConnectionNotifier mockEthernetPortConnectionNotifier;
  
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockInstantTopologyNotifier = MockInstantTopologyNotifier();
    mockInstantVerifyNotifier = MockInstantVerifyNotifier();
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();
    mockEthernetPortConnectionNotifier = MockEthernetPortConnectionNotifier();

    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeCherry7TestState));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockInstantTopologyNotifier.build())
        .thenReturn(TopologyTestData().testTopology2SlavesDaisyState);
    when(mockInstantVerifyNotifier.build())
        .thenReturn(InstantVerifyState.fromMap(instantVerifyTestState));
    when(mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));
    when(mockEthernetPortConnectionNotifier.build()).thenReturn(
        EthernetPortConnectionState.fromMap(portTestState));
  });
  testLocalizations(
    'Instant-Verify view - Instant-Topology',
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
            internetStatusProvider.overrideWith((ref) => InternetStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            ethernetPortConnectionProvider
                .overrideWith(() => mockEthernetPortConnectionNotifier),
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
    screens: [
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
    ],
  );

  testLocalizations('Instant-Verify view - Instant-Info view',
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
            internetStatusProvider.overrideWith((ref) => InternetStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            ethernetPortConnectionProvider
                .overrideWith(() => mockEthernetPortConnectionNotifier),
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
  }, screens: [
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 2880)).toList(),
  ]);

  testLocalizations('Instant-Verify view - Internal speed test tile',
      (tester, locale) async {
    when(mockDashboardHomeNotifier.build()).thenReturn(
        DashboardHomeState.fromMap(dashboardHomeCherry7TestState).copyWith(
            isHealthCheckSupported: true, healthCheckModule: () => 'Ookla'));
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
            internetStatusProvider.overrideWith((ref) => InternetStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            ethernetPortConnectionProvider
                .overrideWith(() => mockEthernetPortConnectionNotifier),
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
      await precacheImage(
          CustomTheme.of(context).images.speedtestPowered, context);

      await tester.pumpAndSettle();
    });
  }, screens: [
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 2880)).toList(),
  ]);

  testLocalizations('Instant-Verify view - Instant-Info view - Internet off',
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
            internetStatusProvider.overrideWith((ref) => InternetStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            ethernetPortConnectionProvider
                .overrideWith(() => mockEthernetPortConnectionNotifier),
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
  }, screens: [
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 2880)).toList(),
  ]);

  testLocalizations('Instant-Verify view - Instant-Info view - WiFi off',
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
            internetStatusProvider.overrideWith((ref) => InternetStatus.online),
            instantPrivacyProvider
                .overrideWith(() => mockInstantPrivacyNotifier),
            instantTopologyProvider
                .overrideWith(() => mockInstantTopologyNotifier),
            instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
            dashboardManagerProvider
                .overrideWith(() => mockDashboardManagerNotifier),
            ethernetPortConnectionProvider
                .overrideWith(() => mockEthernetPortConnectionNotifier),
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
  }, screens: [
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 2880)).toList(),
  ]);

  testLocalizations(
    'Instant-Verify view - Instant-Info view - firmware update available',
    (tester, locale) async {
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const InstantVerifyView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              internetStatusProvider
                  .overrideWith((ref) => InternetStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
              instantVerifyProvider
                  .overrideWith(() => mockInstantVerifyNotifier),
              dashboardManagerProvider
                  .overrideWith(() => mockDashboardManagerNotifier),
              ethernetPortConnectionProvider
                  .overrideWith(() => mockEthernetPortConnectionNotifier),
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
    },
    screens: [
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2880)).toList(),
    ],
  );

  testLocalizations(
    'Instant-Verify view - Instant-Info view - no WAN port',
    (tester, locale) async {
      final testState =
          InstantVerifyState.fromMap(instantVerifyAllWiFiOffTestState);
      when(mockInstantVerifyNotifier.build()).thenReturn(testState);
      when(mockEthernetPortConnectionNotifier.build()).thenReturn(
          EthernetPortConnectionState.fromMap(portTestState).copyWith(primaryWAN: 'None'));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const InstantVerifyView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              internetStatusProvider
                  .overrideWith((ref) => InternetStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
              instantVerifyProvider
                  .overrideWith(() => mockInstantVerifyNotifier),
              dashboardManagerProvider
                  .overrideWith(() => mockDashboardManagerNotifier),
              ethernetPortConnectionProvider
                  .overrideWith(() => mockEthernetPortConnectionNotifier),
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
    },
    screens: [
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2880)).toList(),
    ],
  );

  testLocalizations(
    'Instant-Verify view - Instant-Info view - multi-DNS',
    (tester, locale) async {
      final testState =
          InstantVerifyState.fromMap(instantVerifyMultiDNSTestState);
      when(mockInstantVerifyNotifier.build()).thenReturn(testState);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const InstantVerifyView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              internetStatusProvider
                  .overrideWith((ref) => InternetStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
              instantVerifyProvider
                  .overrideWith(() => mockInstantVerifyNotifier),
              dashboardManagerProvider
                  .overrideWith(() => mockDashboardManagerNotifier),
              ethernetPortConnectionProvider
                  .overrideWith(() => mockEthernetPortConnectionNotifier),
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
    },
    screens: [
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2880)).toList(),
    ],
  );
}
