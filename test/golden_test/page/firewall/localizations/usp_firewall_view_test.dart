import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_firewall.dart';
import '../fixtures/firewall_test_data.dart';

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
      },
    ),
  );
}
