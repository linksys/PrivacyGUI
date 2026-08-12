import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_active_leases_card.dart';

import '../../../../golden_test/page/dhcp/fixtures/dhcp_test_data.dart';
import 'dhcp_card_test_harness.dart';

/// Widget tests for [UspDhcpActiveLeasesCard] mobile layout (#1140).
///
/// Regression coverage: the lease row used two fixed `context.colWidth(2)`
/// boxes, which are sized against the *page* grid (216dp each on a 4-column
/// mobile grid) rather than the row's own 398dp of usable width. That starved
/// the name/MAC `Expanded` down to zero width — wrapping one character per
/// line — and overflowed the Row.
///
/// `flutter_test_config.dart` in this directory loads the shipped fonts, so the
/// measurements below reflect what users see. Without it Flutter's built-in test
/// font applies and is ~1.8x wider, which reports text as truncated when it is
/// not.
void main() {
  group('UspDhcpActiveLeasesCard - mobile row layout', () {
    /// The row's last child, so it is what an overflow pushes past the edge.
    Finder leaseTextOf(DhcpClientUIModel client) =>
        find.text(client.leaseExpiryFormatted);

    testWidgets('lease rows do not overflow at mobile width', (tester) async {
      await pumpDhcpCard(
        tester,
        UspDhcpActiveLeasesCard(clients: testClients),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'lease row Row must fit within the mobile content width',
      );
    });

    testWidgets('device name and MAC each render on a single line',
        (tester) async {
      await pumpDhcpCard(
        tester,
        UspDhcpActiveLeasesCard(clients: testClients),
      );
      expect(tester.takeException(), isNull);

      // The bug stacked every character vertically, making these hundreds of
      // dp tall.
      expect(
        tester.getSize(find.text('iPhone-15-Pro')).height,
        lessThan(singleLineMaxHeight),
        reason: 'device name must stay on one line, not wrap per character',
      );
      expect(
        tester.getSize(find.text('AA:BB:CC:DD:EE:01')).height,
        lessThan(singleLineMaxHeight),
        reason: 'MAC address must stay on one line, not wrap per character',
      );
    });

    testWidgets('lease column stays within its own row bounds', (tester) async {
      await pumpDhcpCard(
        tester,
        UspDhcpActiveLeasesCard(clients: testClients),
      );
      expect(tester.takeException(), isNull);

      // Bind the text to its own row rather than assuming display order: the
      // card re-sorts rows (online first, then by display name), so indexing
      // LayoutBlock and the fixture list independently only lines up by
      // coincidence.
      final leaseText = leaseTextOf(testClients.first);
      final row = find.ancestor(
        of: leaseText,
        matching: find.byType(LayoutBlock),
      );
      expect(row, findsOneWidget);

      expect(
        tester.getRect(leaseText).right,
        lessThanOrEqualTo(tester.getRect(row).right),
        reason: 'lease column must not be clipped off the right edge',
      );
    });

    testWidgets('a long device name ellipsises instead of wrapping',
        (tester) async {
      // #1140 accepts truncation with an ellipsis; what it rules out is
      // wrapping (one character per line) and overflowing the row. A name
      // wider than its column is the case most likely to regress.
      final client = DhcpClientUIModel(
        mac: 'AA:BB:CC:DD:EE:09',
        ip: '192.168.1.109',
        leaseActive: true,
        isOnline: true,
        hostName: 'Peters-MacBook-Pro-16-inch-2023',
        leaseExpiry: DateTime.now().add(const Duration(hours: 12)),
      );

      await pumpDhcpCard(
        tester,
        UspDhcpActiveLeasesCard(clients: [client]),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'an over-long name must not overflow the row',
      );

      final name = find.text(client.hostName);
      final paragraph = tester.renderObject<RenderParagraph>(name);
      expect(
        paragraph.didExceedMaxLines,
        isTrue,
        reason: 'this name is wider than its column, so it should ellipsise — '
            'if it now fits, the fixture no longer covers the truncation path',
      );
      expect(
        tester.getSize(name).height,
        lessThan(singleLineMaxHeight),
        reason: 'ellipsised text must stay on one line',
      );

      final row = find.ancestor(of: name, matching: find.byType(LayoutBlock));
      expect(
        tester.getRect(name).right,
        lessThanOrEqualTo(tester.getRect(row).right),
        reason: 'ellipsised text must stay inside the row',
      );
    });
  });
}
