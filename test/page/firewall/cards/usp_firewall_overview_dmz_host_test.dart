import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';

import '../../../mocks/provider_overrides/mock_dashboard_cards.dart';
import '../../../mocks/test_data/firewall_test_data.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';

/// The Firewall Overview card's DMZ row names the DMZ host (#1775).
///
/// A host given by MAC leaves the router's DestIP empty. The row used to show
/// that IP, so a DMZ set by MAC read "Target: " with nothing after it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  const cardId = 'firewall_overview';
  const mac = 'AA:BB:CC:DD:EE:01';
  final constraints = UspWidgetSpecs.all
      .firstWhere((s) => s.id == cardId)
      .getConstraints(DisplayMode.normal);

  testWidgets('a DMZ host given by MAC is the Ports tab\'s DMZ target',
      (tester) async {
    // The DMZ row is drawn only where a rule fits on one line, so a desktop
    // width, at the height the dashboard gives the card.
    final incidents = await probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: CardWidthCase(
        screenWidth: 1440,
        cardWidth: cardWidthAt(1440, constraints.preferredColumns),
        columnSpan: constraints.preferredColumns,
        label: 'desktop',
      ),
      cardHeightRows: constraints.getPreferredHeightCells(),
      tabIndex: 1,
      locale: const Locale('en'),
      extraOverrides: [
        firewallDataProvider.overrideWith(() => FixedFirewallDataNotifier(
              FirewallTestData.createFirewallData(dmzSummaries: const [
                DmzEntrySummary(enable: true, destIp: '', destMac: mac),
              ]),
            )),
      ],
    );

    expect(find.text('Target: $mac'), findsOneWidget);
    expect(incidents.where((i) => i.pixels > 2.0), isEmpty);
  });
}
