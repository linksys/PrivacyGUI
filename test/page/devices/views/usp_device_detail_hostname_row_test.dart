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

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_devices.dart';
import '../../../mocks/test_data/devices_test_data.dart';

/// The device detail page's Hostname row (#1686 item 3, FWDEV#201 request 5).
///
/// It used to show only when the host name differed from the display name.
/// With no friendly name the display name *is* the host name, so the row
/// vanished exactly when the host name was the only name the device had.
/// Firmware asks for it whenever `HostName` is non-empty.
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

  final hostnameLabel = lookupAppLocalizations(const Locale('en')).hostname;

  testWidgets('shows the host name when it is also the display name',
      (tester) async {
    await pump(
      tester,
      DeviceDetailState(
        device: DevicesTestData.createWifiClient(hostName: 'iPhone-17'),
      ),
    );

    expect(find.text(hostnameLabel), findsOneWidget);
  });

  testWidgets('shows the host name beside a friendly name', (tester) async {
    await pump(
      tester,
      DeviceDetailState(
        device: DevicesTestData.createWifiClient(
            hostName: 'iPhone-17', friendlyName: 'Hank’s phone'),
      ),
    );

    expect(find.text(hostnameLabel), findsOneWidget);
  });

  testWidgets('has no Hostname row when the host name is empty',
      (tester) async {
    await pump(
      tester,
      DeviceDetailState(
        device: DevicesTestData.createWifiClient(
            hostName: '', friendlyName: 'Hank’s phone'),
      ),
    );

    expect(find.text(hostnameLabel), findsNothing);
  });
}
