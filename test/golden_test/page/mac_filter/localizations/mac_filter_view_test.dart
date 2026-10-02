import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_mac_filter.dart';
import '../../../../mocks/test_data/scenes/mac_filter_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'mac_filter',
      view: () => const UspWifiSettingsView(
          initialTab: UspWifiSettingsView.macFilterTab),
      shell: ShellType.custom,
      height: 1200,
      states: {
        'disabled': (overrides) =>
            overrides.addAll(wifiMacFilterTabOverrides(state: disabledState)),
        'deny_with_devices': (overrides) => overrides
            .addAll(wifiMacFilterTabOverrides(state: denyWithDevicesState)),
        'deny_empty': (overrides) =>
            overrides.addAll(wifiMacFilterTabOverrides(state: denyEmptyState)),
      },
      interactions: {
        'dialog_add_device': Interaction(
          setup: (overrides) => overrides
              .addAll(wifiMacFilterTabOverrides(state: denyWithDevicesState)),
          steps: (tester) async {
            await tester.tap(find.byWidgetPredicate((w) =>
                w is AppButton && w.identifier == 'mac-filter-add-device'));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
      },
    ),
  );
}
