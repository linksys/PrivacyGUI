import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/support/views/usp_support_view.dart';

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
            await tester.tap(find.text('Setup'));
            await tester.pump();
            await tester.tap(find.text('Connectivity'));
            await tester.pump();
            await tester.tap(find.text('Speed'));
            await tester.pump();
            await tester.tap(find.text('Password & Access'));
            await tester.pump();
            await tester.tap(find.text('Hardware'));
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
