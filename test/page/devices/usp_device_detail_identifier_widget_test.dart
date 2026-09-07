import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';
import 'package:privacy_gui/page/devices/views/usp_device_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_common.dart';
import '../../mocks/provider_overrides/mock_devices.dart';
import '../../mocks/test_data/scenes/devices_scene_data.dart';

/// Verifies the E2E identifier hooks added to uspDeviceDetail for
/// PrivacyGUI#1391 (unblocks PrivacyGUI-USP-E2E#86): the arrival anchor plus
/// the DHCP-reservation action, which is the one write control on this large
/// read surface.
///
/// Not tagged `ui`: gated in `run_tests.sh` (the repo's only CI test job).
void main() {
  const anchor = 'device-detail';

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'PrivacyGUI',
            'packageName': 'com.linksys.privacygui',
            'version': '0.0.0',
            'buildNumber': '0',
          };
        }
        return null;
      },
    );
  });

  Widget wrap(DeviceDetailState detail) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) =>
              const UspDeviceDetailView(mac: 'AA:BB:CC:DD:EE:01'),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...deviceDetailOverrides(detail: detail),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  group('uspDeviceDetail identifiers', () {
    testWidgets('anchor + reserve action are hooked (no reservation)',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(wifiDetailNoReservation));
      // Device cards render a continuously-loading AppImage.provider; a bounded
      // pump builds the semantics tree without waiting on the image stream.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.bySemanticsIdentifier(anchor), findsOneWidget,
          reason: 'the arrival anchor "$anchor" must be locatable');
      expect(find.bySemanticsIdentifier('device-reservation-reserve'),
          findsOneWidget,
          reason: 'the reserve action must be hooked when there is no '
              'reservation');

      handle.dispose();
    });

    testWidgets('the release action is hooked when a reservation exists',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(wifiDetailWithReservation));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.bySemanticsIdentifier(anchor), findsOneWidget);
      expect(find.bySemanticsIdentifier('device-reservation-release'),
          findsOneWidget,
          reason: 'the release action must be hooked when a reservation '
              'exists');

      handle.dispose();
    });
  });
}
