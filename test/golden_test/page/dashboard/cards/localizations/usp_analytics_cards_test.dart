import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_device_analytics_card.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_network_health_card.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_stats_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_system_status_card.dart';
import 'package:privacy_gui/page/dashboard/views/components/usp_traffic_analysis_card.dart';
import 'package:privacy_gui/page/firewall/cards/usp_firewall_overview_card.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_performance_card.dart';

import '../../../../golden_framework/golden_runner.dart';
import '../../../../golden_framework/golden_test_config.dart';
import '../../../../../mocks/provider_overrides/mock_dashboard_cards.dart';
import '../../../../../mocks/test_data/scenes/cards_scene_data.dart';

/// The WiFi Performance card's tabs are Signal, Speed, Channels.
const _channelsTab = 2;

Override _wifiPerformanceTab(int index) =>
    cardTabIndexProvider('wifi_performance').overrideWith((ref) => index);

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
        // The Channels tab, which prints each radio's channel in use (#1782).
        // The tab is provider state, so it is pinned rather than tapped.
        'channels_tab': (overrides) => overrides.addAll([
              ...cardOverrides(
                wifiData: testWifiData,
                devicesData: testDevicesData,
              ),
              _wifiPerformanceTab(_channelsTab),
            ]),
        // No channel in use read: "Channel --", never the configured one.
        'channels_tab_in_use_unknown': (overrides) => overrides.addAll([
              ...cardOverrides(
                wifiData: testWifiChannelInUseUnknownData,
                devicesData: testDevicesData,
              ),
              _wifiPerformanceTab(_channelsTab),
            ]),
        // Channel utilization (#1295): the 5 GHz radio reports none, so its
        // row reads "Channel utilization: —" under a 2.4 GHz row that reports
        // a percent. (`channels_tab` above has a reading on both.)
        'channels_tab_utilization_unknown': (overrides) => overrides.addAll([
              ...cardOverrides(
                wifiData: testWifiUtilizationUnknownData,
                devicesData: testDevicesData,
              ),
              _wifiPerformanceTab(_channelsTab),
            ]),
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
