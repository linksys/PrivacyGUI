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
import '../../../../mocks/provider_overrides/mock_port_forwarding.dart';
import '../../../../mocks/test_data/scenes/port_forwarding_scene_data.dart';

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
            await switchToTab(tester, 1);
          },
        ),
        'tab_port_triggering': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await switchToTab(tester, 2);
          },
        ),
        // --- Empty tab views ---
        'empty_port_range': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(emptyDataState),
          ),
          steps: (tester) async {
            await switchToTab(tester, 1);
          },
        ),
        'empty_port_triggering': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(emptyDataState),
          ),
          steps: (tester) async {
            await switchToTab(tester, 2);
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
            await settleWithTimeout(tester);
          },
        ),
        'dialog_add_port_range': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await switchToTab(tester, 1);
            final addBtn = find.descendant(
              of: find.byType(UspPortRangeTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await settleWithTimeout(tester);
          },
        ),
        'dialog_add_port_triggering': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await switchToTab(tester, 2);
            final addBtn = find.descendant(
              of: find.byType(UspPortTriggeringTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await settleWithTimeout(tester);
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
            await settleWithTimeout(tester);
          },
        ),
        'dialog_edit_port_range': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await switchToTab(tester, 1);
            final buttons = find.descendant(
              of: find.byType(UspPortRangeTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(buttons.at(1));
            await settleWithTimeout(tester);
          },
        ),
        'dialog_edit_port_triggering': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: (tester) async {
            await switchToTab(tester, 2);
            final buttons = find.descendant(
              of: find.byType(UspPortTriggeringTab),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(buttons.at(1));
            await settleWithTimeout(tester);
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
            await settleWithTimeout(tester);
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
            await settleWithTimeout(tester);
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
          steps: withSemantics((tester) async {
            await switchToTab(tester, 1);
            await tapAdd(tester, 'pf-add-port-range');
            // By identifier: the dialog lost its internal port field (#1080),
            // so a positional index would type into the wrong box.
            await typeInto(tester, 'pf-range-description', 'x' * 33);
            await typeInto(tester, 'pf-range-external-port-start', '99999');
            await typeInto(tester, 'pf-range-external-port-end', '1');
            await typeInto(tester, 'pf-range-internal-ip', 'not-an-ip');
            await tester.pump(const Duration(milliseconds: 100));
          }),
        ),
        // --- FWDEV#204 checks the router no longer refuses on Add ---
        // A range over the scene's HTTP single port (80, TCP), and the router's
        // own address as the destination.
        'dialog_overlap_and_lan_host_port_range': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: withSemantics((tester) async {
            await switchToTab(tester, 1);
            await tapAdd(tester, 'pf-add-port-range');
            await typeInto(tester, 'pf-range-external-port-start', '70');
            await typeInto(tester, 'pf-range-external-port-end', '90');
            await typeInto(tester, 'pf-range-internal-ip', '192.168.1.1');
            await typeInto(tester, 'pf-range-description', 'Overlap');
            await tester.pump(const Duration(milliseconds: 100));
          }),
        ),
        'dialog_overlap_port_triggering': Interaction(
          setup: (overrides) => overrides.addAll(
            portForwardingOverrides(dataState()),
          ),
          steps: withSemantics((tester) async {
            await switchToTab(tester, 2);
            await tapAdd(tester, 'pf-add-port-triggering');
            // 21 is the scene's FTP trigger.
            await typeInto(tester, 'pf-trigger-trigger-port-start', '21');
            await typeInto(tester, 'pf-trigger-forward-port-start', '60000');
            await typeInto(tester, 'pf-trigger-description', 'Overlap');
            await tester.pump(const Duration(milliseconds: 100));
          }),
        ),
        // --- Every list at its FWDEV#204 limit: Add disabled, reason shown ---
        'full_single_port': Interaction(
          setup: (overrides) =>
              overrides.addAll(portForwardingOverrides(fullDataState)),
          steps: (tester) async {},
        ),
        'full_port_range': Interaction(
          setup: (overrides) =>
              overrides.addAll(portForwardingOverrides(fullDataState)),
          steps: (tester) async => switchToTab(tester, 1),
        ),
        'full_port_triggering': Interaction(
          setup: (overrides) =>
              overrides.addAll(portForwardingOverrides(fullDataState)),
          steps: (tester) async => switchToTab(tester, 2),
        ),
      },
    ),
  );
}
