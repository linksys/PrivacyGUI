import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/dhcp/views/dialogs/dhcp_reservation_edit_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/provider_overrides/mock_dhcp.dart';
import '../../../../mocks/test_data/scenes/dhcp_scene_data.dart';
import 'dhcp_card_test_harness.dart';

/// The DHCP page's reservation card reads the LAN before it opens the dialog
/// and passes it in, so the dialog checks the address as a LAN host (#1838).
void main() {
  Finder ipField() => find.byWidgetPredicate(
      (w) => w is AppTextField && w.identifier == 'dhcp-reservation-ip');

  Future<void> pumpCard(WidgetTester tester, {bool lanReadable = true}) =>
      pumpDhcpCard(
        tester,
        UspDhcpReservationsDetailCard(reservations: testReservations),
        overrides: dhcpDetailOverrides(
          reservationState: dataState(),
          lanInfo: testLanInfo,
          clients: testClients,
          lanReadable: lanReadable,
        ),
      );

  Future<void> enterOutsideIp(WidgetTester tester) async {
    expect(find.byType(DhcpReservationEditDialog), findsOneWidget);
    await tester.enterText(
        find.descendant(of: ipField(), matching: find.byType(TextField)),
        '10.0.0.5');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  testWidgets('an address outside the LAN is flagged in the add dialog',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpCard(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await enterOutsideIp(tester);

    expect(tester.widget<AppTextField>(ipField()).errorText,
        l10n.invalidIpAddress);
  });

  testWidgets('and in the edit dialog', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpCard(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    await enterOutsideIp(tester);

    expect(tester.widget<AppTextField>(ipField()).errorText,
        l10n.invalidIpAddress);
  });

  testWidgets('a LAN that cannot be read opens no dialog', (tester) async {
    await pumpCard(tester, lanReadable: false);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(DhcpReservationEditDialog), findsNothing);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    expect(find.byType(DhcpReservationEditDialog), findsNothing);
  });
}
