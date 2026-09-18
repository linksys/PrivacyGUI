import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_remote_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import '../mocks.dart';

void main() {
  late MockUspBridgeClient mockBridge;
  late RemoteSseStrategy strategy;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    strategy = RemoteSseStrategy(mockBridge);

    when(() => mockBridge.subscribe(
          subscriptionId: any(named: 'subscriptionId'),
          path: any(named: 'path'),
          notifType: any(named: 'notifType'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.unsubscribe(
          subscriptionId: any(named: 'subscriptionId'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.listSubscriptions())
        .thenAnswer((_) async => <String>[]);
  });

  group('heartbeatConfig', () {
    test('returns remote config with enabled=false', () {
      expect(strategy.heartbeatConfig.enabled, isFalse);
      expect(strategy.heartbeatConfig.authCheckEnabled, isFalse);
    });
  });

  group('authBehavior', () {
    test('returns remote config with shouldRetryOnFailure=false', () {
      expect(strategy.authBehavior.shouldRetryOnFailure, isFalse);
    });
  });

  group('registerSubscriptions', () {
    test('calls unsubscribe before subscribe for each subscription', () async {
      await strategy.registerSubscriptions([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.',
        ),
      ]);

      // Bridge receives prefixed ID
      verifyInOrder([
        () => mockBridge.unsubscribe(subscriptionId: 'remote-sub-1'),
        () => mockBridge.subscribe(
              subscriptionId: 'remote-sub-1',
              path: 'Device.WiFi.',
              notifType: 1,
            ),
      ]);
    });

    test('ignores unsubscribe error and continues to subscribe', () async {
      when(() => mockBridge.unsubscribe(
              subscriptionId: any(named: 'subscriptionId')))
          .thenThrow(Exception('not found'));

      final records = await strategy.registerSubscriptions([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.',
        ),
      ]);

      expect(records.length, 1);
      // Bridge receives prefixed ID
      verify(() => mockBridge.subscribe(
            subscriptionId: 'remote-sub-1',
            path: 'Device.WiFi.',
            notifType: 1,
          )).called(1);
    });

    test('returns records for successful registrations', () async {
      final records = await strategy.registerSubscriptions([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      expect(records.length, 1);
      expect(records.first.subscriptionId, 'sub-1');
    });

    test('continues on subscribe failure', () async {
      // Mock uses prefixed ID
      when(() => mockBridge.subscribe(
            subscriptionId: 'remote-fail-sub',
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenThrow(Exception('guardian error'));

      final records = await strategy.registerSubscriptions([
        SubscriptionDef(
          subscriptionId: 'fail-sub',
          notifType: 'ValueChange',
          referenceList: 'Device.Fail.',
        ),
        SubscriptionDef(
          subscriptionId: 'ok-sub',
          notifType: 'ValueChange',
          referenceList: 'Device.OK.',
        ),
      ]);

      expect(records.length, 1);
      // Record stores original ID (transparent to Registry/Manager)
      expect(records.first.subscriptionId, 'ok-sub');
    });
  });

  group('unregisterSubscriptions', () {
    test('calls bridge.unsubscribe for each id with prefix', () async {
      await strategy.unregisterSubscriptions(['sub-1', 'sub-2']);

      // Bridge receives prefixed IDs
      verify(() => mockBridge.unsubscribe(subscriptionId: 'remote-sub-1'))
          .called(1);
      verify(() => mockBridge.unsubscribe(subscriptionId: 'remote-sub-2'))
          .called(1);
    });

    test('continues on failure', () async {
      when(() => mockBridge.unsubscribe(subscriptionId: 'remote-fail'))
          .thenThrow(Exception('error'));

      await strategy.unregisterSubscriptions(['fail', 'ok']);

      verify(() => mockBridge.unsubscribe(subscriptionId: 'remote-ok'))
          .called(1);
    });
  });

  // #1497 acceptance 7b. The remote arm used to be a no-op documented as
  // "orchestrator controls", and that was true of the code and wrong about
  // Guardian: it force-closes the proxied stream at roughly ten minutes, which
  // makes a reconnect the most routine event in a support session rather than a
  // fault, and the *new* stream carries no subscriptions, so the dashboard stopped
  // updating for the rest of the session while the banner said "connected". The
  // orchestrator does not cover it — it registers on the first connect only.
  //
  // WHICH EDGE, AND WHY IT IS NOT `onSseConnected`. The first fix put this on the
  // `connected` transition, and review found the hook could not fire in the one
  // mode it was for. `SseConnectionManager` infers `connected` from traffic — the
  // first non-`_debug` event — and `HeartbeatConfig.remote` reflects a Guardian
  // that sends no heartbeats, so the only traffic on a remote stream is a
  // subscription notification. No subscriptions ⇒ no notifications ⇒ no
  // `connected` ⇒ the re-registration never runs, and the manager settles in
  // `connecting` where even `tryReconnect()` refuses to act. The two tests below
  // are a pair for that reason: one asserts the work happens on stream-open, the
  // other asserts it does *not* also happen on `connected`, where it would churn
  // a stream that is by definition already delivering.
  //
  // The `existingRecords.isEmpty` case keeps the old comment's point intact — the
  // first connect still belongs to the orchestrator, and it is recognisable
  // because the registry has nothing recorded yet.
  group('onSseStreamOpened', () {
    SseSubscriptionRecord record(String id, String path) =>
        SseSubscriptionRecord(
          subscriptionId: id,
          notifType: 'ValueChange',
          referenceList: path,
          createdAt: DateTime.now(),
        );

    test('re-registers existing subscriptions on reconnect', () async {
      await strategy.onSseStreamOpened([record('sub-1', 'Device.WiFi.')]);

      // Through registerSubscriptions, so the prefix and the mandatory
      // unregister → register dance both still apply: a bare `subscribe` would be
      // rejected by Guardian as a duplicate ID.
      verifyInOrder([
        () => mockBridge.unsubscribe(subscriptionId: 'remote-sub-1'),
        () => mockBridge.subscribe(
              subscriptionId: 'remote-sub-1',
              path: 'Device.WiFi.',
              notifType: 1,
            ),
      ]);
    });

    test('re-registers every record, not just the first', () async {
      await strategy.onSseStreamOpened([
        record('sub-1', 'Device.WiFi.'),
        record('sub-2', 'Device.Ethernet.'),
      ]);

      verify(() => mockBridge.subscribe(
            subscriptionId: 'remote-sub-1',
            path: 'Device.WiFi.',
            notifType: 1,
          )).called(1);
      verify(() => mockBridge.subscribe(
            subscriptionId: 'remote-sub-2',
            path: 'Device.Ethernet.',
            notifType: 1,
          )).called(1);
    });

    test('first connect stays the orchestrator\'s: no records, no calls',
        () async {
      await strategy.onSseStreamOpened([]);

      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));
      verifyNever(() =>
          mockBridge.unsubscribe(subscriptionId: any(named: 'subscriptionId')));
    });

    test('a second open while the first walk is still running is skipped',
        () async {
      // The walk is ~1s for six subscriptions and `SseManager` invokes it
      // fire-and-forget, so a flapping stream can start a second one over the same
      // records. Interleaved, walk B subscribes an id and walk A's loop then
      // unsubscribes it — the subscription is absent for the rest of the session
      // and the only trace is a swallowed logger.w.
      //
      // Deliberately not awaited: awaiting the first call is precisely the
      // condition under which the bug cannot occur, so the test would pass against
      // the unguarded code.
      final first =
          strategy.onSseStreamOpened([record('sub-1', 'Device.WiFi.')]);
      await strategy.onSseStreamOpened([record('sub-1', 'Device.WiFi.')]);
      await first;

      verify(() => mockBridge.subscribe(
            subscriptionId: 'remote-sub-1',
            path: 'Device.WiFi.',
            notifType: 1,
          )).called(1);
    });
  });

  group('onSseConnected', () {
    test('does nothing — the reconnect work is on stream-open', () async {
      await strategy.onSseConnected([
        SseSubscriptionRecord(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.',
          createdAt: DateTime.now(),
        ),
      ]);

      // Not vacuous by omission: records are passed in, and the local arm does
      // resubscribe on exactly this edge with exactly this input. Asserting
      // silence here is asserting that the remote arm has been moved rather than
      // duplicated — a copy left behind would unsubscribe and re-subscribe a
      // stream that is currently delivering, which is a blackout window bought
      // for nothing.
      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));
      verifyNever(() =>
          mockBridge.unsubscribe(subscriptionId: any(named: 'subscriptionId')));
    });
  });

  group('onSseDisconnected', () {
    test('intentional disconnect triggers fire-and-forget cleanup', () async {
      when(() => mockBridge.listSubscriptions())
          .thenAnswer((_) async => ['remote-sub-1', 'remote-sub-2']);

      await strategy.onSseDisconnected(intentional: true);

      // Fire-and-forget, so we just verify it was called
      // The actual cleanup happens asynchronously
      await Future.delayed(const Duration(milliseconds: 50));
      verify(() => mockBridge.listSubscriptions()).called(1);
    });

    test('cleanup only removes remote-prefixed subscriptions', () async {
      when(() => mockBridge.listSubscriptions()).thenAnswer(
          (_) async => ['remote-sub-1', 'local-sub', 'ethernet-valuechange']);

      await strategy.onSseDisconnected(intentional: true);
      await Future.delayed(const Duration(milliseconds: 50));

      // Only remote-prefixed subscription should be unsubscribed
      verify(() => mockBridge.unsubscribe(subscriptionId: 'remote-sub-1'))
          .called(1);
      // Local subscriptions should NOT be touched
      verifyNever(() => mockBridge.unsubscribe(subscriptionId: 'local-sub'));
      verifyNever(
          () => mockBridge.unsubscribe(subscriptionId: 'ethernet-valuechange'));
    });

    test('unintentional disconnect does not trigger cleanup', () async {
      await strategy.onSseDisconnected(intentional: false);

      verifyNever(() => mockBridge.listSubscriptions());
    });
  });
}
