import 'package:privacy_gui/page/local_network/views/usp_local_network_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_local_network.dart';
import '../fixtures/local_network_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'local_network',
      view: () => const UspLocalNetworkView(),
      shell: ShellType.custom,
      states: {
        'data': (overrides) => overrides.addAll(
              localNetworkOverrides(dataState(dhcpEnabledModel)),
            ),
        'data_dhcp_disabled': (overrides) => overrides.addAll(
              localNetworkOverrides(dataState(dhcpDisabledModel)),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              localNetworkOverrides(dirtyState()),
            ),
        'saving': (overrides) => overrides.addAll(
              localNetworkOverrides(dirtyState(isSaving: true)),
            ),
        'validation_error': (overrides) => overrides.addAll(
              localNetworkOverrides(validationErrorState),
            ),
      },
    ),
  );
}
