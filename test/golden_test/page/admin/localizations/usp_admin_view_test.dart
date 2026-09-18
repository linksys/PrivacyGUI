import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/page/admin/views/usp_admin_view.dart';
import 'package:privacy_gui/page/admin/views/components/usp_password_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_system_actions_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_timezone_card.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppButton, AppIconButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_admin.dart';
import '../../../../mocks/test_data/scenes/admin_scene_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'admin',
      view: () => const UspAdminView(),
      shell: ShellType.custom,
      height: 1200,
      states: {
        // `adminPageOverrides`, not `adminOverrides`: this is the whole page, and
        // the whole page includes `FirmwareOtaCard`, which reads two providers of
        // its own. Left unpinned the card renders `notAvailable` where the app
        // renders a version, and #1552's auto-update row deletes itself on the
        // failed read — so this golden would show the page as it looked before
        // #1552 and tell its reviewer nothing changed. The four dialog
        // interactions below stay on the narrow list: they are of the modal, not
        // of the card behind it.
        'data': (overrides) => overrides.addAll(
              adminPageOverrides(state: testAdminState),
            ),
        // Remote assistance (#1554 §2). The manual firmware card is gated off in
        // this mode through `surfaceStrategyProvider.firmwareManualEntry` while the
        // OTA card and the router's version line stay — that difference is the
        // entire reason #1549 split one firmware page into two, and until this state
        // existed there was no picture of it in *either* mode. A reviewer comparing
        // this against `data` above is reading the split's whole visual claim.
        //
        // **One override, on the profile, and it has to be the profile.**
        // `surfaceStrategyProvider` reads `appModeProfileProvider.mode` rather than
        // `appModeProvider` precisely so that this single line moves the surfaces as
        // well as the four core causes (see that provider's doc). Assigning
        // `BuildConfig.forceCommandType` is what constitution Article XVII forbids,
        // and it would move neither root.
        'data_remote_assistance': (overrides) => overrides.addAll([
              ...adminPageOverrides(state: testAdminState),
              appModeProfileProvider
                  .overrideWithValue(const RemoteModeProfile()),
            ]),
      },
      interactions: {
        'dialog_timezone': Interaction(
          setup: (overrides) => overrides.addAll(
            adminOverrides(testAdminState),
          ),
          steps: (tester) async {
            final editBtn = find.descendant(
              of: find.byType(UspTimezoneCard),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(editBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            // Expand Advanced section (tap the expand_more icon in the dialog)
            await tester.tap(find.byIcon(Icons.expand_more));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
          },
        ),
        'dialog_password': Interaction(
          setup: (overrides) => overrides.addAll(
            adminOverrides(testAdminState),
          ),
          steps: (tester) async {
            final changeBtn = find.descendant(
              of: find.byType(UspPasswordCard),
              matching: find.byType(AppButton),
            );
            await tester.tap(changeBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_reboot': Interaction(
          setup: (overrides) => overrides.addAll(
            adminOverrides(testAdminState),
          ),
          steps: (tester) async {
            final rebootBtn = find.descendant(
              of: find.byType(UspSystemActionsCard),
              matching: find.byType(AppButton),
            );
            await tester.tap(rebootBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_password_invalid': Interaction(
          setup: (overrides) => overrides.addAll(
            adminOverrides(testAdminState),
          ),
          steps: (tester) async {
            final changeBtn = find.descendant(
              of: find.byType(UspPasswordCard),
              matching: find.byType(AppButton),
            );
            await tester.tap(changeBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            // Enter a short, invalid password to trigger rule failures
            final fields = find.byType(EditableText);
            final count = fields.evaluate().length;
            if (count < 2) return;
            final baseIndex = count - 2;
            // New Password — fails length, uppercase, number, special char
            await tester.tap(fields.at(baseIndex));
            await tester.pump();
            tester.testTextInput.enterText('aaa');
            await tester.pump();
            // Confirm Password — mismatched
            await tester.tap(fields.at(baseIndex + 1));
            await tester.pump();
            tester.testTextInput.enterText('bbb');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
          },
        ),
        'dialog_factory_reset': Interaction(
          setup: (overrides) => overrides.addAll(
            adminOverrides(testAdminState),
          ),
          steps: (tester) async {
            final resetBtn = find.descendant(
              of: find.byType(UspSystemActionsCard),
              matching: find.byType(AppButton),
            );
            await tester.tap(resetBtn.last);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
      },
    ),
  );
}
