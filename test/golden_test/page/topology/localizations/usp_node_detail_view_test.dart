import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_topology.dart';
import '../../../../mocks/test_data/scenes/topology_scene_data.dart';

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
        // Backhaul reporting a PHY rate and a last-contact time, the pair the
        // card's bottom row is built for (`usp_node_detail_view.dart:429`) — no
        // other state here sets either field, which is why #1302's report never
        // saw that row. Visual coverage only, and partial: at phone480 the row
        // is captured whole, while at desktop1280 the card sits low enough that
        // only the caption line falls above the 800px fold. The overflow itself
        // is gated by
        // `test/page/topology/views/usp_node_detail_backhaul_overflow_test.dart`,
        // which sweeps 320/1241/1280 — none of them widths this suite renders
        // by default.
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
