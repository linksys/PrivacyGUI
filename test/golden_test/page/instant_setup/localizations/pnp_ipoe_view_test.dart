import 'package:privacy_gui/page/instant_setup/views/pnp_ipoe_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_auto_ipoe.dart';
import '../../../../mocks/test_data/scenes/auto_ipoe_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'pnp_ipoe',
      view: () => const PnpIPoEView(),
      shell: ShellType.custom,
      states: {
        'ready': (overrides) => overrides.addAll(
              autoIPoEOverrides(
                snapshot: ipoeReadySnapshot,
                pageState: ipoeReadyPageState,
                submission: null,
              ),
            ),
        'in_progress': (overrides) => overrides.addAll(
              autoIPoEOverrides(
                snapshot: ipoeInProgressSnapshot,
                pageState: ipoeInProgressPageState,
                submission: ipoeSubmission,
              ),
            ),
      },
    ),
  );
}
