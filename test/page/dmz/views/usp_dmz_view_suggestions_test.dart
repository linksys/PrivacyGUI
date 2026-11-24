import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dmz/models/dmz_feature_state.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/dmz/providers/usp_dmz_notifier.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/dmz/views/usp_dmz_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_devices.dart'
    show FixedDevicesDataNotifier;
import '../../../mocks/provider_overrides/mock_dhcp.dart'
    show FixedLanDataNotifier;
import '../../../mocks/provider_overrides/mock_dmz.dart';
import '../../../mocks/test_data/local_network_test_data.dart';
import '../../../mocks/test_data/devices_test_data.dart';
import '../../../mocks/test_data/scenes/dmz_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// A [FixedDmzNotifier] that counts the validations the page asks for.
class _CountingDmzNotifier extends FixedDmzNotifier {
  _CountingDmzNotifier(super.state);
  int validations = 0;

  @override
  void validate() => validations++;
}

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
      // No IPv4: a Hosts row reading 0.0.0.0 arrives so (#1838).
      DevicesTestData.createWiredClient(
          mac: 'AA:BB:CC:00:00:33', ip: '', hostName: 'NoAddress'),
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

  // A tooltip-mode field loses focus on web the moment it is focused with an
  // error shown (flutter/flutter#195289, ui_kit v3.6.10; E2E P13). The blur
  // only happens in a browser, so this guards the setting that avoids it.
  for (final (type, state) in [
    ('IP', gateDmzState),
    ('MAC', gateDmzMacState),
  ]) {
    testWidgets('the $type destination field shows its error as text',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(state));
      await settle(tester);

      final field = find.descendant(
        of: find.byType(AppSelectAutoComplete),
        matching: find.byType(AppTextFormField),
      );
      expect(field, findsOneWidget);
      expect(tester.widget<AppTextFormField>(field).errorDisplayMode,
          AppErrorDisplayMode.text);
    });
  }

  // #1838: a device with no IPv4 is not offered by IP, and is offered by MAC
  // with no subtitle, as in the MAC filter's picker.
  List<AppAutoCompleteOption> options(WidgetTester tester) => tester
      .widget<AppSelectAutoComplete>(find.byType(AppSelectAutoComplete))
      .options;

  testWidgets('the IP field does not offer a device with no IPv4',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(gateDmzState));
    await settle(tester);

    expect(options(tester).map((o) => o.label), ['Phone', 'Desktop']);
  });

  testWidgets('the MAC field offers it with no subtitle', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(gateDmzMacState));
    await settle(tester);

    final byLabel = {for (final o in options(tester)) o.label: o.subtitle};
    expect(byLabel['NoAddress'], isNull);
    expect(byLabel['Phone'], '192.168.1.11');
  });

  // #1838: the source CIDR field shows its error, as text like the host
  // fields, and its hint is localized.
  group('the source CIDR field', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    // The page's one text field outside the host autocomplete.
    Finder cidrField() => find.byWidgetPredicate((w) =>
        w is AppTextFormField &&
        find
            .ancestor(
                of: find.byWidget(w),
                matching: find.byType(AppSelectAutoComplete))
            .evaluate()
            .isEmpty);

    testWidgets('has the localized hint and shows its error as text',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final withError = gateDmzState.copyWith(
          status: gateDmzState.status.copyWith(
              fieldErrors: {'sourcePrefix': DmzErrorKeys.invalidCidr}));
      await tester.pumpWidget(host(withError));
      await settle(tester);

      expect(cidrField(), findsOneWidget);
      final input = tester.widget<TextField>(
          find.descendant(of: cidrField(), matching: find.byType(TextField)));
      expect(input.decoration?.hintText, l10n.cidrHint);
      final field = tester.widget<AppTextFormField>(cidrField());
      expect(field.errorDisplayMode, AppErrorDisplayMode.text);
      expect(field.externalErrorText, l10n.invalidCidrFormat);
    });

    testWidgets('an empty range reads "required"', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final withError = gateDmzState.copyWith(
          status: gateDmzState.status.copyWith(
              fieldErrors: {'sourcePrefix': DmzErrorKeys.cidrRequired}));
      await tester.pumpWidget(host(withError));
      await settle(tester);

      expect(tester.widget<AppTextFormField>(cidrField()).externalErrorText,
          l10n.cidrRequired);
    });

    testWidgets('switching to "any" checks the form again', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // The CIDR field's error must not outlive the field: the switch asks
      // for a validation, which drops it.
      final notifier = _CountingDmzNotifier(gateDmzState);
      await tester.pumpWidget(pageSurfaceHost(
        view: const UspDmzView(),
        locale: const Locale('en'),
        overrides: [
          uspDmzProvider.overrideWith(() => notifier),
          devicesDataProvider
              .overrideWith(() => FixedDevicesDataNotifier(devices)),
          lanDataProvider.overrideWith(
              () => FixedLanDataNotifier(LocalNetworkTestData.createLanData())),
        ],
      ));
      await settle(tester);

      await tester.tap(find.text(l10n.anyAllSources));
      await settle(tester);

      expect(notifier.validations, 1);
    });
  });
}
