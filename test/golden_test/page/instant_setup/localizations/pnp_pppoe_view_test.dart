import 'package:privacy_gui/page/instant_setup/models/troubleshooting_phase.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_pppoe_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_internet_troubleshooting.dart';
import '../../../../mocks/test_data/scenes/pnp_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'pnp_pppoe',
      view: () => const PnpPppoeView(),
      shell: ShellType.custom,
      states: {
        'prefilled_with_vlan': (overrides) => overrides.addAll(
              internetTroubleshootingOverrides(
                wanPrefill: pnpCurrentWanSettings,
              ),
            ),
        'prefilled_without_vlan': (overrides) => overrides.addAll(
              internetTroubleshootingOverrides(wanPrefill: pnpWanWithoutVlan),
            ),
        'empty': (overrides) => overrides.addAll(
              internetTroubleshootingOverrides(),
            ),
        'validation_error': (overrides) => overrides.addAll(
              internetTroubleshootingOverrides(
                wanPrefill: pnpWanVlanIdOutOfRange,
              ),
            ),
        'saving': (overrides) => overrides.addAll(
              internetTroubleshootingOverrides(
                phase: const IspSaving(step: IspSaveStep.saving),
              ),
            ),
        'checking_settings': (overrides) => overrides.addAll(
              internetTroubleshootingOverrides(
                phase: const IspSaving(step: IspSaveStep.checkingSettings),
              ),
            ),
        'checking_internet': (overrides) => overrides.addAll(
              internetTroubleshootingOverrides(
                phase: const IspSaving(step: IspSaveStep.checkingInternet),
              ),
            ),
      },
    ),
  );
}
