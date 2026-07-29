import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_flow.dart';

import '../../../mocks/pnp_notifier_mocks.dart' as Mock;

/// Minimal host that mixes in [PnpAutoMasterFlowMixin] so the flow state machine
/// can be driven directly, without booting the ISP-save view or any animation.
class _FlowHost extends ConsumerStatefulWidget {
  const _FlowHost({super.key, required this.waitForRunningFirst});

  final bool waitForRunningFirst;

  @override
  ConsumerState<_FlowHost> createState() => _FlowHostState();
}

class _FlowHostState extends ConsumerState<_FlowHost>
    with PnpAutoMasterFlowMixin<_FlowHost> {
  // Records the order of lifecycle callbacks for assertions.
  final List<String> events = [];

  Future<AutoMasterFlowResult> run() {
    return runAutoMasterFlow(
      waitForRunningFirst: widget.waitForRunningFirst,
      onEnterWaiting: () => events.add('enter'),
      onShowConnectionError: () => events.add('error'),
      onExitWaiting: () => events.add('exit'),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  late Mock.MockPnpNotifier mockPnpNotifier;

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    when(mockPnpNotifier.build()).thenReturn(const PnpState(deviceInfo: null));
  });

  // Mounts the host and drives the flow to completion on the real event loop
  // (runAsync) so the stream/future chain fully drains. Returns the flow result
  // together with the host state (for callback-order assertions).
  Future<({AutoMasterFlowResult result, _FlowHostState state})> pumpFlow(
    WidgetTester tester, {
    required bool waitForRunningFirst,
  }) async {
    final key = GlobalKey<_FlowHostState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
        child: _FlowHost(key: key, waitForRunningFirst: waitForRunningFirst),
      ),
    );
    final state = key.currentState!;
    final result = await tester.runAsync(() => state.run());
    await tester.pumpAndSettle();
    return (result: result!, state: state);
  }

  group('PnpAutoMasterFlowMixin - waitForRunningFirst (WAN-up / Phase A)', () {
    testWidgets('Running then Complete -> completed', (tester) async {
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.complete));

      final r = await pumpFlow(tester, waitForRunningFirst: true);

      expect(r.result, AutoMasterFlowResult.completed);
      expect(r.state.events, ['enter', 'exit']);
    });

    testWidgets('Complete during Phase A (missed Running edge) -> completed',
        (tester) async {
      // make-Master finished so fast Phase A sees Complete directly.
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.complete));

      final r = await pumpFlow(tester, waitForRunningFirst: true);

      expect(r.result, AutoMasterFlowResult.completed);
      verifyNever(mockPnpNotifier.pollAutoMasterStatus());
    });

    testWidgets('Failed during Phase A -> proceed', (tester) async {
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.failed));

      final r = await pumpFlow(tester, waitForRunningFirst: true);

      expect(r.result, AutoMasterFlowResult.proceed);
      expect(r.state.events, ['enter', 'exit']);
    });

    testWidgets('Idle only then stream closes (timeout) -> proceed',
        (tester) async {
      // Never starts; session already proven alive upstream, so no reconnect
      // test is attempted.
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.idle));

      final r = await pumpFlow(tester, waitForRunningFirst: true);

      expect(r.result, AutoMasterFlowResult.proceed);
      verifyNever(mockPnpNotifier.testConnectionReconnected());
    });
  });

  group('PnpAutoMasterFlowMixin - Phase B (wait for completion)', () {
    testWidgets('Complete -> completed', (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.complete));

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.completed);
    });

    testWidgets('Idle -> completed', (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.idle));

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.completed);
    });

    testWidgets('Failed -> proceed', (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.failed));

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.proceed);
    });

    testWidgets('Timeout with session alive -> proceed', (tester) async {
      // Stream closes with no terminal status; reconnect test succeeds.
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => const Stream.empty());
      when(mockPnpNotifier.testConnectionReconnected())
          .thenAnswer((_) async {});

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.proceed);
      verify(mockPnpNotifier.testConnectionReconnected()).called(1);
    });

    testWidgets('Timeout with reconnect failure -> connectionError',
        (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => const Stream.empty());
      when(mockPnpNotifier.testConnectionReconnected())
          .thenThrow(ExceptionNeedToReconnect());

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.connectionError);
      expect(r.state.events, ['enter', 'error']);
    });
  });

  group('PnpAutoMasterFlowMixin - null-threshold unauthorized probe', () {
    testWidgets('3 nulls then probe unauthorized -> completed (recover)',
        (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.fromIterable([null, null, null]));
      // Session died mid make-Master.
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenThrow(ExceptionAutoMasterUnauthorized());

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.completed);
      verify(mockPnpNotifier.checkAutoMasterStatus()).called(1);
    });

    testWidgets('3 nulls then probe Complete -> completed', (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.fromIterable([null, null, null]));
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.complete);

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.completed);
    });

    testWidgets('3 nulls then probe null (undetermined) -> connectionError',
        (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.fromIterable([null, null, null]));
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => null);

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.connectionError);
      expect(r.state.events, ['enter', 'error']);
    });

    testWidgets('probe Running resets counter, then Complete -> completed',
        (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) =>
          Stream.fromIterable([null, null, null, AutoMasterStatus.complete]));
      // Probe fires at the 3rd null: still Running -> reset and keep polling.
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.running);

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.completed);
      verify(mockPnpNotifier.checkAutoMasterStatus()).called(1);
    });
  });
}
