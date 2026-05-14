import 'package:privacy_gui/page/port_forwarding/views/usp_port_forwarding_detail_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_port_forwarding.dart';
import '../fixtures/port_forwarding_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'port_forwarding_detail',
      view: () => const UspPortForwardingDetailView(),
      shell: ShellType.custom,
      states: {
        'data': (overrides) => overrides.addAll(
              portForwardingOverrides(dataState()),
            ),
        'data_empty': (overrides) => overrides.addAll(
              portForwardingOverrides(emptyDataState),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              portForwardingOverrides(dirtyState()),
            ),
        'saving': (overrides) => overrides.addAll(
              portForwardingOverrides(dirtyState(isSaving: true)),
            ),
      },
    ),
  );
}
