import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/switch/switch.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/_index.dart';
import '../../../test_data/geolocation_test_state.dart';
import '../../../test_data/vpn_test_state.dart';

void main() async {
  late DashboardHomeNotifier mockDashboardHomeNotifier;
  late DashboardManagerNotifier mockDashboardManagerNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late DeviceManagerNotifier mockDeviceManagerNotifier;
  late InstantPrivacyNotifier mockInstantPrivacyNotifier;
  late InstantTopologyNotifier mockInstantTopologyNotifier;
  late GeolocationNotifier mockGeolocationNotifer;
  late NodeLightSettingsNotifier mockNodeLightSettingsNotifier;
  late PollingNotifier mockPollingNotifier;
  late VPNNotifier mockVPNNotifier;
  late HealthCheckProvider mockHealthCheckProvider;

  late TopologyTestData topologyTestData;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  List<Override> overrideRegister({
    bool withHealthCheck = false,
    bool withNodeLightSettings = false,
    bool withVpn = false,
    InternetStatus internetStatus = InternetStatus.online,
  }) {
    final overrides = [
      dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
      dashboardManagerProvider.overrideWith(() => mockDashboardManagerNotifier),
      firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
      internetStatusProvider.overrideWith((ref) => internetStatus),
      instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
      instantTopologyProvider.overrideWith(() => mockInstantTopologyNotifier),
      geolocationProvider.overrideWith(() => mockGeolocationNotifer),
      pollingProvider.overrideWith(() => mockPollingNotifier),
    ];

    if (withHealthCheck) {
      overrides
          .add(healthCheckProvider.overrideWith(() => mockHealthCheckProvider));
    }
    if (withNodeLightSettings) {
      overrides.add(nodeLightSettingsProvider
          .overrideWith(() => mockNodeLightSettingsNotifier));
    }
    if (withVpn) {
      overrides.add(vpnProvider.overrideWith(() => mockVPNNotifier));
    }
    return overrides;
  }

  setUp(() {
    topologyTestData = TopologyTestData();
  });

  tearDown(() {
    topologyTestData.cleanup();
  });

  group('Dashboard Home View without LAN ports (Cherry7)', () {
    late TestHelper testHelper;
    setUp(() {
      mockDashboardHomeNotifier = MockDashboardHomeNotifier();
      mockDashboardManagerNotifier = MockDashboardManagerNotifier();
      mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
      mockDeviceManagerNotifier = MockDeviceManagerNotifier();
      mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
      mockInstantTopologyNotifier = MockInstantTopologyNotifier();
      mockGeolocationNotifer = MockGeolocationNotifier();
      mockNodeLightSettingsNotifier = MockNodeLightSettingsNotifier();
      mockPollingNotifier = MockPollingNotifier();
      mockHealthCheckProvider = MockHealthCheckProvider();

      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeCherry7TestState));
      when(testHelper.mockDeviceManagerNotifier.build()).thenReturn(
          DeviceManagerState.fromMap(deviceManagerCherry7TestState));
      when(mockInstantPrivacyNotifier.build())
          .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
      when(mockInstantTopologyNotifier.build())
          .thenReturn(topologyTestData.testTopology2SlavesDaisyState);
      when(mockGeolocationNotifer.build()).thenAnswer(
          (_) async => GeolocationState.fromMap(geolocationTestState));
      when(mockNodeLightSettingsNotifier.build())
          .thenReturn(NodeLightSettings(isNightModeEnable: false));
      when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
      when(mockPollingNotifier.build()).thenReturn(
          CoreTransactionData(lastUpdate: 0, isReady: true, data: {}));
      when(mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckInitState));
    });

    tearDown(() {
      testHelper.tearDown();
      topologyTestData.cleanup();
    });

    testLocalizations('Dashboard Home View - no LAN ports',
        (tester, locale) async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withHealthCheck: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - no LAN ports - signals',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(topologyTestData.testTopologySingalsSlaveState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withHealthCheck: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - no LAN ports - child node offline',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(topologyTestData.testTopology3OfflineState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - no LAN ports with speed check',
        (tester, locale) async {
      when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeCherry7TestState).copyWith(
        isHealthCheckSupported: true,
        uploadResult: () => DashboardSpeedItem(unit: 'M', value: '505'),
        downloadResult: () => DashboardSpeedItem(unit: 'M', value: '509'),
        speedCheckTimestamp: () => 1719802401000,
      ));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - no LAN ports fw update avaliable',
        (tester, locale) async {
      when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(
              firmwareUpdateHasFirmwareCherry7TestState));
      when(testHelper.mockInstantTopologyNotifier.build()).thenReturn(
          topologyTestData.testTopology2SlavesDaisyAndFwUpdateState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - no LAN ports night mode enable',
        (tester, locale) async {
      when(mockNodeLightSettingsNotifier.build()).thenReturn(NodeLightSettings(
          isNightModeEnable: true, startHour: 20, endHour: 8));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
        'Dashboard Home View - no LAN ports Instant-Privacy enabled',
        (tester, locale) async {
      when(testHelper.mockInstantPrivacyNotifier.build()).thenReturn(
          InstantPrivacyState.fromMap(instantPrivacyEnabledTestState));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
        'Dashboard Home View - no LAN ports Instant-Privacy toogle enable modal',
        (tester, locale) async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });

      final quickPanelFinder = find.byType(DashboardQuickPanel).first;
      final instantPrivacySwitchFinder = find.descendant(
          of: quickPanelFinder,
          matching: find.byType(AppSwitch),
          skipOffstage: true);
      await tester.tap(instantPrivacySwitchFinder.first);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
        'Dashboard Home View - no LAN ports Instant-Privacy toogle disable modal',
        (tester, locale) async {
      when(mockInstantPrivacyNotifier.build()).thenReturn(
          InstantPrivacyState.fromMap(instantPrivacyEnabledTestState));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });

      final quickPanelFinder = find.byType(DashboardQuickPanel).first;
      final instantPrivacySwitchFinder = find.descendant(
          of: quickPanelFinder,
          matching: find.byType(AppSwitch),
          skipOffstage: false);
      await tester.tap(instantPrivacySwitchFinder.first);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
      'Dashboard Home View - no LAN ports Share WiFi modal',
      (tester, locale) async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: overrideRegister(withNodeLightSettings: true),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final context = tester.element(find.byType(DashboardHomeView));
          await precacheImage(
              CustomTheme.of(context).images.devices.routerLn12, context);
          await tester.pumpAndSettle();
        });

        final wifiGridFinder = find.byType(DashboardWiFiGrid).first;
        final shareWiFiFinder = find.descendant(
            of: wifiGridFinder,
            matching: find.byType(AppIconButton),
            skipOffstage: false);
        await tester.tap(shareWiFiFinder.first);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 2480))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations('Dashboard Home View - no LAN ports offline status',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
              .copyWith(wanPortConnection: () => 'None'));
      when(mockDashboardManagerNotifier.build()).thenReturn(
          DashboardManagerState.fromMap(dashboardManagerChrry7TestState)
              .copyWith(wanConnection: 'None'));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(
              withNodeLightSettings: true,
              internetStatus: InternetStatus.offline),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - no LAN ports bridge mode',
        (tester, locale) async {
      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
              .copyWith(wanType: () => 'Bridge'));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - hover qr code',
        (tester, locale) async {
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(
              firmwareUpdateHasFirmwareCherry7TestState));
      when(mockInstantTopologyNotifier.build()).thenReturn(
          topologyTestData.testTopology2SlavesDaisyAndFwUpdateState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();

        // Simulate hover enter.
        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(
            location: Offset.zero); // Add pointer at the top-left corner
        addTearDown(gesture.removePointer);
        await gesture
            .moveTo(tester.getCenter(find.byIcon(LinksysIcons.qrCode).first));
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);
  });

  group('Dashboard Home View Vertical Ports (Pinnacle)', () {
    late TestHelper testHelper;
    setUp(() {
      mockDashboardHomeNotifier = MockDashboardHomeNotifier();
      mockDashboardManagerNotifier = MockDashboardManagerNotifier();
      mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
      mockDeviceManagerNotifier = MockDeviceManagerNotifier();
      mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
      mockInstantTopologyNotifier = MockInstantTopologyNotifier();
      mockGeolocationNotifer = MockGeolocationNotifier();
      mockNodeLightSettingsNotifier = MockNodeLightSettingsNotifier();
      mockVPNNotifier = MockVPNNotifier();
      mockPollingNotifier = MockPollingNotifier();
      mockHealthCheckProvider = MockHealthCheckProvider();

      when(mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomePinnacleTestState));
      when(mockDashboardManagerNotifier.build()).thenReturn(
          DashboardManagerState.fromMap(dashboardManagerPinnacleTestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
      when(mockDeviceManagerNotifier.build()).thenReturn(
          DeviceManagerState.fromMap(deviceManagerCherry7TestState));
      when(mockInstantPrivacyNotifier.build())
          .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
      when(mockInstantTopologyNotifier.build())
          .thenReturn(topologyTestData.testTopology2SlavesDaisyState);
      when(mockGeolocationNotifer.build()).thenAnswer(
          (_) async => GeolocationState.fromMap(geolocationTestState));
      when(mockNodeLightSettingsNotifier.build())
          .thenReturn(NodeLightSettings(isNightModeEnable: false));
      when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
      when(mockServiceHelper.isSupportVPN()).thenReturn(true);
      when(mockVPNNotifier.build()).thenReturn(VPNTestState.defaultState);
      when(mockPollingNotifier.build()).thenReturn(
          CoreTransactionData(lastUpdate: 0, isReady: true, data: const {}));
      when(mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckStateSuccessGood));
    });

    tearDown(() {
      topologyTestData.cleanup();
    });

    testLocalizations('Dashboard Home View - Vertical Ports',
        (tester, locale) async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - Vertical Ports - signals',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(topologyTestData.testTopologySingalsSlaveState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
        'Dashboard Home View - Vertical Ports - child node offline',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(topologyTestData.testTopology3OfflineState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - Vertical Ports with speed check',
        (tester, locale) async {
      when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomePinnacleTestState).copyWith(
        isHealthCheckSupported: true,
        uploadResult: () => DashboardSpeedItem(unit: 'M', value: '505'),
        downloadResult: () => DashboardSpeedItem(unit: 'M', value: '509'),
        speedCheckTimestamp: () => 1719802401000,
      ));
      when(mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckStateSuccessGood));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withHealthCheck: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - Vertical Ports with speed check - init',
        (tester, locale) async {
      when(mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckInitState));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withHealthCheck: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
        'Dashboard Home View - Vertical Ports fw update avaliable',
        (tester, locale) async {
      when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(
              firmwareUpdateHasFirmwareCherry7TestState));
      when(testHelper.mockInstantTopologyNotifier.build()).thenReturn(
          topologyTestData.testTopology2SlavesDaisyAndFwUpdateState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - Vertical Ports night mode enable',
        (tester, locale) async {
      when(mockNodeLightSettingsNotifier.build()).thenReturn(NodeLightSettings(
          isNightModeEnable: true, startHour: 20, endHour: 8));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
        'Dashboard Home View - Vertical Ports Instant-Privacy enabled',
        (tester, locale) async {
      when(testHelper.mockInstantPrivacyNotifier.build()).thenReturn(
          InstantPrivacyState.fromMap(instantPrivacyEnabledTestState));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
        'Dashboard Home View - Vertical Ports Instant-Privacy toogle enable modal',
        (tester, locale) async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });

      final quickPanelFinder = find.byType(DashboardQuickPanel).first;
      final instantPrivacySwitchFinder = find.descendant(
          of: quickPanelFinder,
          matching: find.byType(AppSwitch),
          skipOffstage: true);
      await tester.tap(instantPrivacySwitchFinder.first);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
        'Dashboard Home View - Vertical Ports Instant-Privacy toogle disable modal',
        (tester, locale) async {
      when(testHelper.mockInstantPrivacyNotifier.build()).thenReturn(
          InstantPrivacyState.fromMap(instantPrivacyEnabledTestState));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });

      final quickPanelFinder = find.byType(DashboardQuickPanel).first;
      final instantPrivacySwitchFinder = find.descendant(
          of: quickPanelFinder,
          matching: find.byType(AppSwitch),
          skipOffstage: false);
      await tester.tap(instantPrivacySwitchFinder.first);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations(
      'Dashboard Home View - Vertical Ports Share WiFi modal',
      (tester, locale) async {
        await tester.pumpWidget(
          testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: overrideRegister(withNodeLightSettings: true),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final context = tester.element(find.byType(DashboardHomeView));
          await precacheImage(
              CustomTheme.of(context).images.devices.routerLn12, context);
          await tester.pumpAndSettle();
        });

        final wifiGridFinder = find.byType(DashboardWiFiGrid).first;
        final shareWiFiFinder = find.descendant(
            of: wifiGridFinder,
            matching: find.byType(AppIconButton),
            skipOffstage: false);
        await tester.tap(shareWiFiFinder.first);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 2480))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations('Dashboard Home View - Vertical Ports offline status',
        (tester, locale) async {
      when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
              .copyWith(wanPortConnection: () => 'None'));
      when(testHelper.mockDashboardManagerNotifier.build()).thenReturn(
          DashboardManagerState.fromMap(dashboardManagerChrry7TestState)
              .copyWith(wanConnection: 'None'));

      await testHelper.pumpShellView(tester,
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(
              withNodeLightSettings: true,
              internetStatus: InternetStatus.offline),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - Vertical Ports bridge mode',
        (tester, locale) async {
      when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
              .copyWith(wanType: () => 'Bridge'));
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withNodeLightSettings: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - hover qr code',
        (tester, locale) async {
      when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(
              firmwareUpdateHasFirmwareCherry7TestState));
      when(testHelper.mockInstantTopologyNotifier.build()).thenReturn(
          topologyTestData.testTopology2SlavesDaisyAndFwUpdateState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();

        // Simulate hover enter.
        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(
            location: Offset.zero); // Add pointer at the top-left corner
        addTearDown(gesture.removePointer);
        await gesture
            .moveTo(tester.getCenter(find.byIcon(LinksysIcons.qrCode).first));
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - VPN connected',
        (tester, locale) async {
      when(mockVPNNotifier.build()).thenReturn(VPNTestState.defaultState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withVpn: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Dashboard Home View - VPN disconnected',
        (tester, locale) async {
      when(mockVPNNotifier.build()).thenReturn(VPNTestState.disconnectedState);
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const DashboardHomeView(),
          locale: locale,
          overrides: overrideRegister(withVpn: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(DashboardHomeView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 2480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);
  });
}
