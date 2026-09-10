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
/// The dialog's own suite (`test/page/dhcp/views/dialogs/`) covers the rule and
/// stayed green throughout the window this bug was reproducible: it constructs
/// [DhcpReservationEditDialog] itself, so it never sees what a *caller* passes.
/// `existingReservations` defaulted to `const []` then, so this card omitted it
/// and validated against nothing — `9028ec6e` repointed the card onto the shared
/// dialog twelve minutes after `31e4667b` added the check, with no compiler or
/// test to notice.
///
/// So this suite pumps the **real card** and taps the **real button**. The
/// parameter is now `required`, which makes that omission a compile error but
/// still cannot check *which* list a caller hands over — an empty literal, or a
/// list the card does not render, compiles just as well. That is what this holds.
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
///
/// The `existingReservations` assertion is the invariant this suite exists for,
/// stated directly rather than inferred from an error message: every other
/// assertion below reaches it through the dialog's validation, the blur
/// listeners and the layout, any of which can change and break these tests for
/// reasons unrelated to #1070. This one fails only when the card stops handing
/// the dialog what it renders, and says so.
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

  final dialog = tester.widget<DhcpReservationEditDialog>(
      find.byType(DhcpReservationEditDialog));
  expect(dialog.existingReservations, testDhcpReservations,
      reason: 'the card must hand the dialog the reservations it is rendering, '
          'or the duplicate check validates against nothing (#1070)');
}

/// Locates a dialog field by the `identifier` the dialog already exposes for
/// E2E, rather than by position.
///
/// Ordinal access (`elementAt(0/1)`) would couple this suite to the order of the
/// two fields, and its failure mode is a false negative rather than a red build:
/// swap MAC and IP and the helpers below type into the wrong field while an
/// assertion can still be satisfied by a coincidentally-matching message.
Finder _fieldByIdentifier(String identifier) => find.byWidgetPredicate(
      (widget) => widget is AppTextField && widget.identifier == identifier,
      description: "AppTextField(identifier: '$identifier')",
    );

final _macFinder = _fieldByIdentifier('dhcp-reservation-mac');
final _ipFinder = _fieldByIdentifier('dhcp-reservation-ip');

AppTextField _macField(WidgetTester tester) => tester.widget(_macFinder);
AppTextField _ipField(WidgetTester tester) => tester.widget(_ipFinder);

Future<void> _enterField(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(
    find.descendant(of: field, matching: find.byType(TextField)),
    text,
  );
  await tester.pumpAndSettle();
  // The dialog validates on blur (FocusNode listener), not on every keystroke.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _enterMac(WidgetTester tester, String text) =>
    _enterField(tester, _macFinder, text);
Future<void> _enterIp(WidgetTester tester, String text) =>
    _enterField(tester, _ipFinder, text);

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

      expect(_macField(tester).errorText, dupMac,
          reason: '$existingMac is already reserved in what the card renders, '
              'so the dialog the card opens must flag it (#1070)');
      expect(_ipField(tester).errorText, isNull);

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

      expect(_ipField(tester).errorText, dupIp,
          reason: '$existingIp is already reserved in what the card renders, '
              'so the dialog the card opens must flag it (#1070)');
      expect(_macField(tester).errorText, isNull);

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

      expect(_macField(tester).errorText, isNull);
      expect(_ipField(tester).errorText, isNull);

      await tester.tap(find.widgetWithText(AppButton, addLabel));
      await tester.pumpAndSettle();
      expect(find.byType(DhcpReservationEditDialog), findsNothing,
          reason: 'a non-duplicate reservation must still be submittable');
    });
  });
}
