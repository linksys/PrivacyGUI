import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/views/my_devices_tab.dart';

import '../../../mocks/mock_instant_test_notifier.dart';
import '../../../mocks/test_data/instant_test_state_data.dart';

Widget _wrap(InstantTestState state) {
  return ProviderScope(
    overrides: [
      instantTestProvider.overrideWith(
          () => MockInstantTestNotifier(state)),
    ],
    child: const MaterialApp(home: Scaffold(body: MyDevicesTab())),
  );
}

void main() {
  group('MyDevicesTab — empty state', () {
    testWidgets('shows no-devices message when empty', (tester) async {
      await tester.pumpWidget(_wrap(InstantTestStateData.idleState()));
      expect(find.text('No connected devices found'), findsOneWidget);
    });
  });

  group('MyDevicesTab — with devices', () {
    testWidgets('shows device hostname', (tester) async {
      final state = InstantTestStateData.allClearState();
      await tester.pumpWidget(_wrap(state));
      await tester.pump();
      // allClearState has one wifi device with hostName 'test-device'
      expect(find.textContaining('test-device'), findsOneWidget);
    });

    testWidgets('shows Good chip for well-connected device', (tester) async {
      final state = InstantTestStateData.allClearState();
      await tester.pumpWidget(_wrap(state));
      await tester.pump();
      expect(find.text('Good'), findsOneWidget);
    });
  });
}
