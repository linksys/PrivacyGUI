import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_port_range_tab.dart'
    show UspPortRangeTab;
import 'package:privacy_gui/page/port_forwarding/views/components/usp_port_triggering_tab.dart'
    show UspPortTriggeringTab;
import 'package:privacy_gui/page/port_forwarding/views/components/usp_single_port_tab.dart'
    show UspSinglePortTab;
import 'package:privacy_gui/page/port_forwarding/views/usp_port_forwarding_detail_view.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppIconButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_port_forwarding.dart';
import '../fixtures/port_forwarding_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'port_forwarding',
      view: () => const UspPortForwardingDetailView(),
      shell: ShellType.custom,
      states: {
        'single_port_rules': (overrides) => overrides.addAll(
              portForwardingOverrides(dataState()),
            ),
        'empty_single_port': (overrides) => overrides.addAll(
              portForwardingOverrides(emptyDataState),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              portForwardingOverrides(dirtyState()),
            ),
      },
      interactions: {
        // --- Tab views ---
        'tab_port_range': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(1));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'tab_port_triggering': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(2));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        // --- Empty tab views ---
        'empty_port_range': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(emptyDataState),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(1));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'empty_port_triggering': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(emptyDataState),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(2));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        // --- Add dialogs ---
        'dialog_add_single_port': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            final addBtn = find.descendant(
              of: find.byType(UspSinglePortTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_add_port_range': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(1));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            final addBtn = find.descendant(
              of: find.byType(UspPortRangeTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'dialog_add_port_triggering': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(2));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            final addBtn = find.descendant(
              of: find.byType(UspPortTriggeringTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        // --- Edit dialogs ---
        // Each tab's row has 3 AppIconButtons: [add(in header), edit, delete]
        // For edit: skip first (add), take second per rule row
        'dialog_edit_single_port': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            final buttons = find.descendant(
              of: find.byType(UspSinglePortTab),
              matching: find.byType(AppIconButton),
            );
            // buttons: [0]=add, [1]=edit(row1), [2]=delete(row1), [3]=edit(row2), [4]=delete(row2)
            await tester.tap(buttons.at(1));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_edit_port_range': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(1));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            final buttons = find.descendant(
              of: find.byType(UspPortRangeTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(buttons.at(1));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'dialog_edit_port_triggering': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(2));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            final buttons = find.descendant(
              of: find.byType(UspPortTriggeringTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(buttons.at(1));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        // --- Delete confirmation dialog ---
        'dialog_delete': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            final buttons = find.descendant(
              of: find.byType(UspSinglePortTab),
              matching: find.byType(AppIconButton),
            );
            // [0]=add, [1]=edit(row1), [2]=delete(row1)
            await tester.tap(buttons.at(2));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        // --- Validation errors in dialogs ---
        'dialog_validation_single_port': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            final addBtn = find.descendant(
              of: find.byType(UspSinglePortTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            // Single port dialog has 4 fields (desc, extPort, intPort, client)
            final allFields = find.byType(EditableText);
            final count = allFields.evaluate().length;
            if (count < 4) return;
            final baseIndex = count - 4;
            // Description — over 32 chars
            await tester.tap(allFields.at(baseIndex));
            await tester.pump();
            tester.testTextInput.enterText('x' * 33);
            await tester.pump();
            // External port — out of range
            await tester.tap(allFields.at(baseIndex + 1));
            await tester.pump();
            tester.testTextInput.enterText('99999');
            await tester.pump();
            // Internal port — out of range
            await tester.tap(allFields.at(baseIndex + 2));
            await tester.pump();
            tester.testTextInput.enterText('0');
            await tester.pump();
            // Internal client — invalid IP
            await tester.tap(allFields.at(baseIndex + 3));
            await tester.pump();
            tester.testTextInput.enterText('not-an-ip');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
          },
        ),
        'dialog_validation_port_range': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(1));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            final addBtn = find.descendant(
              of: find.byType(UspPortRangeTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            // Find all EditableText on screen
            final allFields = find.byType(EditableText);
            final count = allFields.evaluate().length;
            if (count < 5) return;
            // Port range dialog has 5 fields (desc, extStart, extEnd, intPort, client)
            final baseIndex = count - 5;
            // Description — over 32 chars
            await tester.tap(allFields.at(baseIndex));
            await tester.pump();
            tester.testTextInput.enterText('x' * 33);
            await tester.pump();
            // External port start — out of range
            await tester.tap(allFields.at(baseIndex + 1));
            await tester.pump();
            tester.testTextInput.enterText('99999');
            await tester.pump();
            // External port end — less than start
            await tester.tap(allFields.at(baseIndex + 2));
            await tester.pump();
            tester.testTextInput.enterText('1');
            await tester.pump();
            // Internal port — out of range
            await tester.tap(allFields.at(baseIndex + 3));
            await tester.pump();
            tester.testTextInput.enterText('0');
            await tester.pump();
            // Internal client — invalid IP
            await tester.tap(allFields.at(baseIndex + 4));
            await tester.pump();
            tester.testTextInput.enterText('not-an-ip');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
          },
        ),
      },
    ),
  );
}
