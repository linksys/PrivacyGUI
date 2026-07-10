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
/// The dialog surfaces validation errors via the two [AppTextField]s'
/// `errorText`. AppTextField renders that error inline OR as a focus tooltip
/// depending on layout/focus state, so these tests assert on the widget's
/// `errorText` property (the source of truth) rather than a rendered string,
/// which is both more robust and independent of ui_kit rendering internals.
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
}

Future<void> _enterIp(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).at(1), text);
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
}
