import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';
import 'package:privacy_gui/page/devices/views/usp_device_detail_view.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_devices.dart';
import '../../../mocks/provider_overrides/mock_dhcp.dart';
import '../../../mocks/test_data/devices_test_data.dart';
import '../../../mocks/test_data/local_network_test_data.dart';
import '../../../mocks/test_data/scenes/dhcp_scene_data.dart' show dataState;

/// The device page's IP row and Reserve button for a device with no IPv4, and
/// the LAN-host check Reserve runs before it writes (#1838).
///
/// A Hosts row reading `0.0.0.0` reaches the page as `ip: ''`
/// (`MeshNetworkBuilder`), so an empty `ip` is that case.
class _RecordingReservationsNotifier extends FixedDhcpReservationsNotifier {
  _RecordingReservationsNotifier(this.added) : super(dataState());

  final List<(String mac, String ip)> added;

  @override
  Future<void> immediateAdd({
    required String mac,
    required String ip,
    bool enable = true,
    String name = '',
  }) async =>
      added.add((mac, ip));
}

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

  final l10n = lookupAppLocalizations(const Locale('en'));

  Future<List<(String, String)>> pump(WidgetTester tester, String ip,
      {bool lanReadable = true}) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final added = <(String, String)>[];
    final detail = DeviceDetailState(
      device: DevicesTestData.createWiredClient(ip: ip),
    );
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
        uspDhcpReservationsProvider
            .overrideWith(() => _RecordingReservationsNotifier(added)),
        lanDataProvider.overrideWith(() => lanReadable
            ? FixedLanDataNotifier(LocalNetworkTestData.createLanData())
            : UnreadableLanDataNotifier()),
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
    return added;
  }

  Finder reserveButton() => find.byWidgetPredicate(
      (w) => w is AppButton && w.identifier == 'device-reservation-reserve');

  Future<void> tapReserve(WidgetTester tester) async {
    await tester.ensureVisible(reserveButton());
    await tester.tap(reserveButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('a device with no IPv4', () {
    testWidgets('its IP row reads "-", with nothing to copy', (tester) async {
      await pump(tester, '');

      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('says it cannot be reserved and disables Reserve',
        (tester) async {
      await pump(tester, '');

      expect(find.text(l10n.noIpv4AddressDesc), findsOneWidget);
      expect(tester.widget<AppButton>(reserveButton()).onTap, isNull);
    });

    // The page applies the rule itself, not only through the builder: a
    // 0.0.0.0 that reached it would still not be offered for a reservation.
    testWidgets('0.0.0.0 is no IPv4 on the page either', (tester) async {
      await pump(tester, '0.0.0.0');

      expect(find.text('-'), findsOneWidget);
      expect(find.text('0.0.0.0'), findsNothing);
      expect(find.text(l10n.noIpv4AddressDesc), findsOneWidget);
      expect(tester.widget<AppButton>(reserveButton()).onTap, isNull);
    });
  });

  group('Reserve checks the address as a LAN host', () {
    testWidgets('a LAN host is reserved', (tester) async {
      final added = await pump(tester, '192.168.1.102');

      expect(tester.widget<AppButton>(reserveButton()).onTap, isNotNull);
      await tapReserve(tester);

      expect(added.map((a) => a.$2), ['192.168.1.102']);
    });

    testWidgets('an address outside the LAN is not sent, and says why',
        (tester) async {
      final added = await pump(tester, '10.0.0.5');

      await tapReserve(tester);

      expect(added, isEmpty);
      expect(find.text(l10n.invalidIpAddress), findsOneWidget);
    });
    testWidgets('a LAN that cannot be read stops it; nothing is sent',
        (tester) async {
      final added = await pump(tester, '192.168.1.102', lanReadable: false);

      await tapReserve(tester);

      expect(added, isEmpty);
    });
  });
}
