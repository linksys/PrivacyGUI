// #1578 / epic #1575 — reconciling a diagnostic whose push never arrived.
//
// THE DECISION GUARDED. Guardian publishes a diagnostic's `OperationComplete` push
// **at most once and never retries it**, and it closes every stream at ~10 minutes.
// So a diagnostic straddling that boundary loses its result with nothing to notice:
// the caller sees a `TimeoutException` and the result sits in DynamoDB, readable, for
// the whole retention window. `GET /usp/results?commandKey=` is that read, and this
// file pins the three claims that make it worth having:
//
//   1. **The read happens on two edges and nowhere else** — before a timeout is
//      reported, and when the stream reopens. Never on an interval: the server
//      already polls DynamoDB on our behalf, and a second layer multiplies the read
//      volume the design budgets for. Asserted as a call count.
//   2. **Attribution is the `commandKey` alone.** #1575's verification item 2 is
//      closed without an environment — `web/usp_client.d.ts` documents `commandKey`
//      as a UUID minted per `operate()` call, so it is unique per execution by
//      construction. A row carrying another key must never resolve this operation.
//   3. **An empty array is an answer, not a race.** The index is a strongly-consistent
//      LSI, so there is no retry loop; the operation stays pending for the stream or
//      the timeout.
//
// HOW IT COULD SILENTLY REVERT. Each of the three fails *quietly* in the direction
// that looks like working software:
//
//   * A polling loop added to "make recovery more reliable" — every test here stays
//     green, and only the read volume moves.
//   * Attribution loosened to "the first row" — correct on every fixture with one
//     row, which is every fixture anyone writes by hand.
//   * An empty array treated as retryable — a diagnostic that legitimately has no
//     stored result yet spins instead of timing out, and the timeout is the thing
//     the user is waiting on.
//
// WHY THIS TEST TYPE. The same harness as `sse_operation_awaiter_test.dart`: a real
// `SseManager` over a mocked bridge and a `StreamController` for the SSE feed, so the
// stream-open edge is driven the way production drives it rather than by calling the
// listener directly.
//
// WHAT IS UNVERIFIED, deliberately. **The shape of a `results` row.** The spec says
// the endpoint returns a bare array, newest first, one row per execution, and nothing
// more precise; no environment has served one. `_parseStoredResult` therefore accepts
// both candidates — the `history`-style envelope with a `body`, and the bare notify
// payload — and both are pinned below. That is a hedge with a reason: guessing one
// and being wrong gives a reconcile that silently never matches, which is
// indistinguishable from "the result was not stored".

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

import '../helpers.dart';
import '../mocks.dart';

/// A stored result in the envelope shape `history` uses.
Map<String, dynamic> _storedEnvelope(String commandKey, {String? status}) => {
      'msgId': 'msg-1',
      'originTs': 1757000000000,
      'notificationType': 'OperationComplete',
      'body': {
        'oper_complete': {
          'command_name': 'IPPing()',
          'command_key': commandKey,
          'output_args': {'Status': status ?? 'Complete', 'SuccessCount': '5'},
        },
      },
    };

/// The same result as a bare notify payload, with no envelope around it.
Map<String, dynamic> _storedBare(String commandKey) => {
      'oper_complete': {
        'command_name': 'IPPing()',
        'command_key': commandKey,
        'output_args': {'Status': 'Complete', 'SuccessCount': '5'},
      },
    };

