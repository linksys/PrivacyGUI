import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_instant_privacy.dart';
import '../../../../mocks/test_data/scenes/instant_privacy_scene_data.dart';

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
        // #1737: a MAC typed without separators, matching no connected device,
        // so the "Will be added as …" line shows with no suggestion list.
        'dialog_add_device_bare_mac': Interaction(
          setup: (overrides) => overrides.addAll(
            instantPrivacyOverrides(enabledWithDevicesState),
          ),
          steps: (tester) => _openDialogAndType(tester, 'a4c3f0112233'),
        ),
        // No case for the suggestion list a separator-less query opens (#1737):
        // the list is an OverlayEntry, and on the root navigator it lands in
        // the harness's outer app, which has no AppDesignTheme, so it throws
        // here while it renders in the app. Covered by
        // mac_filter_add_device_dialog_mac_forms_test.dart instead.
      },
    ),
  );
}

Future<void> _openDialogAndType(WidgetTester tester, String text) async {
  await tester.tap(find.byWidgetPredicate(
      (w) => w is AppButton && w.identifier == 'instant-privacy-add-device'));
  await tester.pump();
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.tap(find.byType(EditableText));
  await tester.pump();
  tester.testTextInput.enterText(text);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
