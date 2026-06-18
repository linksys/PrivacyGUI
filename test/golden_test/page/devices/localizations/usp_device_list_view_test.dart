import 'package:privacy_gui/page/devices/views/usp_device_list_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_devices.dart';
import '../fixtures/devices_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'device_list',
      view: () => const UspDeviceListView(),
      shell: ShellType.custom,
      height: 1200,
      states: {
        'devices_list': (overrides) => overrides.addAll(
              devicesListOverrides(devices: allDevices),
            ),
        'empty': (overrides) => overrides.addAll(
              devicesListOverrides(devices: []),
            ),
      },
    ),
  );
}
