import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../golden_test/golden_framework/mocks/mock_common.dart';
import '../../golden_test/golden_framework/mocks/mock_dashboard_cards.dart';
import '../../golden_test/page/dashboard/cards/fixtures/cards_test_data.dart';

/// A single "kitchen-sink" override list that feeds *every* dashboard card its
/// with-data fixture at once.
///
/// The per-feature golden tests each override only the one provider their card
/// reads (e.g. `cardOverrides(wifiData: testWifiData)`), because they render one
/// card in isolation. This gate renders all 18 cards from one harness, so it
/// wants a strict superset: fill in every fixture up front. Cards that read
/// providers *not* listed here still build fine — the golden suite proves each
/// card renders without a backend when its own provider is left at default.
///
/// Reuses the golden fixtures verbatim so the overflow gate and the visual
/// goldens exercise the exact same data — no drift between the two.
List<Override> kitchenSinkOverrides() => [
      ...commonOverrides(),
      ...cardOverrides(
        devicesData: testDevicesData,
        systemInfoData: testSystemInfoData,
        timeData: testTimeData,
        wanData: testWanOnlineData,
        lanData: testLanData,
        ethernetData: testEthernetData,
        dhcpData: testDhcpData,
        wifiData: testWifiData,
        portForwardingData: testPortForwardingData,
        portTriggeringData: testPortTriggeringData,
        firewallData: testFirewallData,
        systemMonitorState: testSystemMonitorWithHistory,
        trafficAnalysisState: testTrafficWithHistory,
        deviceAnalyticsState: testDeviceAnalyticsWithData,
      ),
    ];
