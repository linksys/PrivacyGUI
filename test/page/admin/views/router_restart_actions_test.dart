import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/admin/views/usp_admin_view.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_admin.dart';
import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/devices_test_data.dart';

/// The router's own Reboot / Factory Reset confirmation, from the
/// Administration page (#876). `Device.Reboot()` / `Device.FactoryReset()` take
/// every mesh node down with the router (FWDEV#202), so the copy says so when
/// the router has nodes, keeps the single-router copy when it has none, and
/// says so too when the devices are not read yet: an unknown mesh is not
/// treated as no mesh on a destructive action.
void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (call) async => call.method == 'getAll'
          ? <String, dynamic>{
              'appName': 'PrivacyGUI',
              'packageName': 'com.linksys.privacygui',
              'version': '0.0.0',
              'buildNumber': '0',
            }
          : null,
    );
  });

  Future<void> openAdmin(WidgetTester tester, Override devices) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...adminPageOverrides(),
        devices,
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            LinksysRoute(
              path: '/',
              name: 'admin_host',
              builder: (context, state) => const UspAdminView(),
            ),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// The devices as the dashboard leaves them: read once, kept for the
  /// session (an L1 provider). The Administration page itself does not read
  /// them.
  Future<void> readDevices(WidgetTester tester) async {
    final container =
        ProviderScope.containerOf(tester.element(find.byType(UspAdminView)));
    await container.read(devicesDataProvider.future);
    await tester.pump();
  }

  Future<void> tapButton(WidgetTester tester, String identifier) async {
    await tester.tap(find.byWidgetPredicate(
        (w) => w is AppButton && w.identifier == identifier));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Override devicesOf(MeshNetwork network) => devicesDataProvider.overrideWith(
      () => FixedDevicesDataNotifierForTopology(
          DevicesData(meshNetwork: network)));

  final singleRouter = MeshNetwork(master: DevicesTestData.createMaster());
  final withNode = MeshNetwork(
    master: DevicesTestData.createMaster(),
    slaves: [DevicesTestData.createWifiSlave()],
  );

  group('Administration - the router\'s confirmation (#876)', () {
    testWidgets('a single router keeps the single-router copy', (tester) async {
      await openAdmin(tester, devicesOf(singleRouter));
      await readDevices(tester);

      await tapButton(tester, 'admin-reboot');

      expect(find.text('Reboot Router'), findsOneWidget);
      expect(find.textContaining('The router will restart.'), findsOneWidget);
    });

    testWidgets('a router with nodes says the whole mesh goes', (tester) async {
      await openAdmin(tester, devicesOf(withNode));
      await readDevices(tester);

      await tapButton(tester, 'admin-factory-reset');

      expect(find.text('Reset Parent and all its child/s to Factory Default'),
          findsOneWidget);
    });

    // The Administration page needs no devices to offer its buttons, so they
    // can be pressed before the devices are read.
    testWidgets('devices not read yet: the whole mesh copy, not the single one',
        (tester) async {
      await openAdmin(
          tester, devicesDataProvider.overrideWith(_LoadingDevicesData.new));

      await tapButton(tester, 'admin-reboot');

      expect(find.text('Reboot Parent and all its child/s'), findsOneWidget);
      expect(find.text('Reboot Router'), findsNothing);
    });
  });
}

/// A devices read that never returns.
class _LoadingDevicesData extends DevicesDataNotifier {
  @override
  Future<DevicesData> build() => Completer<DevicesData>().future;
}
