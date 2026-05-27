import 'package:privacy_gui/page/dmz/views/usp_dmz_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_dmz.dart';
import '../fixtures/dmz_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'dmz',
      view: () => const UspDmzView(),
      shell: ShellType.custom,
      states: {
        'disabled': (overrides) => overrides.addAll(
              dmzOverrides(dataState(disabledModel)),
            ),
        'enabled': (overrides) => overrides.addAll(
              dmzOverrides(
                dataState(enabledAnyModel,
                    instancePath: 'Device.Firewall.DMZ.1.'),
              ),
            ),
        'enabled_cidr': (overrides) => overrides.addAll(
              dmzOverrides(
                dataState(enabledCidrModel,
                    instancePath: 'Device.Firewall.DMZ.1.'),
              ),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              dmzOverrides(dirtyState()),
            ),
      },
    ),
  );
}
