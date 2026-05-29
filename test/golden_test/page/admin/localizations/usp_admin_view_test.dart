import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/admin/views/usp_admin_view.dart';
import 'package:privacy_gui/page/admin/views/components/usp_password_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_system_actions_card.dart';
import 'package:privacy_gui/page/admin/views/components/usp_timezone_card.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppButton, AppIconButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_admin.dart';
import '../fixtures/admin_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'admin',
      view: () => const UspAdminView(),
      shell: ShellType.custom,
      height: 1200,
      states: {
        'data': (overrides) => overrides.addAll(
              adminOverrides(testAdminState),
            ),
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
