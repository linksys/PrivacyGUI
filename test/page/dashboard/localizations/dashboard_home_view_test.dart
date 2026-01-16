import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/data/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/data/providers/node_internet_status_provider.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/home_title.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/port_and_speed.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/fixed_layout/wifi_grid.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../../../common/config.dart';
import '../../../common/screen.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/_index.dart';

// View ID: DHOME
// Implementation: lib/page/dashboard/views/dashboard_home_view.dart
// Summary:
// - DHOME-NOLAN_BASE: Base layout without LAN ports.
// - DHOME-NOLAN_SIGNAL: Mesh signals scenario.
// - DHOME-NOLAN_CHILD_OFFLINE: Child node offline.
// - DHOME-NOLAN_SPEED: Speed test widget.
// - DHOME-NOLAN_FW: Firmware update banner.
// - DHOME-NOLAN_NIGHT: Night mode toggle.
// - DHOME-NOLAN_PRIVACY: Instant Privacy enabled.
// - DHOME-VERT_BASE: Vertical ports default layout.
// - DHOME-VERT_SPEED: Speed test success.
// - DHOME-VERT_SPEED_INIT: Speed test init state.
// - DHOME-VERT_FW: Firmware update notice.
// - DHOME-VERT_PRIVACY_ON/OFF: Privacy modal toggles.
// - DHOME-VERT_SHARE_WIFI: Share Wi-Fi modal.
// - DHOME-VERT_OFFLINE: Offline WAN indicator.
// - DHOME-VERT_QR: Hover QR tooltip.
// - DHOME-VERT_VPN: VPN connected/disconnected.

final List<ScreenSize> _noLanScreens = [
  ...responsiveMobileScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 2480),
  ),
  ...responsiveDesktopScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 1280),
  ),
];

final List<ScreenSize> _verticalScreens = [
  ...responsiveMobileScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 2480),
  ),
  ...responsiveDesktopScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 1280),
  ),
];

