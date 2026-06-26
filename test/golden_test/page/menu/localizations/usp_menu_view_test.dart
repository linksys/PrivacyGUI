import 'package:privacy_gui/page/menu/views/usp_menu_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_menu.dart';
import '../fixtures/menu_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'menu',
      view: () => const UspMenuView(),
      shell: ShellType.custom,
      height: 1600,
      states: {
        'badges_on': (overrides) => overrides.addAll(
              menuOverrides(
                lanData: menuLanDataBadgesOn,
                privacyState: menuPrivacyOn,
              ),
            ),
        'badges_off': (overrides) => overrides.addAll(
              menuOverrides(
                lanData: menuLanDataBadgesOff,
                privacyState: menuPrivacyOff,
              ),
            ),
      },
    ),
  );
}
