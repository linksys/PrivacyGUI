import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_topology.dart';
import '../fixtures/topology_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'node_detail',
      view: () => const UspNodeDetailView(deviceId: '11:22:33:44:55:66'),
      shell: ShellType.custom,
      states: {
        'master_with_devices': (overrides) => overrides.addAll(
              nodeDetailOverrides(masterNodeWithDevices),
            ),
        'slave_with_devices': (overrides) => overrides.addAll(
              nodeDetailOverrides(slaveNodeWithDevices),
            ),
        // LAN IPv6 global address — rendered without a scope badge.
        'global_ipv6': (overrides) => overrides.addAll(
              nodeDetailOverrides(slaveNodeGlobalIpv6),
            ),
        // LAN IPv6 link-local only — leading icon swapped for a scope badge.
        'link_local_ipv6': (overrides) => overrides.addAll(
              nodeDetailOverrides(slaveNodeLinkLocalIpv6),
            ),
        // Backhaul reporting a PHY rate and a last-contact time — the only
        // state that renders the card's bottom row, which is why that row's
        // overflow was missing from the #1302 baseline report.
        'slave_backhaul_timing': (overrides) => overrides.addAll(
              nodeDetailOverrides(slaveNodeWithBackhaulTiming),
            ),
        'empty_devices': (overrides) => overrides.addAll(
              nodeDetailOverrides(masterNodeEmptyDevices),
            ),
        'not_found': (overrides) => overrides.addAll(
              nodeDetailOverrides(nodeNotFoundState),
            ),
      },
    ),
  );
}
