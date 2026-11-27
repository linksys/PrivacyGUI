import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_subscription_registry.dart';

import '../mocks.dart';

const _sub = SubscriptionDef(
  subscriptionId: 'pkg-w1-valuechange',
  notifType: 'ValueChange',
  referenceList: 'Device.Test.',
);

void main() {
  late MockUspBridgeClient mockBridge;
  late FakeSseOperationStrategy strategy;
  late SseSubscriptionRegistry registry;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    strategy = FakeSseOperationStrategy(mockBridge);
    registry = SseSubscriptionRegistry(strategy);

    // Default stubs
    when(() => mockBridge.subscribe(
          subscriptionId: any(named: 'subscriptionId'),
          path: any(named: 'path'),
          notifType: any(named: 'notifType'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.unsubscribe(
          subscriptionId: any(named: 'subscriptionId'),
        )).thenAnswer((_) async => {});
  });

  void verifyRegistered(int times) => verify(() => mockBridge.subscribe(
        subscriptionId: _sub.subscriptionId,
        path: any(named: 'path'),
        notifType: any(named: 'notifType'),
      )).called(times);

  void verifyNotRegistered() => verifyNever(() => mockBridge.subscribe(
        subscriptionId: any(named: 'subscriptionId'),
        path: any(named: 'path'),
        notifType: any(named: 'notifType'),
      ));

  void verifyUnregistered(int times) => verify(() => mockBridge.unsubscribe(
        subscriptionId: _sub.subscriptionId,
      )).called(times);

  void verifyNotUnregistered() => verifyNever(() => mockBridge.unsubscribe(
        subscriptionId: any(named: 'subscriptionId'),
      ));

  // ---------------------------------------------------------------------------
  // hold
  // ---------------------------------------------------------------------------
  group('hold', () {
    test('registers through the strategy with the subscription\'s params',
        () async {
      await registry.hold([
        const SubscriptionDef(
          subscriptionId: 'wifi-vc',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.SSID.',
        ),
      ], holder: Object());

      verify(() => mockBridge.subscribe(
            subscriptionId: 'wifi-vc',
            path: 'Device.WiFi.SSID.',
            notifType: 1, // ValueChange → 1
          )).called(1);
      expect(registry.activeIds, {'wifi-vc'});
    });

    test('registers several subscriptions in one call', () async {
      await registry.hold([
        const SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.1.',
        ),
        const SubscriptionDef(
          subscriptionId: 'sub-2',
          notifType: 'ObjectCreation',
          referenceList: 'Device.Test.2.',
        ),
      ], holder: Object());

      expect(registry.activeIds, {'sub-1', 'sub-2'});
    });

    test('a second holder of a registered id sends no registration', () async {
      await registry.hold([_sub], holder: Object());
      await registry.hold([_sub], holder: Object());

      verifyRegistered(1);
    });

    test('a second hold of an id in flight joins it, and completes with it',
        () async {
      final gate = Completer<Map<String, dynamic>>();
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) => gate.future);

      var joinedDone = false;
      final first = registry.hold([_sub], holder: Object());
      final joined = registry
          .hold([_sub], holder: Object()).then((_) => joinedDone = true);
      await Future.delayed(Duration.zero);
      expect(joinedDone, isFalse, reason: 'the registration is in flight');

      gate.complete({});
      await Future.wait([first, joined]);

      verifyRegistered(1);
      expect(registry.activeIds, {_sub.subscriptionId});
    });

    test('a hold of an id whose unregister is in flight registers after it',
        () async {
      final unregistered = Completer<Map<String, dynamic>>();
      final order = <String>[];
      when(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          )).thenAnswer((_) async {
        final answer = await unregistered.future;
        order.add('unregister');
        return answer;
      });
      final holder = Object();
      await registry.hold([_sub], holder: holder);
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) async {
        order.add('register');
        return {};
      });

      final release = registry.release(_sub.subscriptionId, holder: holder);
      final again = registry.hold([_sub], holder: Object());
      await Future.delayed(Duration.zero);
      expect(order, isEmpty, reason: 'the unregister is still in flight');

      unregistered.complete({});
      await Future.wait([release, again]);

      expect(order, ['unregister', 'register']);
      expect(registry.activeIds, {_sub.subscriptionId});
    });

    test(
        'an id the router refused is not active, and the next hold tries again',
        () async {
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenThrow(Exception('refused'));
      final holder = Object();
      await registry.hold([_sub], holder: holder);
      expect(registry.activeIds, isEmpty);

      await registry.release(_sub.subscriptionId, holder: holder);
      verifyNotUnregistered();

      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) async => {});
      await registry.hold([_sub], holder: Object());
      expect(registry.activeIds, {_sub.subscriptionId});
    });

    // A registration still in flight when the session ends lands on the
    // router with nothing left to remove it: on Guardian the disconnect's
    // cleanup listed the subscriptions before it landed, and locally the
    // cleanup is a no-op. So it is unregistered when it lands, after the
    // session has ended — the 401 that may answer is one the gate ignores
    // (#1666, folded in from #1981's review).
    test(
        'a registration that completes after the session ended leaves nothing '
        'active, and is unregistered', () async {
      final gate = Completer<Map<String, dynamic>>();
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) => gate.future);

      final held = registry.hold([_sub], holder: Object());
      await Future.delayed(Duration.zero);
      await registry.onSseDisconnected(intentional: true);
      gate.complete({});
      await held;
      await Future.delayed(Duration.zero);

      expect(registry.activeIds, isEmpty);
      expect(registry.records, isEmpty);
      verifyUnregistered(1);
    });

    test('so is one that completes after unregisterAll', () async {
      final gate = Completer<Map<String, dynamic>>();
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) => gate.future);

      final held = registry.hold([_sub], holder: Object());
      await Future.delayed(Duration.zero);
      await registry.unregisterAll();
      gate.complete({});
      await held;
      await Future.delayed(Duration.zero);

      verifyUnregistered(1);
    });

    // A newer hold of the id owns it on the router now; unregistering the id
    // would undo that registration.
    test('not when a newer hold of the id has taken it in the meantime',
        () async {
      final first = Completer<Map<String, dynamic>>();
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) => first.future);
      final held = registry.hold([_sub], holder: Object());
      await Future.delayed(Duration.zero);
      await registry.onSseDisconnected(intentional: true);
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) async => {});
      await registry.hold([_sub], holder: Object()); // the next session's

      first.complete({});
      await held;
      await Future.delayed(Duration.zero);

      verifyNotUnregistered();
      expect(registry.activeIds, {_sub.subscriptionId});
    });

    test('not when the router refused the registration', () async {
      final gate = Completer<Map<String, dynamic>>();
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) => gate.future);

      final held = registry.hold([_sub], holder: Object());
      await Future.delayed(Duration.zero);
      await registry.onSseDisconnected(intentional: true);
      gate.completeError(Exception('refused'));
      await held.catchError((_) {});
      await Future.delayed(Duration.zero);

      verifyNotUnregistered();
    });

    test(
        'a holder with another definition of a held id joins the first '
        'registration, which the router keeps', () async {
      // One id is one subscription on the router. The registry logs the
      // mismatch; what it does is join (#1981 review).
      const other = SubscriptionDef(
        subscriptionId: 'pkg-w1-valuechange',
        notifType: 'ValueChange',
        referenceList: 'Device.Other.',
      );
      final first = Object();
      final second = Object();
      await registry.hold([_sub], holder: first);
      await registry.hold([other], holder: second);

      verify(() => mockBridge.subscribe(
            subscriptionId: _sub.subscriptionId,
            path: 'Device.Test.',
            notifType: any(named: 'notifType'),
          )).called(1);
      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: 'Device.Other.',
            notifType: any(named: 'notifType'),
          ));
      expect(registry.records.single.referenceList, 'Device.Test.');

      await registry.release(_sub.subscriptionId, holder: first);
      verifyNotUnregistered();
      await registry.release(_sub.subscriptionId, holder: second);
      verifyUnregistered(1);
    });

    test(
        'a registration that throws fails every holder that joined it, and '
        'the next hold tries again', () async {
      final gate = Completer<void>();
      final throwing = _ThrowingOnceStrategy(mockBridge, gate.future);
      final registry = SseSubscriptionRegistry(throwing);

      final first = registry.hold([_sub], holder: Object());
      final joined = registry.hold([_sub], holder: Object());
      await Future.delayed(Duration.zero);
      gate.complete();

      await expectLater(first, throwsA(isA<StateError>()));
      await expectLater(joined, throwsA(isA<StateError>()));
      expect(registry.activeIds, isEmpty);

      await registry.hold([_sub], holder: Object());
      expect(registry.activeIds, {_sub.subscriptionId});
      expect(throwing.calls, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // release
  // ---------------------------------------------------------------------------
  group('release', () {
    test('the only holder releasing unregisters the id', () async {
      final holder = Object();
      await registry.hold([_sub], holder: holder);

      await registry.release(_sub.subscriptionId, holder: holder);

      verifyUnregistered(1);
      expect(registry.activeIds, isEmpty);
    });

    test('one of two holders releasing keeps the id registered', () async {
      final first = Object();
      final second = Object();
      await registry.hold([_sub], holder: first);
      await registry.hold([_sub], holder: second);

      await registry.release(_sub.subscriptionId, holder: first);
      verifyNotUnregistered();
      expect(registry.activeIds, {_sub.subscriptionId});

      await registry.release(_sub.subscriptionId, holder: second);
      verifyUnregistered(1);
    });

    test('a holder that held an id twice holds it once', () async {
      // The core set's holder: the orchestrator registers it again on every
      // rebuild.
      final core = Object();
      await registry.hold([_sub], holder: core);
      await registry.hold([_sub], holder: core);

      await registry.release(_sub.subscriptionId, holder: core);

      verifyRegistered(1);
      verifyUnregistered(1);
    });

    test('a second release by one holder changes nothing', () async {
      final first = Object();
      await registry.hold([_sub], holder: first);
      await registry.hold([_sub], holder: Object());

      await registry.release(_sub.subscriptionId, holder: first);
      await registry.release(_sub.subscriptionId, holder: first);

      verifyNotUnregistered();
      expect(registry.activeIds, {_sub.subscriptionId});
    });

    test('an id nobody holds sends nothing', () async {
      await registry.release('nonexistent', holder: Object());

      verifyNotUnregistered();
    });

    test(
        'a release from before an intentional disconnect does not touch the '
        'next session\'s holder', () async {
      final stale = Object();
      await registry.hold([_sub], holder: stale);
      await registry.onSseDisconnected(intentional: true);
      await registry.hold([_sub], holder: Object());

      await registry.release(_sub.subscriptionId, holder: stale);

      verifyNotUnregistered();
      expect(registry.activeIds, {_sub.subscriptionId});
    });
  });

  // ---------------------------------------------------------------------------
  // unregisterAll
  // ---------------------------------------------------------------------------
  group('unregisterAll', () {
    test('unregisters each subscription', () async {
      await registry.hold([
        const SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
        const SubscriptionDef(
          subscriptionId: 'sub-2',
          notifType: 'ObjectCreation',
          referenceList: 'Device.Test.',
        ),
      ], holder: Object());

      await registry.unregisterAll();

      verify(() => mockBridge.unsubscribe(
            subscriptionId: 'sub-1',
          )).called(1);
      verify(() => mockBridge.unsubscribe(
            subscriptionId: 'sub-2',
          )).called(1);
      expect(registry.activeIds, isEmpty);
    });

    test('forgets every holder, so a later release sends nothing', () async {
      final first = Object();
      await registry.hold([_sub], holder: first);
      await registry.hold([_sub], holder: Object());

      await registry.unregisterAll();
      clearInteractions(mockBridge);
      await registry.release(_sub.subscriptionId, holder: first);

      verifyNotUnregistered();
    });

    test('with nothing registered sends nothing', () async {
      await registry.unregisterAll();

      verifyNotUnregistered();
      verifyNotRegistered();
    });
  });

  // ---------------------------------------------------------------------------
  // onSseConnected
  // ---------------------------------------------------------------------------
  group('onSseConnected', () {
    test('delegates to strategy.onSseConnected', () async {
      await registry.hold([
        const SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.SSID.',
        ),
      ], holder: Object());

      reset(mockBridge);
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) async => {});

      await registry.onSseConnected();

      // FakeSseOperationStrategy resubscribes on connect
      verify(() => mockBridge.subscribe(
            subscriptionId: 'sub-1',
            path: 'Device.WiFi.SSID.',
            notifType: 1,
          )).called(1);
    });

    test('hands the strategy only what the router accepted', () async {
      final gate = Completer<Map<String, dynamic>>();
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) => gate.future);
      final held = registry.hold([_sub], holder: Object());
      await Future.delayed(Duration.zero);

      expect(registry.records, isEmpty, reason: 'still in flight');

      gate.complete({});
      await held;
      expect(
          registry.records.map((r) => r.subscriptionId), [_sub.subscriptionId]);
    });
  });

  // ---------------------------------------------------------------------------
  // onSseDisconnected
  // ---------------------------------------------------------------------------
  group('onSseDisconnected', () {
    test('intentional disconnect clears local state', () async {
      await registry.hold([_sub], holder: Object());

      await registry.onSseDisconnected(intentional: true);

      expect(registry.activeIds, isEmpty);
    });

    test('unintentional disconnect preserves local state', () async {
      await registry.hold([_sub], holder: Object());

      await registry.onSseDisconnected(intentional: false);

      expect(registry.activeIds, {_sub.subscriptionId});
    });
  });
}

/// Throws from its first `registerSubscriptions`, once [gate] completes; then
/// behaves as [FakeSseOperationStrategy]. The real strategies swallow a failed
/// subscription; this stands in for a throw they do not catch.
class _ThrowingOnceStrategy extends FakeSseOperationStrategy {
  _ThrowingOnceStrategy(super.bridge, this.gate);

  final Future<void> gate;
  int calls = 0;

  @override
  Future<List<SseSubscriptionRecord>> registerSubscriptions(
    List<SubscriptionDef> subscriptions,
  ) async {
    calls++;
    if (calls == 1) {
      await gate;
      throw StateError('registration threw');
    }
    return super.registerSubscriptions(subscriptions);
  }
}
