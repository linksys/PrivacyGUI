import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_verify_view.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/_index.dart';
import '../../../../test_data/instant_verify_test_state.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });
  testLocalizations(
    'Instant-Verify view - Instant-Topology',
    (tester, locale) async {
      await testHelper.pumpShellView(
        tester,
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          internetStatusProvider.overrideWith((ref) => InternetStatus.online),
        ],
      );
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
      await testHelper.pumpShellView(
        tester,
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          internetStatusProvider.overrideWith((ref) => InternetStatus.online),
        ],
      );
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
    await tester.runAsync(() async {
      await testHelper.pumpShellView(
        tester,
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          internetStatusProvider.overrideWith((ref) => InternetStatus.online),
        ],
      );
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
    when(testHelper.mockInstantVerifyNotifier.build()).thenReturn(testState);
    await tester.runAsync(() async {
      await testHelper.pumpShellView(
        tester,
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          internetStatusProvider.overrideWith((ref) => InternetStatus.online),
        ],
      );
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
    when(testHelper.mockInstantVerifyNotifier.build()).thenReturn(testState);
    await tester.runAsync(() async {
      await testHelper.pumpShellView(
        tester,
        child: const InstantVerifyView(),
        locale: locale,
        overrides: [
          internetStatusProvider.overrideWith((ref) => InternetStatus.online),
        ],
      );
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
      when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      await tester.runAsync(() async {
        await testHelper.pumpShellView(
          tester,
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            internetStatusProvider.overrideWith((ref) => InternetStatus.online),
          ],
        );
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
      when(testHelper.mockInstantVerifyNotifier.build()).thenReturn(testState);
      when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
              .copyWith(wanPortConnection: () => 'None'));
      await tester.runAsync(() async {
        await testHelper.pumpShellView(
          tester,
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            internetStatusProvider.overrideWith((ref) => InternetStatus.online),
          ],
        );
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
      when(testHelper.mockInstantVerifyNotifier.build()).thenReturn(testState);

      await tester.runAsync(() async {
        await testHelper.pumpShellView(
          tester,
          child: const InstantVerifyView(),
          locale: locale,
          overrides: [
            internetStatusProvider.overrideWith((ref) => InternetStatus.online),
          ],
        );
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
