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
