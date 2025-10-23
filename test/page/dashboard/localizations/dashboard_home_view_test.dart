import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
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

void main() async {
  late TopologyTestData topologyTestData;

  setUp(() {
    topologyTestData = TopologyTestData();
  });

  tearDown(() {
    topologyTestData.cleanup();
  });

  group('Dashboard Home View without LAN ports (Cherry7)', () {
    late TestHelper testHelper;
    setUp(() {
      testHelper = TestHelper();
      testHelper.setup();
      when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeCherry7TestState));
      when(testHelper.mockDeviceManagerNotifier.build()).thenReturn(
          DeviceManagerState.fromMap(deviceManagerCherry7TestState));
      when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    });

    tearDown(() {
      topologyTestData.cleanup();
    });

    testLocalizations('Dashboard Home View - no LAN ports',
        (tester, locale) async {
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        config: LinksysRouteConfig(column: ColumnGrid(column: 12)),
        locale: locale,
      );
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
      );
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
      );
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
      );
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
      );

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
      when(testHelper.mockNodeLightSettingsNotifier.build()).thenReturn(
          NodeLightSettings(
              isNightModeEnable: true, startHour: 20, endHour: 8));
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
      );
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
      );
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

  group('Dashboard Home View Vertical Ports (Pinnacle)', () {
    late TestHelper testHelper;
    setUp(() {
      testHelper = TestHelper();
      testHelper.setup();
    });
    tearDown(() {
      topologyTestData.cleanup();
    });

    testLocalizations('Dashboard Home View - Vertical Ports',
        (tester, locale) async {
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        config: LinksysRouteConfig(column: ColumnGrid(column: 12)),
        locale: locale,
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      when(testHelper.mockServiceHelper.isSupportHealthCheck())
          .thenReturn(false);
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      when(testHelper.mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckStateSuccessGood));
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
        'Dashboard Home View - Vertical Ports with speed check - init',
        (tester, locale) async {
      when(testHelper.mockHealthCheckProvider.build())
          .thenReturn(HealthCheckState.fromJson(healthCheckInitState));
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      when(testHelper.mockNodeLightSettingsNotifier.build()).thenReturn(
          NodeLightSettings(
              isNightModeEnable: true, startHour: 20, endHour: 8));
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
        await testHelper.pumpShellView(
          tester,
          child: const DashboardHomeView(),
          locale: locale,
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
          overrides: [
            internetStatusProvider
                .overrideWith((ref) => InternetStatus.offline),
          ]);
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      when(testHelper.mockServiceHelper.isSupportVPN()).thenReturn(true);
      when(testHelper.mockVPNNotifier.build())
          .thenReturn(VPNTestState.defaultState);
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
      when(testHelper.mockServiceHelper.isSupportVPN()).thenReturn(true);

      when(testHelper.mockVPNNotifier.build())
          .thenReturn(VPNTestState.disconnectedState);
      await testHelper.pumpShellView(
        tester,
        child: const DashboardHomeView(),
        locale: locale,
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
