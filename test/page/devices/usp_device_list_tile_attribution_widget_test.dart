import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Verifies what [UspDeviceListTile] says about a device's parent node
/// (PrivacyGUI#1439).
///
/// The bug this guards was a *wrong* attribution, not a missing one: a device
/// whose parent could not be resolved was drawn as "via <Master>". The three
/// business-logic layers of the fix are covered by unit tests, but the sentence
/// the user actually reads is assembled here, in the subtitle — so the marker
/// appearing, and `viaNode` not appearing alongside it, needs asserting at this
/// level or the rendering can regress with every unit test still green.
///
/// Not tagged `ui`: gated in `run_tests.sh` (the repo's only CI test job).
void main() {
  ClientDevice deviceWith({
    required String mac,
    required String hostName,
    String? parentNodeName,
    bool isUnattributed = false,
  }) =>
      ClientDevice(
        mac: mac,
        hostName: hostName,
        isActive: true,
        ip: '192.168.1.10',
        connectionType: ConnectionType.wired,
        parentNodeName: parentNodeName,
        isUnattributed: isUnattributed,
      );

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

  Future<void> pump(WidgetTester tester, List<ClientDevice> devices) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(devices));
    await tester.pump();
  }

  group('UspDeviceListTile parent-node attribution', () {
    testWidgets('an attributed device reads "via <node>"', (tester) async {
      await pump(tester, [
        deviceWith(
          mac: 'AA:BB:CC:DD:EE:01',
          hostName: 'Alpha',
          parentNodeName: 'Living Room',
        ),
      ]);

      expect(find.textContaining('via Living Room'), findsOneWidget);
      expect(find.textContaining('Unattributed'), findsNothing);
    });

    testWidgets(
        'an unattributed device reads the marker and never "via <node>"',
        (tester) async {
      await pump(tester, [
        deviceWith(
          mac: 'AA:BB:CC:DD:EE:02',
          hostName: 'Bravo',
          // The name the model was handed is irrelevant: an unattributed device
          // must never be drawn as if it were on a node, which is the whole of
          // #1439's user-visible symptom.
          parentNodeName: 'Living Room',
          isUnattributed: true,
        ),
      ]);

      expect(find.textContaining('Unattributed'), findsOneWidget);
      expect(find.textContaining('via '), findsNothing,
          reason: 'the marker replaces the attribution, it does not join it');
    });

    testWidgets('a device with no parent at all shows neither', (tester) async {
      await pump(tester, [
        deviceWith(mac: 'AA:BB:CC:DD:EE:03', hostName: 'Charlie'),
      ]);

      expect(find.textContaining('via '), findsNothing);
      expect(find.textContaining('Unattributed'), findsNothing);
    });
  });
}
