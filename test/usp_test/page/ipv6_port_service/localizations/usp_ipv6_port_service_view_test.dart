import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/usp_ipv6_port_service_view.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppIconButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_ipv6_port_service.dart';
import '../fixtures/ipv6_port_service_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'ipv6_port_service',
      view: () => const UspIpv6PortServiceView(),
      shell: ShellType.custom,
      height: 1200,
      states: {
        'rules_list': (overrides) => overrides.addAll(
              ipv6PortServiceOverrides(dataState()),
            ),
        'empty': (overrides) => overrides.addAll(
              ipv6PortServiceOverrides(emptyState()),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              ipv6PortServiceOverrides(dirtyState()),
            ),
      },
      interactions: {
        'dialog_add': Interaction(
          setup: (overrides) => overrides.addAll(
            ipv6PortServiceOverrides(dataState()),
          ),
          steps: (tester) async {
            final addBtn = find.byType(AppIconButton);
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_edit': Interaction(
          setup: (overrides) => overrides.addAll(
            ipv6PortServiceOverrides(dataState()),
          ),
          steps: (tester) async {
            final buttons = find.byType(AppIconButton);
            // Button order: [0]=add(header), then per rule card: [1]=edit(rule1), [2]=delete(rule1), ...
            await tester.tap(buttons.at(1));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_validation': Interaction(
          setup: (overrides) => overrides.addAll(
            ipv6PortServiceOverrides(dataState()),
          ),
          steps: (tester) async {
            final addBtn = find.byType(AppIconButton);
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            final fields = find.byType(EditableText);
            final count = fields.evaluate().length;
            if (count < 4) return;
            final baseIndex = count - 4;
            // Description field — enter empty to trigger error on submit attempt
            await tester.tap(fields.at(baseIndex));
            await tester.pump();
            tester.testTextInput.enterText('');
            await tester.pump();
            // IPv6 address field
            await tester.tap(fields.at(baseIndex + 1));
            await tester.pump();
            tester.testTextInput.enterText('invalid-ipv6');
            await tester.pump();
            // Start port field
            await tester.tap(fields.at(baseIndex + 2));
            await tester.pump();
            tester.testTextInput.enterText('99999');
            await tester.pump();
            // End port field
            await tester.tap(fields.at(baseIndex + 3));
            await tester.pump();
            tester.testTextInput.enterText('0');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
          },
        ),
      },
    ),
  );
}
