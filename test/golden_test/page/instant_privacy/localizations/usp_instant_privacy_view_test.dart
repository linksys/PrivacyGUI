import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_instant_privacy.dart';
import '../fixtures/instant_privacy_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'instant_privacy',
      view: () => const InstantPrivacyView(),
      shell: ShellType.custom,
      height: 1200,
      states: {
        'disabled_with_devices': (overrides) => overrides.addAll(
              instantPrivacyOverrides(disabledWithDevicesState),
            ),
        'disabled_empty': (overrides) => overrides.addAll(
              instantPrivacyOverrides(disabledEmptyState),
            ),
        'enabled_with_devices': (overrides) => overrides.addAll(
              instantPrivacyOverrides(enabledWithDevicesState),
            ),
      },
      interactions: {
        'dialog_add_device': Interaction(
          setup: (overrides) => overrides.addAll(
            instantPrivacyOverrides(enabledWithDevicesState),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(AppButton).first);
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
