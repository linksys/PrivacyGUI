import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';
import 'package:privacy_gui/page/devices/views/usp_device_list_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_devices.dart';
import '../../../mocks/test_data/scenes/devices_scene_data.dart';

/// The device list's search box shows the search the list is filtered by
/// (linksys/PrivacyGUI#1159).
///
/// The filter state outlives the page, but the box used to start empty on every
/// visit. So after searching, leaving and coming back, the list was still
/// filtered while the box read nothing and offered no clear button. Opening the
/// page with a search already in the filter state is that return visit.
void main() {
  setUpAll(() {
    // UspTopBar reads package_info during build; stub the platform channel.
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

  Widget wrap(DeviceFilterConfig filter) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const UspDeviceListView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...devicesListOverrides(devices: allDevices, filter: filter),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  testWidgets(
      'returning to the page with a search in effect shows that search in the '
      'box, with its clear button', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester
        .pumpWidget(wrap(const DeviceFilterConfig(searchQuery: 'iphone')));
    // Not `pumpAndSettle`: the page keeps an animation running, so it never
    // settles. Two frames resolve the device data and build the list.
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<AppTextField>(find.byType(AppTextField)).controller!.text,
      'iphone',
      reason: 'the list is filtered by "iphone", so the box must say so',
    );
    expect(find.byIcon(Icons.clear), findsOneWidget,
        reason: 'and offer the way out of it');
  });
}
