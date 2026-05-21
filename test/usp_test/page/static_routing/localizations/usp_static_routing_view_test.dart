import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/static_routing/views/usp_static_routing_view.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppIconButton;

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_static_routing.dart';
import '../fixtures/static_routing_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'static_routing',
      view: () => const UspStaticRoutingView(),
      shell: ShellType.custom,
      states: {
        'routes_list': (overrides) => overrides.addAll(
              staticRoutingOverrides(dataState([route1, route2])),
            ),
        'empty': (overrides) => overrides.addAll(
              staticRoutingOverrides(emptyState()),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              staticRoutingOverrides(dirtyState()),
            ),
      },
      interactions: {
        'dialog_add': Interaction(
          setup: (overrides) => overrides.addAll(
            staticRoutingOverrides(dataState([route1, route2])),
          ),
          steps: (tester) async {
            final addBtn = find.descendant(
              of: find.byType(UspStaticRoutingView),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_edit': Interaction(
          setup: (overrides) => overrides.addAll(
            staticRoutingOverrides(dataState([route1, route2])),
          ),
          steps: (tester) async {
            final buttons = find.descendant(
              of: find.byType(UspStaticRoutingView),
              matching: find.byType(AppIconButton),
            );
            // [0]=add, [1]=edit(row1), [2]=delete(row1), ...
            await tester.tap(buttons.at(1));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'dialog_validation': Interaction(
          setup: (overrides) => overrides.addAll(
            staticRoutingOverrides(dataState([route1, route2])),
          ),
          steps: (tester) async {
            final addBtn = find.descendant(
              of: find.byType(UspStaticRoutingView),
              matching: find.byType(AppIconButton),
            );
            await tester.tap(addBtn.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            final allFields = find.byType(EditableText);
            final count = allFields.evaluate().length;
            if (count < 4) return;
            final baseIndex = count - 4;
            // Name — over 32 chars
            await tester.tap(allFields.at(baseIndex));
            await tester.pump();
            tester.testTextInput.enterText('x' * 33);
            await tester.pump();
            // Dest IP — invalid
            await tester.tap(allFields.at(baseIndex + 1));
            await tester.pump();
            tester.testTextInput.enterText('not-an-ip');
            await tester.pump();
            // Subnet Mask — invalid
            await tester.tap(allFields.at(baseIndex + 2));
            await tester.pump();
            tester.testTextInput.enterText('999.999.999.999');
            await tester.pump();
            // Gateway — invalid
            await tester.tap(allFields.at(baseIndex + 3));
            await tester.pump();
            tester.testTextInput.enterText('bad-gateway');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
          },
        ),
      },
    ),
  );
}
