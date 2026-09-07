import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_topology.dart';
import '../../../../mocks/test_data/scenes/topology_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'topology',
      view: () => const UspTopologyView(),
      shell: ShellType.custom,
      height: 1000,
      states: {
        'single_node': (overrides) => overrides.addAll(
              topologyViewOverrides(
                devicesData: singleNodeDevicesData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'mesh_network': (overrides) => overrides.addAll(
              topologyViewOverrides(
                devicesData: meshNetworkDevicesData,
                systemInfoData: testSystemInfoData,
              ),
            ),
      },
    ),
  );
}
