// Untagged (not `ui`) so `run_tests.sh`, and with it CI's Unit Tests job, runs
// this suite: it is AC2's guard inside the dialog (linksys/PrivacyGUI#1698).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/dhcp/views/dialogs/dhcp_reservation_edit_dialog.dart';

/// The reservation name field of [DhcpReservationEditDialog]
/// (linksys/PrivacyGUI#1698): FW's rule is checked before anything is sent,
/// and the name comes back with the MAC and IP on submit.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

final _existing = [
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.4.StaticAddress.5.',
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.10',
    enable: true,
    name: 'living-room-tv',
  ),
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.4.StaticAddress.6.',
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.11',
    enable: true,
  ),
];

class _Opened {
  DhcpReservationDialogResult? result;
  bool popped = false;
}

Future<_Opened> _open(WidgetTester tester,
    {DhcpReservationUIModel? reservation}) async {
  final opened = _Opened();
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                opened.result =
                    await showAppDialog<DhcpReservationDialogResult>(
                  context: context,
                  builder: (_) => DhcpReservationEditDialog(
                    reservation: reservation,
                    existingReservations: _existing,
                  ),
                );
                opened.popped = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  ]);
  await tester.pumpWidget(MaterialApp.router(
    theme: _testTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return opened;
}

/// Fields in dialog order: MAC (0), IP (1), name (2).
AppTextField _field(int i) =>
    find.byType(AppTextField).evaluate().elementAt(i).widget as AppTextField;

Future<void> _enter(WidgetTester tester, int i, String text) async {
  await tester.enterText(find.byType(TextField).at(i), text);
  await tester.pumpAndSettle();
  // The dialog validates on blur.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;

  setUp(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> fillAddress(WidgetTester tester) async {
    await _enter(tester, 0, 'AA:BB:CC:DD:EE:99');
    await _enter(tester, 1, '192.168.1.99');
  }

  for (final (name, message) in [
    ('-tv', 'reservationNameInvalid'),
    ('tv-', 'reservationNameInvalid'),
    ('living room', 'reservationNameInvalid'),
    ('tv_1', 'reservationNameInvalid'),
    ('a' * 64, 'maxCharacters'),
    ('living-room-tv', 'reservationNameInUse'),
  ]) {
    testWidgets(
        '"${name.length > 20 ? '64 characters' : name}" is stopped '
        'before it is sent', (tester) async {
      final opened = await _open(tester);
      await fillAddress(tester);
      await _enter(tester, 2, name);

      expect(
        _field(2).errorText,
        switch (message) {
          'reservationNameInvalid' => l.reservationNameInvalid,
          'reservationNameInUse' => l.reservationNameInUse,
          _ => l.maxCharacters(63),
        },
      );
      await tester.tap(find.widgetWithText(AppButton, l.add));
      await tester.pumpAndSettle();
      expect(opened.popped, isFalse, reason: 'Add must stay disabled');
      expect(find.byType(DhcpReservationEditDialog), findsOneWidget);
    });
  }

  testWidgets('a valid name is returned with the address', (tester) async {
    final opened = await _open(tester);
    await fillAddress(tester);
    await _enter(tester, 2, 'Printer-2');

    expect(_field(2).errorText, isNull);
    await tester.tap(find.widgetWithText(AppButton, l.add));
    await tester.pumpAndSettle();

    expect(opened.result, (
      mac: 'AA:BB:CC:DD:EE:99',
      ip: '192.168.1.99',
      enable: true,
      name: 'Printer-2'
    ));
  });

  testWidgets('no name is accepted and returned as empty', (tester) async {
    final opened = await _open(tester);
    await fillAddress(tester);

    await tester.tap(find.widgetWithText(AppButton, l.add));
    await tester.pumpAndSettle();

    expect(opened.result?.name, '');
  });

  testWidgets('editing pre-fills the name and keeps it as its own',
      (tester) async {
    final opened = await _open(tester, reservation: _existing[0]);

    expect(find.text('living-room-tv'), findsOneWidget);
    // Re-validate: its own name is not "in use".
    await _enter(tester, 2, 'living-room-tv');
    expect(_field(2).errorText, isNull);

    await tester.tap(find.widgetWithText(AppButton, l.save));
    await tester.pumpAndSettle();
    expect(opened.result?.name, 'living-room-tv');
  });

  testWidgets('an existing reservation without a name still saves',
      (tester) async {
    final opened = await _open(tester, reservation: _existing[1]);
    await _enter(tester, 1, '192.168.1.12');

    await tester.tap(find.widgetWithText(AppButton, l.save));
    await tester.pumpAndSettle();

    expect(opened.result,
        (mac: 'AA:BB:CC:DD:EE:02', ip: '192.168.1.12', enable: true, name: ''));
  });
}
