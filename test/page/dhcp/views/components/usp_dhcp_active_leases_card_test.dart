@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_active_leases_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

/// Widget tests for [UspDhcpActiveLeasesCard] mobile layout (#1140).
///
/// Regression coverage: the lease row used two fixed `context.colWidth(2)`
/// boxes, which are sized against the *page* grid (216dp each on a 4-column
/// mobile grid) rather than the row's own 400dp of usable width. That starved
/// the name/MAC `Expanded` down to zero width — wrapping one character per
/// line — and overflowed the Row by ~50dp.
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
        child: MaterialApp(
          theme: _testTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: _phoneContentWidth,
                child: UspDhcpActiveLeasesCard(clients: testClients),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lease rows do not overflow at mobile width', (tester) async {
    await pumpCard(tester);

    expect(
      tester.takeException(),
      isNull,
      reason: 'lease row Row must fit within the mobile content width',
    );
  });

  testWidgets('device name and MAC each render on a single line',
      (tester) async {
    await pumpCard(tester);
    tester.takeException(); // overflow is asserted by the test above

    // A single line of bodyMedium/bodySmall is well under 40dp tall; the bug
    // stacked every character vertically, making these hundreds of dp tall.
    final nameSize = tester.getSize(find.text('iPhone-15-Pro'));
    expect(
      nameSize.height,
      lessThan(40),
      reason: 'device name must stay on one line, not wrap per character',
    );

    final macSize = tester.getSize(find.text('AA:BB:CC:DD:EE:01'));
    expect(
      macSize.height,
      lessThan(40),
      reason: 'MAC address must stay on one line, not wrap per character',
    );
  });

  testWidgets('lease column stays within the row bounds', (tester) async {
    await pumpCard(tester);
    tester.takeException(); // overflow is asserted by the first test

    // The lease column is the row's last child, so it is what the overflow
    // pushed past the right edge and clipped.
    final blockRight = tester.getRect(find.byType(LayoutBlock).first).right;
    final expiryRight =
        tester.getRect(find.text(testClients.first.leaseExpiryFormatted)).right;
    expect(
      expiryRight,
      lessThanOrEqualTo(blockRight),
      reason: 'lease column must not be clipped off the right edge',
    );
  });
}
