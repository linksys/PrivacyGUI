import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';

import '../../../mocks/provider_overrides/mock_wan_data.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';
import '../../../util/overflow_probe.dart';

/// linksys/PrivacyGUI#1702 — the Network Status card's DNS row.
///
/// Pumped through the production factory (`network_status`), with only the WAN
/// model swapped, so what is measured is the card a user sees.
void main() {
  const wan = WanStatusUIModel(
    isUp: true,
    ipAddress: '203.0.113.1',
    subnetMask: '255.255.255.0',
    addressingType: 'PPTP',
    mtu: 1460,
    gateway: '172.16.0.1',
    dnsServers: ['203.0.113.53', '198.51.100.53'],
  );

  Future<List<Object>> pump(WidgetTester tester, WanStatusUIModel model) =>
      runWithOverflowCollection((incidents) async {
        await setLayoutSurface(tester, const Size(1280, 800));
        await tester.pumpWidget(buildDashboardCardApp(
          cardId: 'network_status',
          locale: const Locale('en'),
          screenWidth: 1280,
          cardWidth: 600,
          cardHeight: 600,
          extraOverrides: [wanDataOverride(model)],
        ));
        await settleIgnoringAnimations(tester);
        return incidents;
      });

  testWidgets('shows the DNS servers in use as one row', (tester) async {
    final incidents = await pump(tester, wan);

    expect(find.text('DNS SERVERS'), findsOneWidget);
    expect(find.text('203.0.113.53, 198.51.100.53'), findsOneWidget);
    // The rest of the card is unchanged around it.
    expect(find.text('172.16.0.1'), findsOneWidget);
    expect(find.textContaining('PPTP'), findsOneWidget);
    expect(incidents, isEmpty);
  });

  testWidgets('an empty DNS list hides the row', (tester) async {
    const noDns = WanStatusUIModel(
      isUp: true,
      ipAddress: '203.0.113.1',
      subnetMask: '255.255.255.0',
      addressingType: 'DHCP',
      mtu: 1500,
      gateway: '203.0.113.254',
    );
    await pump(tester, noDns);

    expect(find.text('DNS SERVERS'), findsNothing);
    // The card itself still renders in full.
    expect(find.text('203.0.113.254'), findsOneWidget);
    expect(find.text('255.255.255.0'), findsOneWidget);
  });
}
