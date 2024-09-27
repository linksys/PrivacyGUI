import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../test_data/_index.dart';

void main() async {
  late DashboardHomeNotifier mockDashboardHomeNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late DeviceManagerNotifier mockDeviceManagerNotifier;
  late InstantPrivacyNotifier mockInstantPrivacyNotifier;
  late InstantTopologyNotifier mockInstantTopologyNotifier;

  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('Dashboard Home View with 4-ports', () {
    setUp(() {
      mockDashboardHomeNotifier = MockDashboardHomeNotifier();
      mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
      mockDeviceManagerNotifier = MockDeviceManagerNotifier();
      mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
      mockInstantTopologyNotifier = MockInstantTopologyNotifier();

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
    });

    testLocalizations('Dashboard Home View - 4-ports mobile layout',
        (tester, locale) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveMobileScreens);

    testLocalizations('Dashboard Home View - 4-ports horizontal layout',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData)
              .copyWith(isHorizontalLayout: true));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations('Dashboard Home View - 4-ports vertical layout',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData)
              .copyWith(isHorizontalLayout: false));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations(
        'Dashboard Home View - 4-ports mobile layout with speed check',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData)
              .copyWith(isHealthCheckSupported: true));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(DashboardHomeView));
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
        'Dashboard Home View - 4-ports horizontal layout with speed check',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
        isHorizontalLayout: true,
        isHealthCheckSupported: true,
      ));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations(
        'Dashboard Home View - 4-ports vertical layout with speed check',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
        isHorizontalLayout: false,
        isHealthCheckSupported: true,
      ));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
        final speedCheckFinder = find.byKey(const ValueKey('speedCheck'));
        await tester.scrollUntilVisible(speedCheckFinder, 10,
            scrollable: find
                .descendant(
                    of: find.byType(StyledAppPageView),
                    matching: find.byType(Scrollable))
                .last);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations(
        'Dashboard Home View - 4-ports mobile layout fw update available',
        (tester, locale) async {
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(DashboardHomeView));
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
        'Dashboard Home View - 4-ports horizontal layout fw update available',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData)
              .copyWith(isHorizontalLayout: true));
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations(
        'Dashboard Home View - 4-ports vertical layout fw update avaliable',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData)
              .copyWith(isHorizontalLayout: false));
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations('Dashboard Home View - 4-ports mobile layout internet offline',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeOfflineStateData).copyWith(
        isHorizontalLayout: false,
      ));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider
                  .overrideWith((ref) => NodeWANStatus.offline),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveMobileScreens);

    testLocalizations('Dashboard Home View - 4-ports horizontal layout internet offline',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeOfflineStateData)
              .copyWith(isHorizontalLayout: true));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider
                  .overrideWith((ref) => NodeWANStatus.offline),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations('Dashboard Home View - 4-ports vertical layout internet offline',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeOfflineStateData).copyWith(
        isHorizontalLayout: false,
      ));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider
                  .overrideWith((ref) => NodeWANStatus.offline),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations(
        'Dashboard Home View - 4-ports vertical layout with legacy speed check',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
        isHorizontalLayout: false,
        isHealthCheckSupported: true,
        uploadResult: (unit: 'M', value: '505'),
        downloadResult: (unit: 'M', value: '509'),
        speedCheckTimestamp: 1719802401000,
      ));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
        final speedCheckFinder = find.byKey(const ValueKey('speedCheck'));
        await tester.scrollUntilVisible(speedCheckFinder, 10,
            scrollable: find
                .descendant(
                    of: find.byType(StyledAppPageView),
                    matching: find.byType(Scrollable))
                .last);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);
  });

  group('Dashboard Home View with 2-ports', () {
    setUp(() {
      mockDashboardHomeNotifier = MockDashboardHomeNotifier();
      mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
      mockDeviceManagerNotifier = MockDeviceManagerNotifier();
      mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
      mockInstantTopologyNotifier = MockInstantTopologyNotifier();

      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData)
              .copyWith(lanPortConnections: ["None", "None"]));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
      when(mockDeviceManagerNotifier.build())
          .thenReturn(DeviceManagerState.fromMap(deviceManagerTestData));
      when(mockInstantPrivacyNotifier.build())
          .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
      when(mockInstantTopologyNotifier.build())
          .thenReturn(testTopology2SlavesDaisyState);
    });
    testLocalizations('Dashboard Home View - 2-ports mobile layout',
        (tester, locale) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveMobileScreens);

    testLocalizations('Dashboard Home View - 2-ports horizontal layout',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
              isHorizontalLayout: true, lanPortConnections: ["None", "None"]));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations('Dashboard Home View - 2-ports vertical layout',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
              isHorizontalLayout: false, lanPortConnections: ["None", "None"]));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations(
        'Dashboard Home View - 2-ports mobile layout with speed check',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
        lanPortConnections: ["None", "None"],
        isHealthCheckSupported: true,
      ));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
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
        'Dashboard Home View - 2-ports horizontal layout with speed check',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
              isHorizontalLayout: true,
              lanPortConnections: ["None", "None"],
              isHealthCheckSupported: true));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations(
        'Dashboard Home View - 2-ports vertical layout with speed check',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
              isHorizontalLayout: false,
              lanPortConnections: ["None", "None"],
              isHealthCheckSupported: true));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations(
        'Dashboard Home View - 2-ports horizontal layout with legacy speed check',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
        isHorizontalLayout: true,
        lanPortConnections: ["None", "None"],
        isHealthCheckSupported: true,
        uploadResult: (unit: 'M', value: '505'),
        downloadResult: (unit: 'M', value: '509'),
        speedCheckTimestamp: 1719802401000,
      ));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);
    testLocalizations(
        'Dashboard Home View - 2-ports mobile layout fw update available',
        (tester, locale) async {
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(DashboardHomeView));
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
        'Dashboard Home View - 2-ports horizontal layout fw update available',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
              isHorizontalLayout: true, lanPortConnections: ["None", "None"]));
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations(
        'Dashboard Home View - 2-ports vertical layout fw update avaliable',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateData).copyWith(
              isHorizontalLayout: false, lanPortConnections: ["None", "None"]));
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider.overrideWith((ref) => NodeWANStatus.online),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations('Dashboard Home View - 2-ports mobile layout internet offline',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeOfflineStateData).copyWith(
              isHorizontalLayout: false, lanPortConnections: ["None", "None"]));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider
                  .overrideWith((ref) => NodeWANStatus.offline),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveMobileScreens);

    testLocalizations('Dashboard Home View - 2-ports horizontal layout internet offline',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeOfflineStateData).copyWith(
        isHorizontalLayout: true,
        lanPortConnections: ["None", "None"],
      ));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider
                  .overrideWith((ref) => NodeWANStatus.offline),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);

    testLocalizations('Dashboard Home View - 2-ports vertical layout internet offline',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeOfflineStateData).copyWith(
        isHorizontalLayout: false,
        lanPortConnections: ["None", "None"],
      ));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: [
              dashboardHomeProvider
                  .overrideWith(() => mockDashboardHomeNotifier),
              firmwareUpdateProvider
                  .overrideWith(() => mockFirmwareUpdateNotifier),
              deviceManagerProvider
                  .overrideWith(() => mockDeviceManagerNotifier),
              nodeWanStatusProvider
                  .overrideWith((ref) => NodeWANStatus.offline),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
              instantTopologyProvider
                  .overrideWith(() => mockInstantTopologyNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerWhw03, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMr7500, context);
        await tester.pumpAndSettle();
      });
    }, screens: responsiveDesktopScreens);
  });
}
