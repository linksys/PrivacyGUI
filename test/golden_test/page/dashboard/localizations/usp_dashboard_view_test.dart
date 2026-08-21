import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/views/components/dashboard_header_bar.dart';
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
            // Reach Edit the way a user does at this device's width. The header
            // collapses below 601px (#1314), so on `phone480` the edit action
            // lives in the overflow menu and only the menu trigger is on screen;
            // on `desktop1280` it is still a button of its own. Scoped to the
            // header because the cards have `more_vert` triggers of their own.
            if (find.byIcon(Icons.edit).evaluate().isEmpty) {
              await tester.tap(find.descendant(
                of: find.byType(DashboardHeaderBar),
                matching: find.byIcon(Icons.more_vert),
              ));
              await tester.pumpAndSettle();
            }
            await tester.tap(find.byIcon(Icons.edit));
            await tester.pump();
            await tester.pump();
            await tester.pump();
            // Pump past max random delay (50ms) + one full JiggleShake
            // cycle (140ms forward + 140ms reverse = 280ms) so all cards
            // return to their resting position deterministically.
            //
            // On the collapsed path it does a second job: `PopupMenuRoute`
            // reverses over 300ms, and Material invokes `onSelected` as soon as
            // the pop starts, so this is also what gets the menu off the frame
            // before the screenshot. 330 > 300 holds today — if the jiggle
            // window above is ever tuned down, settle the menu explicitly
            // instead of shrinking this.
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
