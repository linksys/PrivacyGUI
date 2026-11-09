import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/views/mac_filter_add_device_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../util/app_test_fonts.dart';

/// #1737 AC6: "name and IP search behave exactly as today".
///
/// The separator-less MAC search compares hex digits, and an IP such as
/// `192.168.1.16` is made only of hex digits and `.`. Without a guard it would
/// also suggest a device whose MAC holds those digits (`19:21:68:11:…`), which
/// the IP search never did. These fixtures put such a MAC next to the device
/// the IP belongs to.
///
/// Untagged on purpose, like the other view tests in this directory.
void main() {
  const devices = [
    MacFilterDeviceUIModel(
      mac: 'E8:D5:2B:77:AE:C5',
      displayName: 'Pixel-7a',
      ipAddress: '192.168.1.160',
    ),
    // Its MAC digits contain `192168116` but its IP does not start with 192.
    MacFilterDeviceUIModel(
      mac: '19:21:68:11:6A:BC',
      displayName: 'Printer',
      ipAddress: '10.0.0.5',
    ),
  ];

  setUpAll(() async {
    await loadAppFonts();
  });

  Widget host() => pageSurfaceHost(
        locale: const Locale('en'),
        overrides: const [],
        view: Builder(
          builder: (context) => Center(
            child: AppButton.primary(
              label: 'open',
              onTap: () => showMacFilterAddDeviceDialog(
                context: context,
                existingMacs: const [],
                connectedDevices: devices,
                onAdd: (_) {},
              ),
            ),
          ),
        ),
      );

  Future<void> settle(WidgetTester tester, [int frames = 5]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.byType(AppTextField), findsOneWidget,
        reason: 'the add-device dialog is open');
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.tap(find.byType(EditableText));
    await settle(tester);
    var typed = '';
    for (final ch in text.split('')) {
      typed += ch;
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: typed,
        selection: TextSelection.collapsed(offset: typed.length),
      ));
      await settle(tester, 1);
    }
    await settle(tester);
  }

  Finder suggested(String label) =>
      find.descendant(of: find.byType(ListView), matching: find.text(label));

  group('an IP query suggests only the device with that IP (AC6)', () {
    for (final query in ['192.168', '192.168.1', '192.168.1.16']) {
      testWidgets('"$query" suggests Pixel-7a, not the MAC 19:21:68:…',
          (tester) async {
        await openDialog(tester);
        await type(tester, query);

        expect(suggested('Pixel-7a'), findsOneWidget,
            reason: 'IP search finds the device as before');
        expect(suggested('Printer'), findsNothing,
            reason: 'an IP is not read as the MAC digits 192168…');
      });
    }

    testWidgets('"10.0" suggests Printer by its IP', (tester) async {
      await openDialog(tester);
      await type(tester, '10.0');

      expect(suggested('Printer'), findsOneWidget);
      expect(suggested('Pixel-7a'), findsNothing);
    });
  });

  testWidgets('the same MAC is still found by its digits', (tester) async {
    await openDialog(tester);
    await type(tester, '1921.6811');

    expect(suggested('Printer'), findsOneWidget);
    expect(suggested('Pixel-7a'), findsNothing);
  });
}
