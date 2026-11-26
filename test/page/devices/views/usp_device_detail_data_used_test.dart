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
import 'package:ui_kit_library/ui_kit.dart' show AppTooltip;

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_devices.dart';
import '../../../mocks/test_data/devices_test_data.dart';

/// The Download and Upload rows on the device detail page's connection card
/// (#1927): the bytes a device exchanged through the router, from its Hosts
/// rows' WANStats, added up over every interface it is shown with.
void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async => methodCall.method == 'getAll'
          ? <String, dynamic>{
              'appName': 'PrivacyGUI',
              'packageName': 'com.linksys.privacygui',
              'version': '0.0.0',
              'buildNumber': '0',
            }
          : null,
    );
  });

  Future<void> pump(WidgetTester tester, DeviceDetailState detail) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) =>
              UspDeviceDetailView(mac: detail.device!.mac),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...deviceDetailOverrides(detail: detail),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: router,
      ),
    ));
    // The device icon keeps loading, so pumpAndSettle never settles.
    await tester.pump(const Duration(milliseconds: 300));
  }

  final l10n = lookupAppLocalizations(const Locale('en'));

  // The wired Mac's counters on the bench, 2026-11-24 14:34
  // (2.0.4.26112201): 114924318 B is 109.6 MiB, 9985679 B is 9.52 MiB.
  testWidgets('shows a device\'s Download and Upload totals', (tester) async {
    await pump(
      tester,
      DeviceDetailState(
        device: DevicesTestData.createWiredClient().copyWith(
          bytesReceived: 114924318,
          bytesSent: 9985679,
        ),
      ),
    );

    expect(find.text(l10n.download), findsOneWidget);
    expect(find.text('110 MB'), findsOneWidget);
    expect(find.text(l10n.upload), findsOneWidget);
    expect(find.text('9.5 MB'), findsOneWidget);
    expect(find.text(l10n.sinceRouterLastRestarted), findsOneWidget);
  });

  // No counter is not 0 B: a row the router has no WANStats for shows
  // nothing, rather than a total it does not know.
  testWidgets('has no Download or Upload row for a device with no counter',
      (tester) async {
    await pump(
      tester,
      DeviceDetailState(device: DevicesTestData.createWiredClient()),
    );

    expect(find.text(l10n.download), findsNothing);
    expect(find.text(l10n.upload), findsNothing);
    expect(find.text(l10n.sinceRouterLastRestarted), findsNothing);
  });

  // A device on a cable and on Wi-Fi is two Hosts rows with a counter each
  // (#1719); the card shows one total under its interface list.
  testWidgets('shows a multi-interface device\'s totals over every interface',
      (tester) async {
    await pump(
      tester,
      DeviceDetailState(
        device: DevicesTestData.createMultiInterfaceClient(
          additionalInterfaces: [
            DevicesTestData.createWiredInterface(
              mac: 'AA:BB:CC:DD:EE:FE',
              ip: '192.168.1.204',
              bytesReceived: 2097152,
              bytesSent: 524288,
            ),
          ],
        ).copyWith(bytesReceived: 3145728, bytesSent: 524288),
      ),
    );

    // 3 MiB + 2 MiB received, 0.5 MiB + 0.5 MiB sent.
    expect(find.text('5.0 MB'), findsOneWidget);
    expect(find.text('1.0 MB'), findsOneWidget);
    expect(find.text(l10n.sinceRouterLastRestarted), findsOneWidget);
  });

  // Each interface's own counters, behind an (i) so the card keeps one total.
  group('per-interface usage behind (i)', () {
    DeviceDetailState merged({int? wiredReceived = 2097152}) =>
        DeviceDetailState(
          device: DevicesTestData.createMultiInterfaceClient(
            additionalInterfaces: [
              DevicesTestData.createWiredInterface(
                mac: 'AA:BB:CC:DD:EE:FE',
                ip: '192.168.1.204',
                bytesReceived: wiredReceived,
                bytesSent: 524288,
              ),
            ],
          ).copyWith(bytesReceived: 3145728, bytesSent: 524288),
        );

    Future<void> openInfo(WidgetTester tester) async {
      await tester.tap(find.descendant(
        of: find.byType(AppTooltip),
        matching: find.byIcon(Icons.info_outline),
      ));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('lists each interface\'s own Download and Upload',
        (tester) async {
      await pump(tester, merged());

      // 3 MiB on the Wi-Fi row, 2 MiB on the cable's, 512 KiB sent on each.
      expect(find.text('3.0 MB'), findsNothing, reason: 'closed until tapped');
      await openInfo(tester);

      expect(find.text('3.0 MB'), findsOneWidget);
      expect(find.text('2.0 MB'), findsOneWidget);
      expect(find.text('512 KB'), findsNWidgets(2));
    });

    testWidgets('an interface with no counter reads a dash', (tester) async {
      await pump(tester, merged(wiredReceived: null));
      await openInfo(tester);

      // The cable's Download has no counter; both Uploads still read.
      expect(find.text('—'), findsOneWidget);
      expect(find.text('512 KB'), findsNWidgets(2));
    });

    testWidgets('a single-interface device has no (i)', (tester) async {
      await pump(
        tester,
        DeviceDetailState(
          device: DevicesTestData.createWiredClient()
              .copyWith(bytesReceived: 3145728, bytesSent: 524288),
        ),
      );

      expect(find.text(l10n.download), findsOneWidget);
      expect(find.byType(AppTooltip), findsNothing);
    });
  });
}
