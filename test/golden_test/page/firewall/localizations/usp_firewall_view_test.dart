import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_firewall.dart';
import '../../../../mocks/test_data/scenes/firewall_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'firewall',
      view: () => const UspFirewallView(),
      shell: ShellType.custom,
      height: 1400,
      states: {
        'all_on': (overrides) => overrides.addAll(
              firewallOverrides(dataState(allOnModel)),
            ),
        'all_off': (overrides) => overrides.addAll(
              firewallOverrides(dataState(allOffModel)),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              firewallOverrides(dirtyState()),
            ),
        // A router missing one rule: that switch is locked (#1611).
        'missing_rule': (overrides) => overrides.addAll(
              firewallOverrides(missingNatRuleState),
            ),
        // What a router with no named rule gets instead of fabricated
        // switches (#1611).
        'error': (overrides) => overrides.addAll(
              firewallOverrides(errorState),
            ),
      },
    ),
  );
}
