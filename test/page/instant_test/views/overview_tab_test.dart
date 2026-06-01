import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/views/overview_tab.dart';

import '../../../mocks/mock_instant_test_notifier.dart';
import '../../../mocks/test_data/instant_test_state_data.dart';

Widget _wrap(InstantTestState state) {
  return ProviderScope(
    overrides: [
      instantTestProvider.overrideWith(
          () => MockInstantTestNotifier(state)),
    ],
    child: const MaterialApp(home: Scaffold(body: OverviewTab())),
  );
}

void main() {
  group('OverviewTab — idle state', () {
    testWidgets('shows Run button when idle', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.idleState()));
      expect(find.text('Run Instant Test'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('OverviewTab — loading state', () {
    testWidgets('shows spinner when loading', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.loadingState()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('OverviewTab — all-clear state', () {
    testWidgets('shows all-checks-passed text', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.allClearState()));
      await tester.pump();
      expect(find.text('All checks passed'), findsOneWidget);
    });

    testWidgets('shows checksRun count', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.allClearState()));
      await tester.pump();
      final state = InstantTestStateData.allClearState();
      expect(find.textContaining('${state.verdict!.checksRun} checks run'),
          findsOneWidget);
    });
  });

  group('OverviewTab — WAN disconnected state', () {
    testWidgets('shows critical finding headline', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.wanDisconnectedState()));
      await tester.pump();
      expect(find.textContaining('internet'), findsWidgets);
    });
  });
}
