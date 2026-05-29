import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/views/usp_dashboard_view.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/preset_selection_dialog.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_dashboard.dart';

void main() {
  initDashboardSharedPreferences();

  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'dashboard',
      view: () => const UspDashboardView(),
      shell: ShellType.scaffold,
      height: 1800,
      states: {
        'normal': (overrides) => overrides.addAll(dashboardOverrides()),
      },
      interactions: {
        'edit_mode': Interaction(
          setup: (overrides) => overrides.addAll(dashboardOverrides()),
          steps: (tester) async {
            final editButton = find.byIcon(Icons.edit);
            await tester.tap(editButton);
            await tester.pump();
            await tester.pump();
            await tester.pump();
            // Pump past max random delay (50ms) + one full JiggleShake
            // cycle (140ms forward + 140ms reverse = 280ms) so all cards
            // return to their resting position deterministically.
            await tester.pump(const Duration(milliseconds: 330));
          },
        ),
        'preset_dialog': Interaction(
          setup: (overrides) => overrides.addAll(dashboardOverrides()),
          steps: (tester) async {
            final navigator = tester.state<NavigatorState>(
              find.byType(Navigator).last,
            );
            showPresetSelectionDialog(navigator.context);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
      },
    ),
  );
}
