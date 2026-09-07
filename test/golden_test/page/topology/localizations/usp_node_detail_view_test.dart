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
      // This page is taller than the 800px default at every width, so the
      // default was cropping it — silently, because both sides of a golden
      // comparison get cropped identically. Content extent measured across all
      // 7 states x 26 locales x 480/1080/1280: 1045px at phone480
      // (`slave_offline`, `vi` — 245px below the fold, and `en` is 1036px),
      // 838px at screen1080, 895px at desktop1280. Only `not_found` fits in 800
      // at every width.
      //
      // #1465's two-chip header is what made this visible, not what caused it.
      // Its wrapped chip pair adds ~28px at desktop1280 in the ten
      // long-translation locales, which was finally enough to carry the diff
      // past `diffThreshold` and file #1482; subtract those 28px and three
      // states are still over the fold, and phone480's 245px is untouched by it.
      //
      // 1200 rather than the measured 1045 because that is what the sibling
      // `usp_device_detail_view_test.dart` uses, and what `detail_view_probe.dart`
      // calls "the height the device-detail goldens use" — the two detail pages
      // are worth photographing on one canvas.
      height: 1200,
      states: {
        'master_with_devices': (overrides) => overrides.addAll(
              nodeDetailOverrides(masterNodeWithDevices),
            ),
        'slave_offline': (overrides) => overrides.addAll(
              nodeDetailOverrides(slaveNodeOffline),
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
        // card's bottom row is built for (`usp_node_detail_view.dart:516`) — no
        // other state here sets either field, which is why #1302's report never
        // saw that row. Visual coverage only: the overflow itself is gated by
        // `test/page/topology/views/usp_node_detail_backhaul_overflow_test.dart`,
        // which sweeps 320/1241/1280 — none of them widths this suite renders
        // by default.
        //
        // And this state is why the `height` above is not cosmetic. Measured on
        // the old 800px surface, the last-contact tile's own rect: it ended at
        // 785-793px at phone480 and screen1080, just inside the frame, but at
        // desktop1280 it ended at 825px with only its caption line above the
        // fold — and after #1465's wrap the caption went under too (`ru`: caption
        // top 817.5px). The row this state exists to photograph had stopped being
        // in the photograph, in the widest layout, in ten locales.
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
