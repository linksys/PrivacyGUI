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
  // HelpMeFixItTab now shows the FlowMenu qualifier ("What are you running into?")
  // as its landing state — not verdict findings. The old stub behavior is gone.

  group('HelpMeFixItTab — landing state', () {
    testWidgets('shows qualifier question when all-clear', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.allClearState()));
      await tester.pump();
      expect(find.textContaining('What are you running into'), findsOneWidget);
    });

    testWidgets('shows qualifier question when WAN disconnected', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.wanDisconnectedState()));
      await tester.pump();
      expect(find.textContaining('What are you running into'), findsOneWidget);
    });
  });

  group('HelpMeFixItTab — renders without crash', () {
    testWidgets('idle state renders FlowMenu', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.idleState()));
      await tester.pump();
      expect(find.byType(HelpMeFixItTab), findsOneWidget);
      // FlowMenu qualifier is shown
      expect(find.textContaining('What are you running into'), findsOneWidget);
    });
  });
}
