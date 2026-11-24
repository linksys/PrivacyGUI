import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_port_mapping_section.dart';

import '../../../../mocks/provider_overrides/mock_statistics.dart';
import '../../../../mocks/test_data/firewall_test_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/statistics/stats_section_probe.dart';

/// The Port Mapping section's DMZ row names the DMZ host (#1775).
///
/// A host given by MAC leaves the router's DestIP empty. The row used to show
/// that IP, so a DMZ set by MAC read "Target: " with nothing after it.
void main() {
  setUpAll(() async {
    // Real fonts: the second assertion is about the row fitting.
    await loadAppFonts();
  });

  const mac = 'AA:BB:CC:DD:EE:01';

  testWidgets(
      'a DMZ host given by MAC is the row\'s target, and fits on the '
      'narrowest screen', (tester) async {
    final incidents = await probeSectionOverflow(
      tester,
      section: const StatsPortMappingSection(),
      screenWidth: narrowStatsScreens.last,
      locale: const Locale('en'),
      overrides: statisticsOverrides(
        firewallData: FirewallTestData.createFirewallData(dmzSummaries: const [
          DmzEntrySummary(enable: true, destIp: '', destMac: mac),
        ]),
      ),
    );

    expect(find.text('Target: $mac'), findsOneWidget);
    expect(incidents, isEmpty,
        reason: 'a MAC is longer than an IP; the row must still fit');
  });
}
