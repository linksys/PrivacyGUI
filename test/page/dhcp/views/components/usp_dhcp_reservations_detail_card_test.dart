import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';

import '../../../../mocks/provider_overrides/mock_dhcp.dart';
import '../../../../mocks/test_data/scenes/dhcp_scene_data.dart';
import 'dhcp_card_test_harness.dart';

/// Widget tests for [UspDhcpReservationsDetailCard] mobile layout (#1140).
///
/// Regression coverage: the reservation row sized its IP column with a fixed
/// `context.colWidth(2)` box — 216dp against the 4-column mobile page grid —
/// which left the MAC `Expanded` too narrow to fit one line, wrapping the MAC
/// into one octet per line.
///
/// `flutter_test_config.dart` in this directory loads the shipped fonts, so the
/// measurements below reflect what users see. Without it Flutter's built-in test
/// font applies and is ~1.8x wider, which reports text as truncated when it is
/// not.
void main() {
  group('UspDhcpReservationsDetailCard - mobile row layout', () {
    Future<void> pumpCard(WidgetTester tester) => pumpDhcpCard(
          tester,
          UspDhcpReservationsDetailCard(reservations: testReservations),
          overrides: dhcpDetailOverrides(
            reservationState: dataState(),
            lanInfo: testLanInfo,
            clients: testClients,
          ),
        );

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
      expect(tester.takeException(), isNull);

      // A single line of bodyMedium is well under 40dp tall; the bug stacked
      // one MAC octet per line, making this ~6 lines tall.
      expect(
        tester.getSize(find.text('AA:BB:CC:DD:EE:01')).height,
        lessThan(singleLineMaxHeight),
        reason: 'MAC must stay on one line, not wrap one octet per line',
      );
    });

    testWidgets('MAC address is not ellipsised at mobile width',
        (tester) async {
      await pumpCard(tester);
      expect(tester.takeException(), isNull);

      // The MAC is the row's only device identifier, so ellipsising it (e.g.
      // "AA:BB:CC:DD:EE:...") would make two reservations indistinguishable.
      // Stacking the MAC over the IP gives the text column the row's whole
      // flexible width — ~130dp of text in ~230dp of space at mobile width.
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

    testWidgets('each MAC stays within its own row bounds', (tester) async {
      await pumpCard(tester);
      expect(tester.takeException(), isNull);

      // Bind each text to its own row instead of indexing LayoutBlock and the
      // fixture list independently, which would only line up by coincidence.
      for (final reservation in testReservations) {
        final mac = find.text(reservation.mac);
        final row = find.ancestor(of: mac, matching: find.byType(LayoutBlock));
        expect(row, findsOneWidget);

        expect(
          tester.getRect(mac).right,
          lessThanOrEqualTo(tester.getRect(row).right),
          reason: 'MAC ${reservation.mac} must not be clipped off the edge',
        );
      }
    });
  });
}
