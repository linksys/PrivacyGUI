@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/dhcp/views/dialogs/dhcp_reservation_edit_dialog.dart';

/// Widget tests for [DhcpReservationEditDialog] duplicate-address validation.
///
/// Covers linksys/PrivacyGUI#1070: the Add/Edit dialog must reject a
/// reservation whose MAC or IP already exists among the current reservations,
/// while still allowing the reservation being edited to keep its own address.
///
/// The dialog surfaces these errors via the MAC and IP [AppTextField]s'
/// `errorText`, which each renders as a line of text under the field
/// (`AppErrorDisplayMode.text`; the dialog's class doc says why not a
/// tooltip). These tests assert on the widget's `errorText` property (the
/// source of truth) rather than a rendered string, which is both more robust
/// and independent of ui_kit rendering internals.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

final _existing = [
  DhcpReservationUIModel(
      mac: 'AA:BB:CC:DD:EE:01', ip: '192.168.1.10', enable: true),
  DhcpReservationUIModel(
      mac: 'AA:BB:CC:DD:EE:02', ip: '192.168.1.11', enable: true),
];

/// Pumps the dialog inside a GoRouter (the dialog calls context.pop) and
/// immediately opens it. Returns the record the dialog pops with (null = still
/// open / cancelled).
Future<({String mac, String ip, bool enable})?> _pumpAndOpen(
  WidgetTester tester, {
  DhcpReservationUIModel? reservation,
  List<DhcpReservationUIModel>? existing,
  String? lanIp,
  String? lanSubnetMask,
  List<AppAutoCompleteOption> macOptions = const [],
}) async {
  final existingReservations = existing ?? _existing;
  ({String mac, String ip, bool enable})? result;
  bool popped = false;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showAppDialog<
                      ({String mac, String ip, bool enable})>(
                    context: context,
                    builder: (_) => DhcpReservationEditDialog(
                      reservation: reservation,
                      existingReservations: existingReservations,
                      lanIp: lanIp,
                      lanSubnetMask: lanSubnetMask,
                      macDeviceOptions: macOptions,
                    ),
                  );
                  popped = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(
    theme: _testTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return popped ? result : null;
}

/// The two AppTextFields are ordered MAC (0), IP (1) in the dialog.
AppTextField _macField() =>
    find.byType(AppTextField).evaluate().elementAt(0).widget as AppTextField;
AppTextField _ipField() =>
    find.byType(AppTextField).evaluate().elementAt(1).widget as AppTextField;

Future<void> _enterMac(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).at(0), text);
  await tester.pumpAndSettle();
  // The dialog validates on blur (FocusNode listener), not on every keystroke.
  // Drop focus to trigger _validate(), mirroring a real user tabbing away.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _enterIp(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).at(1), text);
  await tester.pumpAndSettle();
  // The dialog validates on blur (FocusNode listener), not on every keystroke.
  // Drop focus to trigger _validate(), mirroring a real user tabbing away.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

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

  group('DhcpReservationEditDialog duplicate validation (add)', () {
    testWidgets('duplicate MAC sets error and keeps Add disabled',
        (tester) async {
      await _pumpAndOpen(tester);
      await _enterMac(tester, 'AA:BB:CC:DD:EE:01'); // dup of existing
      await _enterIp(tester, '192.168.1.99'); // unique IP

      expect(_macField().errorText, dupMac);
      expect(_ipField().errorText, isNull);

      // Add stays disabled -> tapping does not pop the dialog.
      await tester.tap(find.widgetWithText(AppButton, addLabel));
      await tester.pumpAndSettle();
      expect(find.byType(DhcpReservationEditDialog), findsOneWidget);
    });

    testWidgets('duplicate IP sets error and keeps Add disabled',
        (tester) async {
      await _pumpAndOpen(tester);
      await _enterMac(tester, 'AA:BB:CC:DD:EE:99'); // unique MAC
      await _enterIp(tester, '192.168.1.10'); // dup of existing

      expect(_ipField().errorText, dupIp);
      expect(_macField().errorText, isNull);

      await tester.tap(find.widgetWithText(AppButton, addLabel));
      await tester.pumpAndSettle();
      expect(find.byType(DhcpReservationEditDialog), findsOneWidget);
    });

    testWidgets('duplicate MAC match is case-insensitive', (tester) async {
      await _pumpAndOpen(tester);
      await _enterMac(tester, 'aa:bb:cc:dd:ee:01'); // lowercase dup
      await _enterIp(tester, '192.168.1.99');

      expect(_macField().errorText, dupMac);
    });

    testWidgets('fully unique MAC+IP has no duplicate error', (tester) async {
      await _pumpAndOpen(tester);
      await _enterMac(tester, 'AA:BB:CC:DD:EE:99');
      await _enterIp(tester, '192.168.1.99');

      expect(_macField().errorText, isNull);
      expect(_ipField().errorText, isNull);
    });
  });

  group('DhcpReservationEditDialog duplicate validation (edit)', () {
    testWidgets('editing keeps own MAC/IP without a duplicate error',
        (tester) async {
      // Open in edit mode on the first reservation; its pre-filled own
      // MAC/IP must not be flagged as a duplicate of itself.
      await _pumpAndOpen(tester, reservation: _existing[0]);
      // Re-enter its own values to force _validate() to run.
      await _enterMac(tester, _existing[0].mac);
      await _enterIp(tester, _existing[0].ip);

      expect(_macField().errorText, isNull);
      expect(_ipField().errorText, isNull);
    });

    testWidgets('editing to another existing MAC flags duplicate',
        (tester) async {
      await _pumpAndOpen(tester, reservation: _existing[0]);
      await _enterMac(tester, _existing[1].mac); // collide with the OTHER one

      expect(_macField().errorText, dupMac);
    });

    testWidgets(
        'editing own reservation is not a false-positive duplicate when its '
        'non-key field drifts in existingReservations (SSE race)',
        (tester) async {
      // Reproduces the SSE-race false-positive: while the edit dialog is open,
      // the Notifier re-fetches and toggles the edited reservation's `enable`
      // flag in existingReservations. Because DhcpReservationUIModel uses
      // value-equality (props include `enable`), a value-equality self-filter
      // would fail to exclude self and flag the user's own MAC/IP as a
      // duplicate. Self must be excluded by stable instancePath identity.
      final frozen = DhcpReservationUIModel(
        instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1',
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.10',
        enable: true,
      );
      // Same instancePath, but enable drifted true -> false (SSE update).
      final drifted = DhcpReservationUIModel(
        instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1',
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.1.10',
        enable: false,
      );
      await _pumpAndOpen(tester, reservation: frozen, existing: [drifted]);
      // Change the value (so onChanged fires) then set it back to its own MAC,
      // forcing _validate() to run against the drifted self-entry.
      await _enterMac(tester, 'AA:BB:CC:DD:EE:09');
      await _enterMac(tester, frozen.mac);
      await _enterIp(tester, '192.168.1.99');
      await _enterIp(tester, frozen.ip);

      expect(_macField().errorText, isNull);
      expect(_ipField().errorText, isNull);
    });
  });

  // #1838: the reservation address is checked as every form that writes a
  // LAN host's address checks it, with the same messages.
  group('the address, as a LAN host', () {
    late AppLocalizations l10n;
    setUp(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    Future<void> open(WidgetTester tester) => _pumpAndOpen(tester,
        lanIp: '192.168.1.1', lanSubnetMask: '255.255.255.0');

    testWidgets('0.0.0.0 is refused as reserved', (tester) async {
      await open(tester);
      await _enterIp(tester, '0.0.0.0');

      expect(_ipField().errorText, l10n.reservedIpNotAllowed);
    });

    testWidgets('an address outside the LAN is refused', (tester) async {
      await open(tester);
      await _enterIp(tester, '10.0.0.5');

      expect(_ipField().errorText, l10n.invalidIpAddress);
    });

    testWidgets("the router's own address is refused", (tester) async {
      await open(tester);
      await _enterIp(tester, '192.168.1.1');

      expect(_ipField().errorText, l10n.invalidIpAddress);
    });

    testWidgets('a LAN host is accepted', (tester) async {
      await open(tester);
      await _enterIp(tester, '192.168.1.50');

      expect(_ipField().errorText, isNull);
    });

    // A LAN subnet change leaves a reservation on the old subnet. Editing it
    // flags its address, whatever else the edit changes, because it is no
    // longer a LAN host.
    testWidgets('a reservation saved on a LAN that has since moved is flagged',
        (tester) async {
      final onOldSubnet = DhcpReservationUIModel(
        instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
        mac: 'AA:BB:CC:DD:EE:01',
        ip: '192.168.2.10',
        enable: true,
      );
      await _pumpAndOpen(tester,
          reservation: onOldSubnet,
          existing: [onOldSubnet],
          lanIp: '192.168.1.1',
          lanSubnetMask: '255.255.255.0');
      // Edit the MAC only; the dialog checks every field.
      await _enterMac(tester, 'AA:BB:CC:DD:EE:09');

      expect(_ipField().errorText, l10n.invalidIpAddress);
    });
  });

  // #1838: a device with no IPv4 is offered by MAC with no subtitle. Picking
  // it must clear the IP field, not keep the address of the device picked
  // before it: that would reserve one device's address for another.
  testWidgets('picking a device with no IPv4 clears the IP field',
      (tester) async {
    await _pumpAndOpen(tester, existing: const [], macOptions: const [
      AppAutoCompleteOption(
          label: 'With Address',
          value: 'AA:BB:CC:00:00:0A',
          subtitle: '192.168.1.10'),
      AppAutoCompleteOption(label: 'No Address', value: 'AA:BB:CC:00:00:0B'),
    ]);

    Future<void> pick(String label) async {
      await tester.enterText(find.byType(TextField).at(0), 'AA:BB:CC');
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    String ipText() =>
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text;

    await pick('With Address');
    expect(ipText(), '192.168.1.10');

    await pick('No Address');
    expect(ipText(), '');
  });
}
