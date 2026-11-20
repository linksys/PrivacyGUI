import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// The device list's address slot for a device with no IPv4 (#1838): a Hosts
/// row reading `0.0.0.0` arrives as `ip: ''`, and the slot reads "-" rather
/// than going blank.
void main() {
  ClientDevice deviceWith(String ip) => ClientDevice(
        mac: 'AA:BB:CC:DD:EE:01',
        hostName: 'Alpha',
        isActive: true,
        ip: ip,
        connectionType: ConnectionType.wired,
      );

  Widget wrap(ClientDevice device) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        home: Scaffold(body: UspDeviceListTile(device: device, onTap: () {})),
      );

  Future<void> pump(WidgetTester tester, ClientDevice device) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(device));
    await tester.pump();
  }

  testWidgets('a device with no IPv4 reads "-"', (tester) async {
    await pump(tester, deviceWith(''));

    expect(find.text('-'), findsOneWidget);
  });

  testWidgets('a device with an address shows it', (tester) async {
    await pump(tester, deviceWith('192.168.1.10'));

    expect(find.text('192.168.1.10'), findsOneWidget);
    expect(find.text('-'), findsNothing);
  });
}
