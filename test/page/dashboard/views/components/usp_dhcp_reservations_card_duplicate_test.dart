@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/dhcp/views/dialogs/dhcp_reservation_edit_dialog.dart';
import 'package:privacy_gui/page/local_network/cards/usp_dhcp_reservations_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/provider_overrides/mock_dashboard_cards.dart'
    show cardOverrides;
import '../../../../mocks/provider_overrides/mock_dhcp.dart'
    show FixedDhcpReservationsNotifier;
import '../../../../mocks/test_data/scenes/cards_scene_data.dart'
    show testDhcpData, testDhcpReservations;
import '../../../../mocks/test_data/scenes/dhcp_scene_data.dart' show dataState;

/// Duplicate-address validation as reached from the **Dashboard** DHCP card
/// (#1070).
///
/// ## Why this file exists next to a green dialog suite
///
/// `test/page/dhcp/views/dialogs/dhcp_reservation_edit_dialog_test.dart` already
/// covers the rule, and it passed throughout the window this bug was reproducible
/// — because it constructs [DhcpReservationEditDialog] itself and hands it the
/// `existingReservations` list directly. What it cannot see is whether a *caller*
/// supplies that list, and `existingReservations` defaults to `const []`, so a
/// call site that omits it compiles, renders and validates — against nothing.
///
/// That is exactly how #1070 came back. The duplicate check landed on
/// 2026-07-08 (`31e4667b`) and wired the two callers that existed, both on the
/// DHCP detail page. Twelve minutes later `9028ec6e` repointed this card off its
/// own unvalidated `DhcpReservationDialog` and onto the shared dialog for #1067,
/// passing only the autocomplete options. The parameter added minutes earlier was
/// not part of that PR's diff to copy, and no compiler or test noticed: QA
/// re-verified via the detail page, and the issue's own repro steps ("Go to
/// Dashboard > DHCP") walked the one path where the check was a structural no-op.
///
/// So this suite pumps the **real card** and drives the **real dialog** through
/// the button a user taps. The assertion is not about the rule — the dialog suite
/// owns that — it is about the wiring the rule depends on, which is the only part
/// a per-call-site default can silently drop.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// The card is the DHCP dashboard card at a width wide enough to keep its list
/// form, inside a GoRouter because the dialog pops with `context.pop`.
///
/// `dhcpDataProvider` carries the reservations the card renders **and** the list
/// the duplicate check must be made against: they are the same list in
/// production, which is what makes the omission testable from here.
/// `uspDhcpReservationsProvider` is overridden only so `deviceOptions()` can be
/// read without a live USP transport.
Future<void> _pumpCard(WidgetTester tester) async {
  const surface = Size(800, 900);
  await tester.binding.setSurfaceSize(surface);
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  });

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        // A bounded box, not a scroll view: DashboardCardTemplate's body Column
        // uses Expanded, so an unbounded height makes it assert during layout
        // before any of this suite's own subject is reachable.
        builder: (context, state) => const Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              height: 700,
              child: UspDhcpReservationsCard(),
            ),
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...cardOverrides(
          dhcpData: testDhcpData,
          devicesData: DevicesData(
            meshNetwork: MeshNetwork(
              master: MasterNode(deviceId: 'GATEWAY', model: 'Test Router'),
            ),
          ),
        ),
        uspDhcpReservationsProvider
            .overrideWith(() => FixedDhcpReservationsNotifier(dataState())),
      ],
      child: MaterialApp.router(
        theme: _testTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps the card's own add button, so the dialog under test is the one the card
/// actually builds — arguments included.
Future<void> _openAddDialog(WidgetTester tester) async {
  final addButton = find.descendant(
    of: find.byType(UspDhcpReservationsCard),
    matching: find.byIcon(Icons.add),
  );
  expect(addButton, findsOneWidget,
      reason: 'the card must expose exactly one add affordance to drive');

  await tester.tap(addButton);
  await tester.pumpAndSettle();
  expect(find.byType(DhcpReservationEditDialog), findsOneWidget,
      reason: 'tapping add must open the shared reservation dialog');
}

/// The two AppTextFields are ordered MAC (0), IP (1) in the dialog.
AppTextField _macField() =>
    find.byType(AppTextField).evaluate().elementAt(0).widget as AppTextField;
AppTextField _ipField() =>
    find.byType(AppTextField).evaluate().elementAt(1).widget as AppTextField;

Future<void> _enterField(WidgetTester tester, int index, String text) async {
  await tester.enterText(find.byType(TextField).at(index), text);
  await tester.pumpAndSettle();
  // The dialog validates on blur (FocusNode listener), not on every keystroke.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _enterMac(WidgetTester tester, String text) =>
    _enterField(tester, 0, text);
Future<void> _enterIp(WidgetTester tester, String text) =>
    _enterField(tester, 1, text);

void main() {
  late String dupMac;
  late String dupIp;
  late String addLabel;

  setUp(() async {
    final loc = await AppLocalizations.delegate.load(const Locale('en'));
    dupMac = loc.duplicateMacAddress;
    dupIp = loc.duplicateIpAddress;
    addLabel = loc.add;
  });

  // The reservations the card renders, and therefore the addresses the dialog it
  // opens must refuse. Read off the fixture rather than typed, so a fixture
  // change cannot leave these tests asserting against addresses that are no
  // longer duplicates of anything.
  final existingMac = testDhcpReservations.first.mac;
  final existingIp = testDhcpReservations.first.ip;

  group('Dashboard DHCP card: add dialog rejects duplicates (#1070)', () {
    testWidgets('duplicate MAC is flagged and Add stays disabled',
        (tester) async {
      await _pumpCard(tester);
      await _openAddDialog(tester);

      await _enterMac(tester, existingMac);
      await _enterIp(tester, '192.168.1.99'); // unique

      expect(_macField().errorText, dupMac,
          reason: 'the card opened the dialog without its reservation list, so '
              'the duplicate check compared $existingMac against an empty list '
              '(#1070)');
      expect(_ipField().errorText, isNull);

      // Add must stay disabled: tapping it does not pop the dialog, so no USP
      // ADD is ever issued for the duplicate.
      await tester.tap(find.widgetWithText(AppButton, addLabel));
      await tester.pumpAndSettle();
      expect(find.byType(DhcpReservationEditDialog), findsOneWidget,
          reason: 'Add accepted a duplicate MAC from the Dashboard card');
    });

    testWidgets('duplicate IP is flagged and Add stays disabled',
        (tester) async {
      await _pumpCard(tester);
      await _openAddDialog(tester);

      await _enterMac(tester, 'AA:BB:CC:DD:EE:99'); // unique
      await _enterIp(tester, existingIp);

      expect(_ipField().errorText, dupIp,
          reason: 'the card opened the dialog without its reservation list, so '
              'the duplicate check compared $existingIp against an empty list '
              '(#1070)');
      expect(_macField().errorText, isNull);

      await tester.tap(find.widgetWithText(AppButton, addLabel));
      await tester.pumpAndSettle();
      expect(find.byType(DhcpReservationEditDialog), findsOneWidget,
          reason: 'Add accepted a duplicate IP from the Dashboard card');
    });

    testWidgets('a unique MAC+IP is still accepted', (tester) async {
      // The other half of the wiring: passing the list must not make the card
      // reject addresses that collide with nothing. Without this, "always
      // invalid" would satisfy the two tests above.
      await _pumpCard(tester);
      await _openAddDialog(tester);

      await _enterMac(tester, 'AA:BB:CC:DD:EE:99');
      await _enterIp(tester, '192.168.1.99');

      expect(_macField().errorText, isNull);
      expect(_ipField().errorText, isNull);

      await tester.tap(find.widgetWithText(AppButton, addLabel));
      await tester.pumpAndSettle();
      expect(find.byType(DhcpReservationEditDialog), findsNothing,
          reason: 'a non-duplicate reservation must still be submittable');
    });
  });
}
