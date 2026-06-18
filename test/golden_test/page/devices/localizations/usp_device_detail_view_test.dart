import 'package:privacy_gui/page/devices/views/usp_device_detail_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_devices.dart';
import '../fixtures/devices_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'device_detail',
      view: () => const UspDeviceDetailView(mac: 'AA:BB:CC:DD:EE:01'),
      shell: ShellType.custom,
      height: 1200,
      states: {
        'wifi_with_reservation': (overrides) => overrides.addAll(
              deviceDetailOverrides(
                detail: wifiDetailWithReservation,
                reservations: [testReservation],
              ),
            ),
        'wifi_no_reservation': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: wifiDetailNoReservation),
            ),
        'wired_device': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: wiredDetail),
            ),
        'offline_device': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: offlineDetail),
            ),
        'not_found': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: deviceNotFound),
            ),
      },
    ),
  );
}
