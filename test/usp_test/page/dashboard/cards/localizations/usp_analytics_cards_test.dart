import 'package:flutter/material.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_device_analytics_card.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_network_health_card.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_stats_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_system_status_card.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_traffic_analysis_card.dart';
import 'package:privacy_gui/page/firewall/cards/usp_firewall_overview_card.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_performance_card.dart';

import '../../../../golden_framework/golden_runner.dart';
import '../../../../golden_framework/golden_test_config.dart';
import '../../../../golden_framework/mocks/mock_dashboard_cards.dart';
import '../fixtures/cards_test_data.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // UspStatsPanel
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_stats_panel',
      view: () => const UspStatsPanel(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('800x120', Size(800, 120))],
      states: {
        'summary': (overrides) => overrides.addAll(
              cardOverrides(
                devicesData: testDevicesData,
                ethernetData: testEthernetData,
                wifiData: testWifiData,
                portForwardingData: testPortForwardingData,
                portTriggeringData: testPortTriggeringData,
              ),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspSystemStatusCard — Monitor tab (default)
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_system_status',
      view: () => const UspSystemStatusCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('500x400', Size(500, 400))],
      states: {
        'monitor_with_data': (overrides) => overrides.addAll(
              cardOverrides(
                systemInfoData: testSystemInfoData,
                systemMonitorState: testSystemMonitorWithHistory,
              ),
            ),
        'monitor_empty': (overrides) => overrides.addAll(
              cardOverrides(
                systemInfoData: testSystemInfoData,
                systemMonitorState: testSystemMonitorEmpty,
              ),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspTrafficAnalysisCard — Monitor tab (default)
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_traffic_analysis',
      view: () => const UspTrafficAnalysisCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('500x400', Size(500, 400))],
      states: {
        'monitor_with_data': (overrides) => overrides.addAll(
              cardOverrides(trafficAnalysisState: testTrafficWithHistory),
            ),
        'empty': (overrides) => overrides.addAll(
              cardOverrides(trafficAnalysisState: testTrafficEmpty),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspDeviceAnalyticsCard — Distribution tab (default)
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_device_analytics',
      view: () => const UspDeviceAnalyticsCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('500x400', Size(500, 400))],
      states: {
        'distribution_with_data': (overrides) => overrides.addAll(
              cardOverrides(deviceAnalyticsState: testDeviceAnalyticsWithData),
            ),
        'empty': (overrides) => overrides.addAll(
              cardOverrides(deviceAnalyticsState: testDeviceAnalyticsEmpty),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspNetworkHealthCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_network_health',
      view: () => const UspNetworkHealthCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('500x400', Size(500, 400))],
      states: {
        'health_with_data': (overrides) => overrides.addAll(
              cardOverrides(trafficAnalysisState: testTrafficWithHistory),
            ),
        'empty': (overrides) => overrides.addAll(
              cardOverrides(trafficAnalysisState: testTrafficEmpty),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspWifiPerformanceCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_wifi_performance',
      view: () => const UspWifiPerformanceCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('500x400', Size(500, 400))],
      states: {
        'signal_with_clients': (overrides) => overrides.addAll(
              cardOverrides(
                wifiData: testWifiData,
                devicesData: testDevicesData,
              ),
            ),
        'empty': (overrides) => overrides.addAll(
              cardOverrides(
                wifiData: testWifiEmptyData,
                devicesData: testDevicesEmptyData,
              ),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspFirewallOverviewCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_firewall_overview',
      view: () => const UspFirewallOverviewCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('500x400', Size(500, 400))],
      states: {
        'rules_with_data': (overrides) => overrides.addAll(
              cardOverrides(
                firewallData: testFirewallData,
                portForwardingData: testPortForwardingData,
              ),
            ),
        'empty': (overrides) => overrides.addAll(
              cardOverrides(
                firewallData: testFirewallEmptyData,
                portForwardingData: testPortForwardingEmptyData,
              ),
            ),
      },
    ),
  );
}
