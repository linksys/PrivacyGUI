import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/views/help_me_fix_it_tab.dart';

import '../../../mocks/mock_instant_test_notifier.dart';
import '../../../mocks/test_data/instant_test_state_data.dart';

Widget _wrap(InstantTestState state) {
  return ProviderScope(
    overrides: [
      instantTestProvider.overrideWith(
          () => MockInstantTestNotifier(state)),
    ],
    child: const MaterialApp(home: Scaffold(body: HelpMeFixItTab())),
  );
}

void main() {
  group('HelpMeFixItTab — no issues', () {
    testWidgets('shows no-issues message when all-clear', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.allClearState()));
      await tester.pump();
      expect(find.text('No issues found that need attention.'), findsOneWidget);
    });
  });

  group('HelpMeFixItTab — WAN disconnected (has action)', () {
    testWidgets('shows no action finding for WAN disconnect (no actionKey)',
        (tester) async {
      // WAN disconnect has no actionKey on the finding — no button shown
      await tester.pumpWidget(_wrap(InstantTestStateData.wanDisconnectedState()));
      await tester.pump();
      // HelpMeFixItTab only shows findings with actionKey
      // WAN disconnect finding has no actionKey → shows "no issues" message
      expect(find.text('No issues found that need attention.'), findsOneWidget);
    });
  });

  group('HelpMeFixItTab — renders without crash', () {
    testWidgets('idle state renders', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.idleState()));
      expect(find.byType(HelpMeFixItTab), findsOneWidget);
    });
  });
}
