@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/static_routing/views/dialogs/static_route_dialog.dart';

/// Widget tests for [StaticRouteDialog].
///
/// Covers linksys/PrivacyGUI#1332: the Add static route dialog dropped
/// keystrokes because validation ran on EVERY keystroke and assigned the
/// `_errors` map inside `onChanged`. When `_errors` gained an entry the field's
/// `errorText` flipped null -> value, the widget rebuilt, and CanvasKit tore
/// down the semantics `<input>` mid-edit, so focus (and every keystroke after)
/// was lost. The fix moves validation to focus-loss (a FocusNode listener for
/// the plain-text name field, AppIpv4TextField.onFocusChanged for the three
/// IPv4 fields), so `onChanged` only rebuilds to re-gate the Add button and
/// never assigns `_errors` mid-edit — the same focus-loss pattern already used
/// by port_forwarding_dialog / usp_local_network_view / dhcp_reservation_edit.
///
/// The dialog surfaces validation errors via each field's `errorText`. Those
/// render inline OR as a focus tooltip depending on layout/focus state, so
/// these tests assert on the widget's `errorText` property (the source of
/// truth) rather than a rendered string.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Pumps the dialog inside a GoRouter (the dialog calls Navigator.pop) and
/// immediately opens it. Returns the result the dialog pops with (null = still
/// open / cancelled).
Future<StaticRouteDialogResult?> _pumpAndOpen(
  WidgetTester tester, {
  String? lanIp = '192.168.1.1',
  String? lanSubnetMask = '255.255.255.0',
}) async {
  StaticRouteDialogResult? result;
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
                  result = await showAppDialog<StaticRouteDialogResult>(
                    context: context,
                    builder: (_) => StaticRouteDialog(
                      lanIp: lanIp,
                      lanSubnetMask: lanSubnetMask,
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

/// The dialog's four text fields.
// AppTextField is the single plain-text field in the dialog (the route name).
AppTextField _nameField() =>
    find.byType(AppTextField).evaluate().first.widget as AppTextField;

// The three AppIpv4TextFields are ordered: dest (0), subnet (1), gateway (2).
AppIpv4TextField _ipv4At(int i) =>
    find.byType(AppIpv4TextField).evaluate().elementAt(i).widget
        as AppIpv4TextField;

AppIpv4TextField _destField() => _ipv4At(0);
AppIpv4TextField _subnetField() => _ipv4At(1);
AppIpv4TextField _gatewayField() => _ipv4At(2);

/// Enters [text] into the name field. Does NOT drop focus, so this mirrors the
/// user still typing — used to assert the #1332 no-mid-edit-error property.
Future<void> _typeName(WidgetTester tester, String text) async {
  await tester.enterText(_nameTextField(), text);
  await tester.pumpAndSettle();
}

/// The raw name TextField (first TextField in tree — the AppIpv4TextFields
/// render their own TextFields after it).
Finder _nameTextField() => find.byType(TextField).first;

Future<void> _blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

/// Enters [text] into one octet box of the gateway field WITHOUT dropping focus,
/// mirroring a user mid-typing. The dialog's TextFields are ordered: the name
/// field first, then each AppIpv4TextField's four octet boxes in field order
/// (dest, subnet, gateway) — so gateway octet [octet] is at
/// 1 + (2 * 4) + octet. Asserted against the field count rather than hardcoded
/// so a layout change fails loudly instead of silently typing into the wrong box.
Future<void> _typeGatewayOctet(
  WidgetTester tester,
  int octet,
  String text,
) async {
  final boxes = find.byType(TextField);
  expect(
    boxes.evaluate().length,
    1 + 3 * 4,
    reason: 'expected the name field plus three IPv4 fields of four octets; '
        'if this changed, the octet index below is wrong',
  );
  await tester.enterText(boxes.at(1 + 2 * 4 + octet), text);
  await tester.pumpAndSettle();
}

void main() {
  late String addLabel;

  setUp(() async {
    final loc = await AppLocalizations.delegate.load(const Locale('en'));
    addLabel = loc.add;
  });

  group('StaticRouteDialog #1332 focus-loss validation', () {
    testWidgets('add-open shows no errors on any field (empty form)',
        (tester) async {
      await _pumpAndOpen(tester);

      expect(_nameField().errorText, isNull);
      expect(_destField().errorText, isNull);
      expect(_subnetField().errorText, isNull);
      expect(_gatewayField().errorText, isNull);
    });

    testWidgets(
        'typing an invalid name does NOT set errorText mid-edit (#1332): '
        'onChanged must not assign _errors while still focused',
        (tester) async {
      await _pumpAndOpen(tester);

      // A 33+ char name is invalid (nameTooLong), but while the field is still
      // focused (user typing) the error must NOT appear — assigning it would
      // rebuild and tear down the CanvasKit <input>, dropping keystrokes.
      await _typeName(tester, 'x' * 40);

      expect(_nameField().errorText, isNull,
          reason: 'onChanged must not assign _errors mid-edit (#1332)');
    });

    testWidgets('name error surfaces only after the field loses focus',
        (tester) async {
      await _pumpAndOpen(tester);
      await _typeName(tester, 'x' * 40); // invalid: too long
      expect(_nameField().errorText, isNull); // still typing -> no error yet

      await _blur(tester); // tab away -> validation runs

      expect(_nameField().errorText, isNotNull,
          reason: 'validation runs on focus-loss');
    });

    testWidgets('Add stays disabled while the form is incomplete/invalid',
        (tester) async {
      await _pumpAndOpen(tester);
      await _typeName(tester, 'e2e-route');
      await _blur(tester);

      // Dest/subnet/gateway are still empty -> form invalid -> Add disabled ->
      // tapping does not pop the dialog.
      await tester.tap(find.widgetWithText(AppButton, addLabel));
      await tester.pumpAndSettle();
      expect(find.byType(StaticRouteDialog), findsOneWidget);
    });

    // Review round 1 flagged that gateway — the field #1332 actually reproduces
    // on (typed 192, landed 1/19) — had no focus-loss coverage: it was only
    // asserted null on open. These two cover the AppIpv4TextField
    // onFocusChanged path that the name field's FocusNode listener does not.
    testWidgets(
        'typing an invalid gateway does NOT set errorText mid-edit (#1332): '
        'the octet path must not assign _errors while still focused',
        (tester) async {
      await _pumpAndOpen(tester);
      // A bare "1" is not a valid address and is outside the LAN subnet, so it
      // is exactly the transiently-invalid state that used to flip errorText on
      // the first keystroke and tear the <input> down mid-edit.
      await _typeGatewayOctet(tester, 0, '1');

      expect(_gatewayField().errorText, isNull,
          reason: 'still focused mid-edit -> onChanged must not assign _errors');
    });

    testWidgets('gateway error surfaces only after the IPv4 field loses focus',
        (tester) async {
      await _pumpAndOpen(tester);
      await _typeGatewayOctet(tester, 0, '1');
      expect(_gatewayField().errorText, isNull); // still typing -> no error yet

      await _blur(tester); // whole IPv4 field blurs -> validation runs

      expect(_gatewayField().errorText, isNotNull,
          reason: 'validation runs when the entire IPv4 field loses focus');
    });
  });
}
