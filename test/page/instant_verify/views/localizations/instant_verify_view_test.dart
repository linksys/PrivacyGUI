import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:privacy_gui/page/instant_topology/views/instant_topology_view.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';
import 'package:privacy_gui/page/instant_verify/views/components/ping_network_modal.dart';
import 'package:privacy_gui/page/instant_verify/views/components/traceroute_modal.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_verify_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/config.dart';
import '../../../../common/screen.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/health_check_state_data.dart';
import '../../../../test_data/instant_verify_test_state.dart';

// View ID: IVER
// Implementation: lib/page/instant_verify/views/instant_verify_view.dart
// Summary:
// - IVER-INFO: Base Instant Info tab with device/connection/speed cards.
// - IVER-TOPOLOGY: Tab switch to topology view with tree layout.
// - IVER-MULTI_DNS: Connectivity card display when multiple DNS entries exist.
// - IVER-SPEEDTEST: Internal health-check speed test widget rendered.
// - IVER-SPEEDTEST_INIT: Modules configured but idle still show speed test panel.
// - IVER-PING: Ping tile launches ping modal via PageBottomBar.
// - IVER-TRACEROUTE: Traceroute tile launches traceroute modal.

final _infoScreens = [
  ...responsiveDesktopScreens.map((s) => s.copyWith(height: 1280)),
  ...responsiveMobileScreens.map((s) => s.copyWith(height: 2880)),
];

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  Future<BuildContext> pumpInstantVerify(
    WidgetTester tester,
    LocalizedScreen screen, {
    InstantVerifyState? state,
  }) async {
    when(testHelper.mockInstantVerifyNotifier.build()).thenReturn(
      state ?? InstantVerifyState.fromMap(instantVerifyTestState),
    );
    final context = await testHelper.pumpShellView(
      tester,
      child: const InstantVerifyView(),
      locale: screen.locale,
      overrides: [
        internetStatusProvider.overrideWith((ref) => InternetStatus.online),
      ],
    );
    await tester.runAsync(() async {
      final element = tester.element(find.byType(InstantVerifyView));
      final images = [
        Assets.images.devices.routerMx6200.provider(),
        Assets.images.devices.routerWhw03.provider(),
        Assets.images.devices.routerMr7500.provider(),
        Assets.images.speedtestPowered.provider(),
      ];
      for (final image in images) {
        await precacheImage(image, element);
      }
    });
    await tester.pumpAndSettle();
    return context;
  }

  // Test ID: IVER-INFO — validate base Instant Info tab layout
  testLocalizationsV2(
    'instant verify view - instant info layout',
    (tester, screen) async {
      final context = await pumpInstantVerify(tester, screen);
      final loc = testHelper.loc(context);

      expect(find.text(loc.instantVerify), findsOneWidget);
      expect(find.text(loc.deviceInfo), findsOneWidget);
      expect(find.byKey(const ValueKey('connectivityCard')), findsOneWidget);
      expect(find.byKey(const ValueKey('speedTestCard')), findsOneWidget);
    },
    screens: _infoScreens,
    goldenFilename: 'IVER-INFO_01_layout',
    helper: testHelper,
  );

  // Test ID: IVER-TOPOLOGY — switch tab renders InstantTopologyView
  testLocalizationsV2(
    'instant verify view - instant topology tab',
    (tester, screen) async {
      final context = await pumpInstantVerify(tester, screen);
      final loc = testHelper.loc(context);

      await tester.tap(find.text(loc.instantTopology));
      await tester.pumpAndSettle();
      expect(find.byType(InstantTopologyView), findsOneWidget);
    },
    screens: _infoScreens,
    goldenFilename: 'IVER-TOPOLOGY_01_tab',
    helper: testHelper,
  );

  // Test ID: IVER-MULTI_DNS — connectivity card with multiple DNS servers
  testLocalizationsV2(
    'instant verify view - connectivity multi dns',
    (tester, screen) async {
      final context = await pumpInstantVerify(
        tester,
        screen,
        state: InstantVerifyState.fromMap(instantVerifyMultiDNSTestState),
      );
      final loc = testHelper.loc(context);

      expect(find.text(loc.nDNS(3)), findsOneWidget);
      expect(
        find.textContaining(' | '),
        findsWidgets,
      );
    },
    screens: _infoScreens,
    goldenFilename: 'IVER-MULTI_DNS_01_card',
    helper: testHelper,
  );

  // Test ID: IVER-SPEEDTEST — internal health-check speed test widget
  testLocalizationsV2(
    'instant verify view - internal speed test widget',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
        HealthCheckState.fromJson(healthCheckStateWithModulesSuccessOkay),
      );
      await pumpInstantVerify(tester, screen);
      expect(find.byKey(const ValueKey('speedTestCard')), findsOneWidget);
      expect(find.byType(SpeedTestWidget), findsOneWidget);
    },
    screens: _infoScreens,
    goldenFilename: 'IVER-SPEEDTEST_01_card',
    helper: testHelper,
  );

  // Test ID: IVER-SPEEDTEST_INIT — idle modules still show speed test card
  testLocalizationsV2(
    'instant verify view - speed test modules idle state',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
        HealthCheckState.fromJson(healthCheckInitStateWithModules),
      );
      await pumpInstantVerify(tester, screen);
      expect(find.byKey(const ValueKey('speedTestCard')), findsOneWidget);
    },
    screens: _infoScreens,
    goldenFilename: 'IVER-SPEEDTEST_INIT_01_card',
    helper: testHelper,
  );

  // Test ID: IVER-PING — tapping ping card opens modal
  testLocalizationsV2(
    'instant verify view - ping dialog',
    (tester, screen) async {
      await pumpInstantVerify(tester, screen);

      await tester.tap(find.byKey(const ValueKey('ping')));
      await tester.pumpAndSettle();
      expect(find.byType(PingNetworkModal), findsOneWidget);
    },
    screens: _infoScreens,
    goldenFilename: 'IVER-PING_01_dialog',
    helper: testHelper,
  );

  // Test ID: IVER-TRACEROUTE — tapping traceroute card opens modal
  testLocalizationsV2(
    'instant verify view - traceroute dialog',
    (tester, screen) async {
      await pumpInstantVerify(tester, screen);

      await tester.tap(find.byKey(const ValueKey('traceroute')));
      await tester.pumpAndSettle();
      expect(find.byType(TracerouteModal), findsOneWidget);
    },
    screens: _infoScreens,
    goldenFilename: 'IVER-TRACEROUTE_01_dialog',
    helper: testHelper,
  );
}
