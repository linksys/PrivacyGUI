import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_instant_safety.dart';
import '../../../../mocks/test_data/scenes/instant_safety_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'instant_safety',
      view: () => const UspInstantSafetyView(),
      shell: ShellType.custom,
      states: {
        'enabled': (overrides) => overrides.addAll(
              instantSafetyOverrides(enabledState()),
            ),
        'disabled': (overrides) => overrides.addAll(
              instantSafetyOverrides(disabledState()),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              instantSafetyOverrides(dirtyState()),
            ),
      },
    ),
  );
}
