import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/port_forwarding_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The single-port dialog's target address is checked as every form that writes a
/// LAN host's address checks it (#1838), through the same shared rule as the
/// port-range dialog.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

Future<void> _open(WidgetTester tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showAppDialog<void>(
                  context: context,
                  builder: (_) => const PortForwardingDialog(
                    lanIp: '192.168.1.1',
                    lanSubnetMask: '255.255.255.0',
                  ),
                ),
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
}

/// The target address field: the dialog's `AppTextFormField` labelled with
/// the IP address string (the other one is the description).
Finder _clientField() => find.byWidgetPredicate(
    (w) => w is AppTextFormField && w.label == _l10nEn.ipAddress);

final _l10nEn = lookupAppLocalizations(const Locale('en'));

Future<void> _enterClient(WidgetTester tester, String text) async {
  await tester.enterText(
      find.descendant(of: _clientField(), matching: find.byType(TextField)),
      text);
  await tester.pumpAndSettle();
  // The dialog validates on blur, as a user tabbing away.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l10n;
  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  String? clientError(WidgetTester tester) =>
      tester.widget<AppTextFormField>(_clientField()).externalErrorText;

  testWidgets('0.0.0.0 is refused as reserved', (tester) async {
    await _open(tester);
    await _enterClient(tester, '0.0.0.0');

    expect(clientError(tester), l10n.reservedIpNotAllowed);
  });

  testWidgets('an address outside the LAN is refused', (tester) async {
    await _open(tester);
    await _enterClient(tester, '10.0.0.5');

    expect(clientError(tester), l10n.invalidIpAddress);
  });

  testWidgets('a malformed address is a format error', (tester) async {
    await _open(tester);
    await _enterClient(tester, '192.168.1');

    expect(clientError(tester), l10n.invalidIpv4Format);
  });

  testWidgets('a LAN host is accepted', (tester) async {
    await _open(tester);
    await _enterClient(tester, '192.168.1.50');

    expect(clientError(tester), isNull);
  });
}
