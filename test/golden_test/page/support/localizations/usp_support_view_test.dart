import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/support/views/usp_support_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'support',
      view: () => const UspSupportView(),
      shell: ShellType.custom,
      height: 1800,
      states: {
        'faq_list': (overrides) {},
      },
      interactions: {
        'all_expanded': Interaction(
          setup: (overrides) {},
          steps: (tester) async {
            final panels = find.byType(AppExpansionPanel);
            for (int i = 0; i < panels.evaluate().length; i++) {
              await tester.tap(panels.at(i));
              await tester.pump(const Duration(milliseconds: 100));
            }
          },
        ),
      },
    ),
  );
}
