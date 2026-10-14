import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';

import '../../golden_framework/golden_runner.dart';
import '../../golden_framework/golden_test_config.dart';

/// Shared UI states — captured once to cover common overlay components used
/// by all USP views: AppLoader, discard changes dialog, saving spinner dialog.
/// Uses a minimal Scaffold host so the golden contains only the overlay itself.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'shared_states',
      view: () => const Scaffold(body: SizedBox.expand()),
      shell: ShellType.custom,
      states: {
        'loading': (overrides) {},
      },
      interactions: {
        'discard_changes_dialog': Interaction(
          setup: (overrides) {},
          steps: (tester) async {
            final context = tester.element(find.byType(Scaffold));
            showUnsavedAlert(context);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          },
        ),
        // Through `doSomethingWithSpinner` itself, not `showAppSpinnerDialog`
        // (#905). The lower-level call defaults to no messages, so this golden
        // used to show a spinner no user sees: every one of the 18 call sites
        // goes through `doSomethingWithSpinner`, and none overrides the
        // "Processing..." line it adds. The task is a future that never
        // completes, so the dialog stays up for the capture.
        'saving_spinner': Interaction(
          setup: (overrides) {},
          steps: (tester) async {
            final context = tester.element(find.byType(Scaffold));
            doSomethingWithSpinner(context, Completer<void>().future);
            await pumpOverlayIn(tester);
          },
        ),
      },
    ),
  );
}
