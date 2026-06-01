import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/views/my_network_tab.dart';

import '../../../mocks/mock_instant_test_notifier.dart';
import '../../../mocks/test_data/instant_test_state_data.dart';

Widget _wrap(InstantTestState state) {
  return ProviderScope(
    overrides: [
      instantTestProvider.overrideWith(
          () => MockInstantTestNotifier(state)),
    ],
    child: const MaterialApp(home: Scaffold(body: MyNetworkTab())),
  );
}

void main() {
  group('MyNetworkTab — WAN connected', () {
    testWidgets('shows Connected status', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.allClearState()));
      await tester.pump();
      expect(find.text('Connected · 98.137.11.163'), findsOneWidget);
    });
  });

  group('MyNetworkTab — WAN disconnected', () {
    testWidgets('shows Not connected status', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.wanDisconnectedState()));
      await tester.pump();
      expect(find.text('Not connected'), findsOneWidget);
    });
  });

  group('MyNetworkTab — idle (no WAN)', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.idleState()));
      expect(find.byType(MyNetworkTab), findsOneWidget);
    });
  });
}
