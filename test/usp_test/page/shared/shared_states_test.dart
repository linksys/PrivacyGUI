import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';

import '../../golden_framework/golden_runner.dart';
import '../../golden_framework/golden_test_config.dart';
import '../../golden_framework/mocks/mock_firewall.dart';
import '../firewall/fixtures/firewall_test_data.dart';

/// Shared UI states — captured once to cover common components used
/// by all USP views: AppLoader, error+retry layout, discard changes dialog,
/// saving spinner dialog.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'shared_states',
      view: () => const UspFirewallView(),
      shell: ShellType.custom,
      states: {
        'loading': (overrides) => overrides.addAll(
              firewallOverrides(FirewallFeatureState.initial()),
            ),
        'error': (overrides) => overrides.addAll(
              firewallOverrides(errorState),
            ),
      },
      interactions: {
        'discard_changes_dialog': Interaction(
          setup: (overrides) => overrides.addAll(
            firewallOverrides(dirtyState()),
          ),
          steps: (tester) async {
            final context = tester.element(find.byType(Scaffold));
            showUnsavedAlert(context);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        'saving_spinner': Interaction(
          setup: (overrides) => overrides.addAll(
            firewallOverrides(dirtyState()),
          ),
          steps: (tester) async {
            final context = tester.element(find.byType(Scaffold));
            showAppSpinnerDialog(context);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
      },
    ),
  );
}
