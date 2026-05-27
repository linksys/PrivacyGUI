import 'package:privacy_gui/page/advanced_settings/views/usp_advanced_settings_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'advanced_settings',
      view: () => const UspAdvancedSettingsView(),
      shell: ShellType.custom,
      states: {
        'menu': (overrides) {},
      },
    ),
  );
}
