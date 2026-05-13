import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
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
      states: {
        'loading': (overrides) => overrides.addAll(
          firewallOverrides(FirewallFeatureState.initial()),
        ),
        'error': (overrides) => overrides.addAll(
          firewallOverrides(errorState),
        ),
        'data': (overrides) => overrides.addAll(
          firewallOverrides(dataState(allOnModel)),
        ),
        'data_all_off': (overrides) => overrides.addAll(
          firewallOverrides(dataState(allOffModel)),
        ),
        'edit_dirty': (overrides) => overrides.addAll(
          firewallOverrides(dirtyState()),
        ),
        'saving': (overrides) => overrides.addAll(
          firewallOverrides(dirtyState(isSaving: true)),
        ),
      },
    ),
  );
}
