import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppText;

import '../../golden_framework/golden_runner.dart';
import '../../golden_framework/golden_test_config.dart';

/// The parts of the shared dialog helpers that the helper draws, not its
/// caller (#905).
///
/// Each page's own dialogs, the add, edit and delete forms and their
/// validation, stay in that page's golden: their content is the caller's. What
/// is here is what no page golden can show, either because it is the same for
/// every caller or because no page golden reaches it.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'shared_dialogs',
      view: () => const Scaffold(body: SizedBox.expand()),
      shell: ShellType.custom,
      states: const {},
      interactions: {
        // `showSubmitAppDialog` after its positive button is tapped, with the
        // event still running. The content and both buttons are replaced by
        // the helper's own loader, so this frame is the same for all six
        // callers but the title; the title is the password dialog's.
        'submit_loading': Interaction(
          setup: (overrides) {},
          steps: (tester) async {
            final context = tester.element(find.byType(Scaffold));
            showSubmitAppDialog<void>(
              context,
              title: loc(context).changeRouterPassword,
              contentBuilder: (context, setState, onSubmit) =>
                  AppText.bodyMedium(loc(context).newPassword),
              event: () => Completer<void>().future,
            );
            await pumpOverlayIn(tester);
            await tester.tap(find.byKey(const Key('alertPositiveButton')));
            await tester.pump();
          },
        ),
        // `showListSelectionDialog`, the speed test's server picker, as both of
        // its callers open it: the full server list, the current one marked.
        'list_selection': Interaction(
          setup: (overrides) {},
          steps: (tester) async {
            final context = tester.element(find.byType(Scaffold));
            showListSelectionDialog<SpeedTestServer>(
              context: context,
              title: loc(context).selectTestServer,
              items: SpeedTestServer.all,
              itemLabel: (server) => server.name,
              currentValue: SpeedTestServer.all.first,
              itemIcon: Icons.dns,
            );
            await pumpOverlayIn(tester);
          },
        ),
      },
    ),
  );
}
