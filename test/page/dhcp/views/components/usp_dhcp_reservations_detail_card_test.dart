@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../golden_test/golden_framework/mocks/mock_dhcp.dart';
import '../../../../golden_test/page/dhcp/fixtures/dhcp_test_data.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Mobile viewport used by the golden suite (GoldenDevice.phone480).
const _phoneSize = Size(480, 800);

/// Content width the page grid hands the card at [_phoneSize]:
/// screen 480 minus the page margin (16) on both sides.
const _phoneContentWidth = 448.0;

/// Widget tests for [UspDhcpReservationsDetailCard] mobile layout (#1140).
///
/// Regression coverage: the reservation row sized its IP column with a fixed
/// `context.colWidth(2)` box — 216dp against the 4-column mobile page grid —
/// which left the MAC `Expanded` too narrow to fit one line, wrapping the MAC
/// into one octet per line.
void main() {
  Future<void> pumpCard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(_phoneSize);
    tester.view.physicalSize = _phoneSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: dhcpDetailOverrides(
          reservationState: dataState(),
          lanInfo: testLanInfo,
          clients: testClients,
        ),
        child: MaterialApp(
          theme: _testTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: _phoneContentWidth,
                child: UspDhcpReservationsDetailCard(
                  reservations: testReservations,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reservation rows do not overflow at mobile width',
      (tester) async {
    await pumpCard(tester);

    expect(
      tester.takeException(),
      isNull,
      reason: 'reservation row Row must fit within the mobile content width',
    );
  });

  testWidgets('MAC address renders on a single line', (tester) async {
    await pumpCard(tester);
    tester.takeException(); // overflow is asserted by the test above

    // A single line of bodyMedium is well under 40dp tall; the bug stacked one
    // MAC octet per line, making this ~6 lines tall.
    final macSize = tester.getSize(find.text('AA:BB:CC:DD:EE:01'));
    expect(
      macSize.height,
      lessThan(40),
      reason: 'MAC must stay on one line, not wrap one octet per line',
    );
  });

  testWidgets('MAC address is not ellipsised at mobile width', (tester) async {
    await pumpCard(tester);
    tester.takeException(); // overflow is asserted by the first test

    // The MAC is the row's only device identifier, so ellipsising it (e.g.
    // "AA:BB:CC:DD:EE:...") would make two reservations indistinguishable.
    // A full MAC needs ~238dp and the stacked layout gives the text column the
    // row's whole flexible width, so it fits at mobile width. Narrower hosts
    // (e.g. the desktop two-column split) may still ellipsise, which #1140
    // explicitly accepts — this only guards the mobile case from the report.
    for (final reservation in testReservations) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(reservation.mac),
      );
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: 'MAC ${reservation.mac} must render in full, not ellipsised',
      );
    }
  });
}
