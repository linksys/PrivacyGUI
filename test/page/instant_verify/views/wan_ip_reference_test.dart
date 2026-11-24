import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/wan_ip_comparison.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/wan_ip_history.dart';
import 'package:privacy_gui/page/instant_verify/views/my_network_tab.dart';
import '../../../common/di.dart';
import '../../../common/testable_widget.dart';

class _Notifier extends InstantVerifyPivotNotifier {
  _Notifier(this.initial);
  final InstantVerifyPivotState initial;
  @override
  InstantVerifyPivotState build() => initial;
}

void main() {
  mockDependencyRegister();
  testWidgets('shows both addresses and acknowledgement clears the change',
      (tester) async {
    final storage = <String, String>{};
    final history =
        WanIpHistory(read: (k) => storage[k], write: (k, v) => storage[k] = v);
    history.observe(
        routerMac: 'AA:BB:CC:DD:EE:01',
        currentAddress: '198.51.100.10',
        connected: true);
    final initial = InstantVerifyPivotState(
      phase: PivotLoadPhase.complete,
      wanStatus: const {
        'wanStatus': 'Connected',
        'wanConnection': {'ipAddress': '198.51.100.20'}
      },
      deviceInfo: const {'macAddress': 'AA:BB:CC:DD:EE:01'},
      wanIpComparison: history.observe(
          routerMac: 'AA:BB:CC:DD:EE:01',
          currentAddress: '198.51.100.20',
          connected: true),
    );
    final container = ProviderContainer(overrides: [
      instantVerifyPivotProvider.overrideWith(() => _Notifier(initial)),
      wanIpHistoryProvider.overrideWithValue(history),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
        testableWidget(parent: container, child: const MyNetworkTab()));
    await tester.pumpAndSettle();
    expect(find.text('198.51.100.10'), findsOneWidget);
    expect(find.text('198.51.100.20'), findsOneWidget);
    final acknowledge = find.text('Use current IP as reference');
    await tester.ensureVisible(acknowledge);
    await tester.tap(acknowledge);
    await tester.pumpAndSettle();
    expect(container.read(instantVerifyPivotProvider).wanIpComparison.status,
        WanIpStatus.unchanged);
    expect(find.text('Your WAN IP matches the saved address.'), findsOneWidget);
    expect(find.text('Use current IP as reference'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'first observation explains that a comparison is not yet available',
      (tester) async {
    await tester.pumpWidget(testableWidget(overrides: [
      instantVerifyPivotProvider
          .overrideWith(() => _Notifier(const InstantVerifyPivotState(
                phase: PivotLoadPhase.complete,
                wanStatus: {
                  'wanStatus': 'Connected',
                  'wanConnection': {'ipAddress': '198.51.100.10'}
                },
                wanIpComparison: WanIpComparison(
                    status: WanIpStatus.firstObservation,
                    currentAddress: '198.51.100.10',
                    referenceAddress: '198.51.100.10'),
              ))),
    ], child: const MyNetworkTab()));
    await tester.pumpAndSettle();
    expect(find.text('First address saved. Future checks can detect a change.'),
        findsOneWidget);
    expect(find.text('Use current IP as reference'), findsNothing);
  });
}
