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

    testWidgets('Idle only then stream closes (budget spent) -> proceed',
        (tester) async {
      // Never starts; session already proven alive upstream, so no reconnect
      // test is attempted.
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.idle));

      final r = await pumpFlow(tester, waitForRunningFirst: true);

      expect(r.result, AutoMasterFlowResult.proceed);
      verifyNever(mockPnpNotifier.testConnectionReconnected());
    });

    testWidgets('nulls only then stream closes (budget spent) -> proceed',
        (tester) async {
      // Firmware that still requires auth for GetAutoMasterStatus answers 401
      // to the unauthed poll, which the notifier flattens to null — so every
      // poll comes back undetermined. Phase A runs right after the ISP save +
      // internet check proved the session alive, so this must not surface
      // "router not found"; it proceeds and lets PnP's second pass recover.
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.fromIterable([null, null, null]));

      final r = await pumpFlow(tester, waitForRunningFirst: true);

      expect(r.result, AutoMasterFlowResult.proceed);
      expect(r.state.events, ['enter', 'exit']);
      // Phase A resolved it in place: no completion poll, and no extra probe
      // round-trip — the stream's own budget is the only give-up rule.
      verifyNever(mockPnpNotifier.pollAutoMasterStatus());
      verifyNever(mockPnpNotifier.checkAutoMasterStatus());
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

    testWidgets('Budget spent with router alive -> budgetExhausted',
        (tester) async {
      // Stream closes with no terminal status; reconnect test succeeds. The
      // router is there but Auto Master's outcome was never observed, so the
      // result is explicitly "unknown" rather than proceed — callers with a
      // pending save need to tell the two apart.
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => const Stream.empty());
      when(mockPnpNotifier.testConnectionReconnected())
          .thenAnswer((_) async {});

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.budgetExhausted);
      expect(r.state.events, ['enter', 'exit']);
      verify(mockPnpNotifier.testConnectionReconnected()).called(1);
    });

    testWidgets('Budget spent with reconnect failure -> connectionError',
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

  group('PnpAutoMasterFlowMixin - nulls during the make-Master outage', () {
    // make-Master takes the router's HTTP service down for the better part of a
    // minute; while it is gone the router may time out, refuse, or answer
    // something unrecognised — all of which flatten to null. These lock in that
    // nulls are never treated as evidence: the poll runs its full budget, and
    // only the reachability test at the end decides.
    testWidgets('nulls then Complete -> completed, without probing',
        (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) =>
          Stream.fromIterable([null, null, null, AutoMasterStatus.complete]));

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.completed);
      // No mid-poll probe: a run of nulls no longer triggers anything.
      verifyNever(mockPnpNotifier.checkAutoMasterStatus());
      verifyNever(mockPnpNotifier.testConnectionReconnected());
    });

    testWidgets('nulls to the end, router alive -> budgetExhausted',
        (tester) async {
      // The regression from #1180: three nulls used to be enough to declare
      // "router not found" ~15s before the router's HTTP service came back.
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.fromIterable([null, null, null]));
      when(mockPnpNotifier.testConnectionReconnected())
          .thenAnswer((_) async {});

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.budgetExhausted);
      expect(r.state.events, ['enter', 'exit']);
    });

    testWidgets('nulls to the end, router gone -> connectionError',
        (tester) async {
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.fromIterable([null, null, null]));
      when(mockPnpNotifier.testConnectionReconnected())
          .thenThrow(ExceptionNeedToReconnect());

      final r = await pumpFlow(tester, waitForRunningFirst: false);

      expect(r.result, AutoMasterFlowResult.connectionError);
      expect(r.state.events, ['enter', 'error']);
    });
  });

  group('PnpAutoMasterFlowMixin - mid-flow password rotation', () {
    testWidgets('Phase A Running, then rotation mid-completion -> completed',
        (tester) async {
      // The polls are unauthed, so make-Master rotating the admin password no
      // longer breaks them — nothing throws. Rotation is observed the normal
      // way: the status reaches Complete.
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
      when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer(
          (_) => Stream.fromIterable([null, AutoMasterStatus.complete]));

      final r = await pumpFlow(tester, waitForRunningFirst: true);

      expect(r.result, AutoMasterFlowResult.completed);
      expect(r.state.events, ['enter', 'exit']);
      verifyNever(mockPnpNotifier.checkAutoMasterStatus());
    });
  });
}
