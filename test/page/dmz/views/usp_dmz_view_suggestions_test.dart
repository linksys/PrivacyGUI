import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dmz/models/dmz_feature_state.dart';
import 'package:privacy_gui/page/dmz/views/usp_dmz_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_dmz.dart';
import '../../../mocks/test_data/devices_test_data.dart';
import '../../../mocks/test_data/scenes/dmz_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// #1775: both DMZ host fields suggest the LAN's devices by name, the way the
/// DHCP reservation dialog's MAC and IP fields do — in place of 1.x's "View
/// DHCP client table".
///
/// **Untagged on purpose**, like `instant_privacy_add_device_search_test.dart`:
/// the suggestion overlay exists only while the field has focus and a query, so
/// no golden and no layout-gate cell renders it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  final devices = DevicesTestData.createDevicesData(
    meshNetwork: DevicesTestData.createSingleNodeNetwork(masterClients: [
      DevicesTestData.createWifiClient(
          mac: 'AA:BB:CC:00:00:11', ip: '192.168.1.11', hostName: 'Phone'),
      DevicesTestData.createWiredClient(
          mac: 'AA:BB:CC:00:00:22', ip: '192.168.1.22', hostName: 'Desktop'),
    ]),
  );

  /// Hosted through the layout gate's [pageSurfaceHost] because `UspTopBar`
  /// reaches `GoRouter.of(context)` unguarded.
  Widget host(DmzFeatureState state) => pageSurfaceHost(
        view: const UspDmzView(),
        locale: const Locale('en'),
        overrides: dmzOverrides(state, devices),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// The destination field: the one text input under an autocomplete.
  final destinationField = find.descendant(
    of: find.byType(AppSelectAutoComplete),
    matching: find.byType(EditableText),
  );

  testWidgets('the IP field suggests a device by name, found by its address',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(gateDmzState));
    await settle(tester);

    await tester.enterText(destinationField, '1.11');
    await settle(tester);

    expect(find.text('Phone'), findsOneWidget,
        reason: 'the device holding 192.168.1.11 is suggested by its name');
    expect(find.text('Desktop'), findsNothing);
  });

  testWidgets('the MAC field suggests a device by name, found by its MAC',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(gateDmzMacState));
    await settle(tester);

    await tester.enterText(destinationField, '00:00:22');
    await settle(tester);

    expect(find.text('Desktop'), findsOneWidget,
        reason: 'the device with MAC AA:BB:CC:00:00:22 is suggested by name');
    expect(find.text('Phone'), findsNothing);
  });
}
