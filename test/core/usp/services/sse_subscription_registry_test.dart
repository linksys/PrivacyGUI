import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_subscription_registry.dart';

import '../mocks.dart';

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

  // ---------------------------------------------------------------------------
  // registerAll
  // ---------------------------------------------------------------------------
  group('registerAll', () {
    test('calls strategy.registerSubscriptions with correct params', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'wifi-vc',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.SSID.',
        ),
      ]);

      verify(() => mockBridge.subscribe(
            subscriptionId: 'wifi-vc',
            path: 'Device.WiFi.SSID.',
            notifType: 1, // ValueChange → 1
          )).called(1);
    });

    test('adds to activeIds', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'test-sub',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      expect(registry.activeIds, contains('test-sub'));
    });

    test('duplicate subscriptionId skips strategy call', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'dup-sub',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'dup-sub',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      verify(() => mockBridge.subscribe(
            subscriptionId: 'dup-sub',
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).called(1); // Only 1 call, not 2
    });

    test('registers multiple subscriptions', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.1.',
        ),
        SubscriptionDef(
          subscriptionId: 'sub-2',
          notifType: 'ObjectCreation',
          referenceList: 'Device.Test.2.',
        ),
      ]);

      expect(registry.activeIds, containsAll(['sub-1', 'sub-2']));
    });
  });

  // ---------------------------------------------------------------------------
  // unregister
  // ---------------------------------------------------------------------------
  group('unregister', () {
    test('calls strategy.unregisterSubscriptions', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'to-remove',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      await registry.unregister('to-remove');

      verify(() => mockBridge.unsubscribe(
            subscriptionId: 'to-remove',
          )).called(1);
    });

    test('removes from activeIds', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'to-remove',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      await registry.unregister('to-remove');

      expect(registry.activeIds, isNot(contains('to-remove')));
    });

    test('unknown subscriptionId has no strategy call', () async {
      await registry.unregister('nonexistent');

      verifyNever(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          ));
    });
  });

  // ---------------------------------------------------------------------------
  // unregisterAll
  // ---------------------------------------------------------------------------
  group('unregisterAll', () {
    test('unregisters each subscription', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
        SubscriptionDef(
          subscriptionId: 'sub-2',
          notifType: 'ObjectCreation',
          referenceList: 'Device.Test.',
        ),
      ]);

      await registry.unregisterAll();

      verify(() => mockBridge.unsubscribe(
            subscriptionId: 'sub-1',
          )).called(1);
      verify(() => mockBridge.unsubscribe(
            subscriptionId: 'sub-2',
          )).called(1);
    });

    test('activeIds empty after', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      await registry.unregisterAll();

      expect(registry.activeIds, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // onSseConnected
  // ---------------------------------------------------------------------------
  group('onSseConnected', () {
    test('delegates to strategy.onSseConnected', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.SSID.',
        ),
      ]);

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
  });

  // ---------------------------------------------------------------------------
  // onSseDisconnected
  // ---------------------------------------------------------------------------
  group('onSseDisconnected', () {
    test('intentional disconnect clears local state', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      await registry.onSseDisconnected(intentional: true);

      expect(registry.activeIds, isEmpty);
    });

    test('unintentional disconnect preserves local state', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      await registry.onSseDisconnected(intentional: false);

      expect(registry.activeIds, contains('sub-1'));
    });
  });

  // ---------------------------------------------------------------------------
  // clearLocal
  // ---------------------------------------------------------------------------
  group('clearLocal', () {
    test('clears in-memory state without backend call', () async {
      await registry.registerAll([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      registry.clearLocal();

      expect(registry.activeIds, isEmpty);
      verifyNever(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          ));
    });
  });
}
