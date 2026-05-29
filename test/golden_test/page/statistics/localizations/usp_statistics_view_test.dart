import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/statistics/views/usp_statistics_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_statistics.dart';
import '../fixtures/statistics_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'statistics',
      view: () => const UspStatisticsView(),
      shell: ShellType.custom,
      height: 4200,
      states: {
        'network_tab': (overrides) => overrides.addAll(
              statisticsOverrides(
                trafficState: testTrafficState,
                firewallData: testFirewallData,
                portForwardingData: testPortForwardingData,
              ),
            ),
        'network_empty': (overrides) => overrides.addAll(
              statisticsOverrides(),
            ),
      },
      interactions: {
        'tab_devices': Interaction(
          setup: (overrides) => overrides.addAll(
            statisticsOverrides(
              deviceAnalyticsState: testDeviceAnalyticsState,
              wifiData: testWifiData,
            ),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(1));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'tab_system': Interaction(
          setup: (overrides) => overrides.addAll(
            statisticsOverrides(
              systemMonitorState: testSystemMonitorState,
              systemInfoData: testSystemInfoData,
              trafficState: testTrafficState,
            ),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(2));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
      },
    ),
  );
}
