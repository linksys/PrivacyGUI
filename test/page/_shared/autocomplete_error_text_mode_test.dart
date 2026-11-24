import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/port_forwarding_dialog.dart';
import 'package:privacy_gui/page/dhcp/views/dialogs/dhcp_reservation_edit_dialog.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/dialogs/ipv6_port_service_rule_dialog.dart';
import 'package:privacy_gui/page/port_forwarding/views/dialogs/port_range_forwarding_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The address fields that offer a device list (`AppSelectAutoComplete`) show
/// their errors as text, not as a tooltip (linksys/PrivacyGUI#1829).
///
/// On web, on Flutter 3.47.2, a tooltip-mode field that shows an error loses
/// focus when it is clicked again, and a second click gives it a caret but the
/// keys never reach it (linksys/privacyGUI-UI-kit#100). #1829 did not
/// reproduce it on these fields on Flutter 3.50.0. It needs a browser with
/// semantics on, so a widget test cannot reproduce it; these tests hold each
/// field to the setting that avoids it (`AppErrorDisplayMode.text`).
///
/// Each test reads every [AppTextField] under an [AppSelectAutoComplete] in
/// one dialog, so a device-list field added to that dialog later is checked
/// too. The other two `AppSelectAutoComplete` sites in `lib/` are covered
/// elsewhere: `usp_dmz_view_suggestions_test.dart` holds the DMZ field to text
/// mode, and `mac_filter_add_device_dialog_focus_test.dart` checks that the
/// MAC filter field keeps its place in the semantics tree while typing.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Opens [dialog] through `showAppDialog` in a `MaterialApp.router` host, the
/// way the app shows it.
Future<void> _open(WidgetTester tester, Widget dialog) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showAppDialog<void>(
                    context: context, builder: (_) => dialog),
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

/// Every field under a device list in the open dialog, in dialog order, as
/// its E2E identifier and how it shows an error.
List<(String?, AppErrorDisplayMode)> _deviceListFields(WidgetTester tester) =>
    tester
        .widgetList<AppTextField>(find.descendant(
          of: find.byType(AppSelectAutoComplete),
          matching: find.byType(AppTextField),
        ))
        .map((field) => (field.identifier, field.errorDisplayMode))
        .toList();

void main() {
  group('the device-list fields show their errors as text', () {
    testWidgets('in the single port forwarding dialog', (tester) async {
      await _open(
          tester, const PortForwardingDialog(lanIp: null, lanSubnetMask: null));

      expect(_deviceListFields(tester), [
        ('pf-single-internal-ip', AppErrorDisplayMode.text),
      ]);
    });

    testWidgets('in the port range forwarding dialog', (tester) async {
      await _open(tester,
          const PortRangeForwardingDialog(lanIp: null, lanSubnetMask: null));

      expect(_deviceListFields(tester), [
        ('pf-range-internal-ip', AppErrorDisplayMode.text),
      ]);
    });

    testWidgets('in the DHCP reservation dialog', (tester) async {
      await _open(
          tester,
          const DhcpReservationEditDialog(
              lanIp: null, lanSubnetMask: null, existingReservations: []));

      expect(_deviceListFields(tester), [
        ('dhcp-reservation-mac', AppErrorDisplayMode.text),
        ('dhcp-reservation-ip', AppErrorDisplayMode.text),
      ]);
    });

    testWidgets('in the IPv6 port service rule dialog', (tester) async {
      await _open(tester, const Ipv6PortServiceRuleDialog());

      expect(_deviceListFields(tester), [
        ('ipv6-rule-address', AppErrorDisplayMode.text),
      ]);
    });
  });
}
