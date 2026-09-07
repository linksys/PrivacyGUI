import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Verifies the per-row E2E arrival anchor added to [UspDeviceListTile] for
/// PrivacyGUI#1391 (unblocks PrivacyGUI-USP-E2E#86). The device-detail page is
/// only reachable by tapping a device row, so the row itself needs a stable,
/// data-derived hook (`device-row-<normalized-mac>`) — otherwise the hooks on
/// the detail page are unreachable (the exact B1 lesson from #1391 applied to a
/// navigation entry point).
///
/// The hook MUST be derived from the device MAC (never a row index) and MUST be
/// stable across list reordering and independent of the human-visible hostname.
///
/// Not tagged `ui`: gated in `run_tests.sh` (the repo's only CI test job).
void main() {
  ClientDevice deviceWith({required String mac, required String hostName}) =>
      ClientDevice(
        mac: mac,
        hostName: hostName,
        isActive: true,
        ip: '192.168.1.10',
        connectionType: ConnectionType.wired,
      );

  final deviceA = deviceWith(mac: 'AA:BB:CC:DD:EE:01', hostName: 'Alpha');
  final deviceB = deviceWith(mac: '11:22:33:44:55:66', hostName: 'Bravo');

  Widget wrap(List<ClientDevice> devices) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: themeConfig.createLightTheme(),
      home: Scaffold(
        body: Column(
          children: [
            for (final d in devices) UspDeviceListTile(device: d, onTap: () {}),
          ],
        ),
      ),
    );
  }

  group('UspDeviceListTile row identifier', () {
    testWidgets('renders a MAC-derived hook, distinct per device',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap([deviceA, deviceB]));
      await tester.pump();

      // Each row anchor equals `device-row-<normalized-mac>`.
      expect(
          find.bySemanticsIdentifier('device-row-AABBCCDDEE01'), findsOneWidget,
          reason: 'row A must carry a hook derived from its MAC');
      expect(
          find.bySemanticsIdentifier('device-row-112233445566'), findsOneWidget,
          reason: 'row B must carry a hook derived from its MAC');

      // The two rows must resolve to distinct widgets.
      final a = find.bySemanticsIdentifier('device-row-AABBCCDDEE01');
      final b = find.bySemanticsIdentifier('device-row-112233445566');
      expect(a.evaluate().single != b.evaluate().single, isTrue,
          reason: 'the two rows must be distinct nodes');

      handle.dispose();
    });

    testWidgets('the hook is stable across list reordering', (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Reversed order — same devices, opposite positions.
      await tester.pumpWidget(wrap([deviceB, deviceA]));
      await tester.pump();

      // Both MAC-derived hooks are still present and unchanged: the identifier
      // tracks the device, not the row index.
      expect(
          find.bySemanticsIdentifier('device-row-AABBCCDDEE01'), findsOneWidget,
          reason: 'row A keeps its MAC hook regardless of position');
      expect(
          find.bySemanticsIdentifier('device-row-112233445566'), findsOneWidget,
          reason: 'row B keeps its MAC hook regardless of position');

      handle.dispose();
    });

    test('identifierKey normalizes the MAC (separators stripped, uppercased)',
        () {
      expect(
        UspDeviceListTile(device: deviceA).identifierKey,
        'AABBCCDDEE01',
      );
      expect(
        UspDeviceListTile(device: deviceB).identifierKey,
        '112233445566',
      );
    });
  });
}
