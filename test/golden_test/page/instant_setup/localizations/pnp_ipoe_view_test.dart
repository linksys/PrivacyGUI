import 'package:privacy_gui/page/instant_setup/views/pnp_ipoe_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_auto_ipoe.dart';
import '../../internet_settings/fixtures/auto_ipoe_golden_scenes.dart';

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
                pageState: ipoeGoldenPageState(ipoeReadySnapshot),
                submission: null,
              ),
            ),
        'in_progress': (overrides) => overrides.addAll(
              autoIPoEOverrides(
                snapshot: ipoeInProgressSnapshot,
                pageState: ipoeGoldenPageState(ipoeInProgressSnapshot),
                submission: ipoeInProgressSubmission,
              ),
            ),
      },
    ),
  );
}