void main() {
  final testHelper = TestHelper();
  late TopologyTestData topologyTestData;

  setUp(() {
    testHelper.setup();
    topologyTestData = TopologyTestData();
  });

  tearDown(() {
    topologyTestData.cleanup();
  });

  Future<BuildContext> pumpDashboard(
    WidgetTester tester,
    LocalizedScreen screen, {
    LinksysRouteConfig? config,
    List<Override> overrides = const [],
  }) async {
    final context = await testHelper.pumpShellView(
      tester,
      child: const DashboardHomeView(),
      locale: screen.locale,
      config: config ?? LinksysRouteConfig(column: ColumnGrid(column: 12)),
      overrides: overrides,
    );
    await tester.runAsync(() async {
      // TODO
      await precacheImage(
        Assets.images.devices.routerLn12.provider(),
        context,
      );
    });
    await tester.pumpAndSettle();
    return context;
  }

  Future<void> scrollToQuickPanel(WidgetTester tester) async {
    final panel = find.byType(FixedDashboardQuickPanel).first;
    await tester.ensureVisible(panel);
    await tester.pumpAndSettle();
  }

  Future<void> scrollToWifiGrid(WidgetTester tester) async {
    final grid = find.byType(FixedDashboardWiFiGrid).first;
    await tester.ensureVisible(grid);
    await tester.pumpAndSettle();
  }

  Future<void> toggleInstantPrivacy(WidgetTester tester) async {
    await scrollToQuickPanel(tester);
    final quickPanel = find.byType(FixedDashboardQuickPanel).first;
    final privacySwitch = find.descendant(
      of: quickPanel,
      matching: find.byType(AppSwitch),
    );
    await tester.tap(privacySwitch.first);
    await tester.pumpAndSettle();
  }

  // Test ID: DHOME-NOLAN_BASE
  testLocalizations(
    'dashboard home view - no lan ports base layout',
    (tester, screen) async {
      final context = await pumpDashboard(tester, screen);
      final loc = testHelper.loc(context);

      expect(find.byType(DashboardHomeTitle), findsOneWidget);
      expect(find.text(loc.internetOnline), findsOneWidget);
      expect(find.byType(FixedDashboardQuickPanel), findsOneWidget);
      expect(find.byType(FixedDashboardWiFiGrid), findsOneWidget);
    },
    screens: _noLanScreens,
    goldenFilename: 'DHOME-NOLAN_BASE_01_layout',
    helper: testHelper,
  );

  // Test ID: DHOME-NOLAN_SIGNAL
  testLocalizations(
    'dashboard home view - mesh signal indicators',
    (tester, screen) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(topologyTestData.testTopologySingalsSlaveState);

      await pumpDashboard(tester, screen);
      expect(find.byType(FixedDashboardNetworks), findsOneWidget);
    },
    screens: _noLanScreens,
    goldenFilename: 'DHOME-NOLAN_SIGNAL_01_signals',
    helper: testHelper,
  );

  // Test ID: DHOME-NOLAN_CHILD_OFFLINE
  testLocalizations(
    'dashboard home view - child node offline warning',
    (tester, screen) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(topologyTestData.testTopology3OfflineState);
      await pumpDashboard(tester, screen);
      expect(find.byIcon(AppFontIcons.infoCircle), findsWidgets);
    },
    screens: _noLanScreens,
    goldenFilename: 'DHOME-NOLAN_CHILD_OFFLINE_01_offline',
    helper: testHelper,
  );

  // Test ID: DHOME-NOLAN_SPEED
  testLocalizations(
    'dashboard home view - display speed test results',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
        HealthCheckState.fromJson(healthCheckStateSuccessGood),
      );
      final context = await pumpDashboard(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.connectedSpeed), findsOneWidget);
    },
    screens: _noLanScreens,
    goldenFilename: 'DHOME-NOLAN_SPEED_01_speedtest',
    helper: testHelper,
  );

  // Test ID: DHOME-NOLAN_FW
  testLocalizations(
    'dashboard home view - firmware update available banner',
    (tester, screen) async {
      when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwarePinnacleTestState),
      );
      when(testHelper.mockInstantTopologyNotifier.build()).thenReturn(
        topologyTestData.testTopology2SlavesDaisyAndFwUpdateState,
      );

      final context = await pumpDashboard(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.updateFirmware), findsOneWidget);
    },
    screens: _noLanScreens,
    goldenFilename: 'DHOME-NOLAN_FW_01_banner',
    helper: testHelper,
  );

  // Test ID: DHOME-NOLAN_NIGHT
  testLocalizations(
    'dashboard home view - node night mode enabled',
    (tester, screen) async {
      when(testHelper.mockNodeLightSettingsNotifier.build()).thenReturn(
        NodeLightSettings(isNightModeEnable: true, startHour: 20, endHour: 8),
      );

      final context = await pumpDashboard(tester, screen);
      final loc = testHelper.loc(context);
      await scrollToQuickPanel(tester);
      expect(find.text(loc.nightMode), findsOneWidget);
    },
    screens: _noLanScreens,
    goldenFilename: 'DHOME-NOLAN_NIGHT_01_quickpanel',
    helper: testHelper,
  );

  // Test ID: DHOME-NOLAN_PRIVACY
  testLocalizations(
    'dashboard home view - instant privacy enabled',
    (tester, screen) async {
      when(testHelper.mockInstantPrivacyNotifier.build()).thenReturn(
        InstantPrivacyState.fromMap(instantPrivacyEnabledTestState),
      );

      final context = await pumpDashboard(tester, screen);
      final loc = testHelper.loc(context);
      await scrollToQuickPanel(tester);
      expect(find.text(loc.instantPrivacy), findsWidgets);
    },
    screens: _noLanScreens,
    goldenFilename: 'DHOME-NOLAN_PRIVACY_01_enabled',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_BASE
  testLocalizations(
    'dashboard home view - vertical ports layout',
    (tester, screen) async {
      await pumpDashboard(tester, screen);
      expect(find.byType(DashboardHomeTitle), findsOneWidget);
      expect(find.byType(FixedDashboardWiFiGrid), findsOneWidget);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_BASE_01_layout',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_SPEED
  testLocalizations(
    'dashboard home view - vertical speed test success',
    (tester, screen) async {
      when(testHelper.mockServiceHelper.isSupportHealthCheck())
          .thenReturn(true);

      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
        HealthCheckState.fromJson(healthCheckStateSuccessGood),
      );

      final context = await pumpDashboard(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.connectedSpeed), findsWidgets);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_SPEED_01_widget',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_SPEED_INIT
  testLocalizations(
    'dashboard home view - vertical speed test init state',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
        HealthCheckState.fromJson(healthCheckStateSuccessGood).copyWith(
          healthCheckModules: ['SpeedTest'],
        ),
      );
      await pumpDashboard(tester, screen);
      expect(find.byType(FixedDashboardHomePortAndSpeed), findsOneWidget);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_SPEED_INIT_01_init',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_FW
  testLocalizations(
    'dashboard home view - vertical firmware update',
    (tester, screen) async {
      when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwarePinnacleTestState),
      );
      when(testHelper.mockInstantTopologyNotifier.build()).thenReturn(
        topologyTestData.testTopology2SlavesDaisyAndFwUpdateState,
      );

      final context = await pumpDashboard(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.updateFirmware), findsWidgets);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_FW_01_banner',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_PRIVACY_ON
  testLocalizations(
    'dashboard home view - instant privacy enable modal',
    (tester, screen) async {
      await pumpDashboard(tester, screen);
      await toggleInstantPrivacy(tester);
      expect(find.byType(AppDialog), findsOneWidget);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_PRIVACY_ON_01_dialog',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_PRIVACY_OFF
  testLocalizations(
    'dashboard home view - instant privacy disable modal',
    (tester, screen) async {
      when(testHelper.mockInstantPrivacyNotifier.build()).thenReturn(
        InstantPrivacyState.fromMap(instantPrivacyEnabledTestState),
      );
      await pumpDashboard(tester, screen);
      await toggleInstantPrivacy(tester);
      expect(find.byType(AppDialog), findsOneWidget);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_PRIVACY_OFF_01_dialog',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_SHARE_WIFI
  testLocalizations(
    'dashboard home view - share wifi modal',
    (tester, screen) async {
      await pumpDashboard(tester, screen);
      await scrollToWifiGrid(tester);
      final wifiGrid = find.byType(FixedDashboardWiFiGrid).first;
      final shareButton = find.descendant(
        of: wifiGrid,
        matching: find.byType(AppIconButton),
      );
      await tester.tap(shareButton.first);
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_SHARE_WIFI_01_modal',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_OFFLINE
  testLocalizations(
    'dashboard home view - offline wan message',
    (tester, screen) async {
      when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
        DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
            .copyWith(wanPortConnection: () => 'None'),
      );
      when(testHelper.mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState)
            .copyWith(wanConnection: 'None'),
      );

      final context = await pumpDashboard(
        tester,
        screen,
        overrides: [
          internetStatusProvider.overrideWith((ref) => InternetStatus.offline),
        ],
      );
      final loc = testHelper.loc(context);
      expect(find.text(loc.internetOffline), findsOneWidget);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_OFFLINE_01_banner',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_QR
  testLocalizations(
    'dashboard home view - qr hover tooltip',
    (tester, screen) async {
      when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwarePinnacleTestState),
      );
      when(testHelper.mockInstantTopologyNotifier.build()).thenReturn(
        topologyTestData.testTopology2SlavesDaisyAndFwUpdateState,
      );

      await pumpDashboard(tester, screen);
      await scrollToWifiGrid(tester);
      expect(find.byType(QrImageView), findsNothing);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(
        find.byIcon(AppFontIcons.qrCode).first,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsWidgets);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_QR_01_hover',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_VPN_CONNECTED
  testLocalizations(
    'dashboard home view - vpn connected state',
    (tester, screen) async {
      when(testHelper.mockServiceHelper.isSupportVPN()).thenReturn(true);
      when(testHelper.mockVPNNotifier.build())
          .thenReturn(VPNTestState.defaultState);

      final context = await pumpDashboard(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.vpn), findsWidgets);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_VPN_CONNECTED_01_card',
    helper: testHelper,
  );

  // Test ID: DHOME-VERT_VPN_DISCONNECTED
  testLocalizations(
    'dashboard home view - vpn disconnected state',
    (tester, screen) async {
      when(testHelper.mockServiceHelper.isSupportVPN()).thenReturn(true);
      when(testHelper.mockVPNNotifier.build())
          .thenReturn(VPNTestState.disconnectedState);

      final context = await pumpDashboard(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.vpn), findsWidgets);
    },
    screens: _verticalScreens,
    goldenFilename: 'DHOME-VERT_VPN_DISCONNECTED_01_card',
    helper: testHelper,
  );
}