void main() {
  late MockUspBridgeClient mockBridge;
  late MockUspClient mockUsp;
  late SseManager manager;
  late SseOperationAwaiter awaiter;
  late StreamController<SseEvent> streamController;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    mockUsp = MockUspClient();
    streamController = StreamController<SseEvent>.broadcast();

    when(() => mockBridge.notifications())
        .thenAnswer((_) => streamController.stream);
    when(() => mockBridge.subscribe(
          subscriptionId: any(named: 'subscriptionId'),
          path: any(named: 'path'),
          notifType: any(named: 'notifType'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.unsubscribe(
          subscriptionId: any(named: 'subscriptionId'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.abortSse()).thenReturn(null);
    // The default: nothing stored. Individual tests override it.
    when(() => mockBridge.results(any())).thenAnswer((_) async => const []);

    when(() => mockUsp.onSseSubscribe = any(that: anything)).thenReturn(null);
    when(() => mockUsp.onTokenRefreshed = any(that: anything)).thenReturn(null);
    when(() => mockUsp.operate(any(), args: any(named: 'args')))
        .thenAnswer((_) async => {'commandKey': 'key-abc'});

    manager = SseManager(
      usp: mockUsp,
      bridge: mockBridge,
      strategy: FakeSseOperationStrategy(mockBridge),
    );
    awaiter = SseOperationAwaiter(manager, mockUsp);
  });

  tearDown(() async {
    awaiter.dispose();
    await awaiter.tearDownSharedSessionNow();
    if (!streamController.isClosed) streamController.close();
    await manager.dispose();
  });

  Future<void> connectManager() async {
    await manager.connect();
    streamController.add(heartbeatEvent());
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Fires a diagnostic with a short timeout and nothing on the stream to answer it.
  Future<OperateResult> runDiagnostic({
    Duration timeout = const Duration(milliseconds: 150),
  }) =>
      awaiter.execute(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        referencePath: 'Device.IP.Diagnostics.IPPing()',
        args: const {'Host': '8.8.8.8'},
        timeout: timeout,
      );

  // ═════════════════════════════════════════════════════════════════════════
  // Edge 1 — before reporting a timeout
  // ═════════════════════════════════════════════════════════════════════════
  group('before reporting a timeout', () {
    test('a stored result is returned instead of the timeout', () async {
      await connectManager();
      when(() => mockBridge.results('key-abc'))
          .thenAnswer((_) async => [_storedEnvelope('key-abc')]);

      final result = await runDiagnostic();

      expect(result.commandKey, 'key-abc');
      expect(result.status, 'Complete');
      expect(result.outputArgs['SuccessCount'], '5');
      verify(() => mockBridge.results('key-abc')).called(1);
    });

    test('the bare-payload row shape works too', () async {
      // The other candidate for the row shape; see this file's header for why both
      // are accepted rather than one being chosen.
      await connectManager();
      when(() => mockBridge.results('key-abc'))
          .thenAnswer((_) async => [_storedBare('key-abc')]);

      final result = await runDiagnostic();

      expect(result.commandKey, 'key-abc');
      expect(result.status, 'Complete');
    });

    test('an empty array still times out, with no retry', () async {
      await connectManager();

      await expectLater(runDiagnostic(), throwsA(isA<TimeoutException>()));

      // Exactly one read: an empty array is a definitive answer, because the index
      // is a strongly-consistent LSI. A retry loop here would be reads spent to
      // learn the same thing.
      verify(() => mockBridge.results('key-abc')).called(1);
    });

    test('a read that throws still times out rather than escaping', () async {
      // Includes the local transport, where this endpoint does not exist at all and
      // every reconcile is a `StateError`. A lost local push is a different problem
      // with no store behind it, so the correct behaviour is the timeout the caller
      // was already going to get.
      await connectManager();
      when(() => mockBridge.results(any()))
          .thenThrow(StateError('no RemoteReads on this transport'));

      await expectLater(runDiagnostic(), throwsA(isA<TimeoutException>()));
    });

    test('a diagnostic against an OFFLINE device still reconciles', () async {
      // #1578's second acceptance row, named so it is findable. The read is the one
      // part of this epic that does not need the device: the store is Guardian's, and
      // "the device dropped" is the likeliest reason the push went missing in the
      // first place.
      //
      // Worth stating because it constrains which edge can cover it: while the device
      // is offline Guardian answers the *stream* with a 400 (#1577), so it never
      // reopens and the reconnect edge cannot fire. The pre-timeout read is therefore
      // the whole of the offline path, which is exactly why it exists.
      await connectManager();
      when(() => mockBridge.results('key-abc'))
          .thenAnswer((_) async => [_storedEnvelope('key-abc')]);

      final result = await runDiagnostic();

      expect(result.commandKey, 'key-abc');
      expect(result.status, 'Complete');
      // No stream event was ever delivered — the device is not there to send one.
      verify(() => mockBridge.results('key-abc')).called(1);
    });

    test('another execution\'s row never resolves this one', () async {
      // Attribution, and the claim that matters most here: the query already filtered
      // on the key, but the spec makes resolving the ambiguity the *client's* job, so
      // the key is re-checked against the row.
      await connectManager();
      when(() => mockBridge.results('key-abc'))
          .thenAnswer((_) async => [_storedEnvelope('key-SOMEONE-ELSE')]);

      await expectLater(runDiagnostic(), throwsA(isA<TimeoutException>()));
    });

    test('a matching row is taken even when a foreign one is served first',
        () async {
      // The `.first`-instead-of-`.firstWhere` mistake, pinned. One row per execution
      // means a multi-row answer is several executions, and newest-first ordering is
      // no help: the newest may be another run.
      await connectManager();
      when(() => mockBridge.results('key-abc')).thenAnswer((_) async => [
            _storedEnvelope('key-OTHER'),
            _storedEnvelope('key-abc', status: 'Error'),
          ]);

      final result = await runDiagnostic();

      expect(result.commandKey, 'key-abc');
      expect(result.status, 'Error');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Edge 2 — the stream reopened
  // ═════════════════════════════════════════════════════════════════════════
  group('when the stream reopens', () {
    test('an outstanding diagnostic is recovered from the store', () async {
      await connectManager();
      when(() => mockBridge.results('key-abc'))
          .thenAnswer((_) async => [_storedEnvelope('key-abc')]);

      // A generous timeout, so that if the reopen did *not* recover it the test would
      // hang rather than pass on the timeout path.
      final pending = runDiagnostic(timeout: const Duration(seconds: 30));
      await Future.delayed(const Duration(milliseconds: 50));

      // Drive the edge the way production does: the stream closes and comes back.
      await streamController.close();
      streamController = StreamController<SseEvent>.broadcast();
      when(() => mockBridge.notifications())
          .thenAnswer((_) => streamController.stream);
      await manager.connect();

      final result = await pending;
      expect(result.commandKey, 'key-abc');
      expect(result.status, 'Complete');
    });

    test('nothing is read when nothing is outstanding', () async {
      await connectManager();

      await streamController.close();
      streamController = StreamController<SseEvent>.broadcast();
      when(() => mockBridge.notifications())
          .thenAnswer((_) => streamController.stream);
      await manager.connect();
      await Future.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockBridge.results(any()));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // The negative claim: no interval
  // ═════════════════════════════════════════════════════════════════════════
  test('the read is never on a timer', () async {
    // Acceptance 3 of #1578, and the reason it is a count rather than a code review:
    // a `Timer.periodic` added to this class looks like working code and every other
    // test in this file would stay green.
    //
    // **An hour of fake time, not 700 ms of real time.** The first version elapsed
    // 700 ms and its own comment claimed that was "well past any plausible poll
    // interval" — which was wrong twice over. The interval a well-meaning change
    // would copy is the server's own ~10 s, and no amount of *real* waiting is a
    // reasonable price for the assertion anyway. `fakeAsync` fires a real periodic
    // timer 360 times inside an hour, so the mutant this test is written against
    // cannot survive it.
    await connectManager();
    when(() => mockBridge.results('key-abc'))
        .thenAnswer((_) async => [_storedEnvelope('key-abc')]);
    await runDiagnostic();

    fakeAsync((async) => async.elapse(const Duration(hours: 1)));

    verify(() => mockBridge.results('key-abc')).called(1);
  });

  test('an operate the agent REFUSED engages nothing', () async {
    // The seam with #1533 / PR #1599, and **neither side's tests cover it**: from
    // usp-client 0.13.0 `UspClient.operate` *throws* on a refusal instead of returning
    // an empty map, and every test in this file stubs `operate` to succeed. So this
    // case is written from this side, by making the stub throw the way that change
    // will.
    //
    // What must happen: the error reaches the caller, and the reconcile machinery
    // never engages. There is nothing to reconcile — a command the agent refused was
    // never executed, so Guardian has no stored result and a read would spend a
    // request to be told so. It also means `expectedKey` is never assigned, which is
    // what keeps `_pending` clean without a special case.
    //
    // A `String`, not an `Exception`, because that is what the USP layer throws across
    // the Wasm boundary — and it is also why `_operateWithRetry` does not swallow it:
    // that method catches `TimeoutException` alone, so a refusal is not re-fired.
    await connectManager();
    when(() => mockUsp.operate(any(), args: any(named: 'args')))
        .thenThrow('Operate failed: Operation error: refused (code: 7004)');

    await expectLater(runDiagnostic(), throwsA(isA<String>()));

    verifyNever(() => mockBridge.results(any()));
  });

  test('an SSE push still wins, and costs no read at all', () async {
    // The happy path must not have gained a read. The store is the recovery path,
    // and a reconcile on every successful diagnostic would double the read volume
    // for the case that never needed it.
    await connectManager();

    final pending = runDiagnostic(timeout: const Duration(seconds: 5));
    await Future.delayed(const Duration(milliseconds: 50));

    streamController.add(notificationEvent(
      subscriptionId: 'cpe-1',
      type: 'OperationComplete',
      operComplete: {
        'command_name': 'IPPing()',
        'command_key': 'key-abc',
        'output_args': {'Status': 'Complete'},
      },
    ));

    final result = await pending;
    expect(result.status, 'Complete');
    verifyNever(() => mockBridge.results(any()));
  });
}
