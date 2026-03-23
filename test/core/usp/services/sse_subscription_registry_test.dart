import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_subscription_registry.dart';

import '../mocks.dart';

void main() {
  late MockUspBridgeClient mockBridge;
  late SseSubscriptionRegistry registry;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    registry = SseSubscriptionRegistry(mockBridge);

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
  // register
  // ---------------------------------------------------------------------------
  group('register', () {
    test('calls bridge.subscribe with correct params', () async {
      await registry.register(
        subscriptionId: 'wifi-vc',
        notifType: 'ValueChange',
        referenceList: 'Device.WiFi.SSID.',
      );

      verify(() => mockBridge.subscribe(
            subscriptionId: 'wifi-vc',
            path: 'Device.WiFi.SSID.',
            notifType: 1, // ValueChange → 1
          )).called(1);
    });

    test('returns SseSubscriptionRecord with correct fields', () async {
      final record = await registry.register(
        subscriptionId: 'hosts-oc',
        notifType: 'ObjectCreation',
        referenceList: 'Device.Hosts.Host.',
      );

      expect(record.subscriptionId, 'hosts-oc');
      expect(record.notifType, 'ObjectCreation');
      expect(record.referenceList, 'Device.Hosts.Host.');
      expect(record.createdAt, isNotNull);
    });

    test('adds to activeIds', () async {
      await registry.register(
        subscriptionId: 'test-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );

      expect(registry.activeIds, contains('test-sub'));
    });

    test('duplicate subscriptionId skips bridge call', () async {
      await registry.register(
        subscriptionId: 'dup-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );
      await registry.register(
        subscriptionId: 'dup-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );

      verify(() => mockBridge.subscribe(
            subscriptionId: 'dup-sub',
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).called(1); // Only 1 call, not 2
    });

    test('duplicate returns existing record', () async {
      final first = await registry.register(
        subscriptionId: 'dup-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );
      final second = await registry.register(
        subscriptionId: 'dup-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );

      expect(identical(first, second), isTrue);
    });

    test('notifType conversion: ValueChange→1', () async {
      await registry.register(
        subscriptionId: 'vc',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );

      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: 1,
          )).called(1);
    });

    test('notifType conversion: OperationComplete→4', () async {
      await registry.register(
        subscriptionId: 'oc',
        notifType: 'OperationComplete',
        referenceList: 'Device.Test.',
      );

      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: 4,
          )).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // unregister
  // ---------------------------------------------------------------------------
  group('unregister', () {
    test('calls bridge.unsubscribe', () async {
      await registry.register(
        subscriptionId: 'to-remove',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );

      await registry.unregister('to-remove');

      verify(() => mockBridge.unsubscribe(
            subscriptionId: 'to-remove',
          )).called(1);
    });

    test('removes from activeIds', () async {
      await registry.register(
        subscriptionId: 'to-remove',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );

      await registry.unregister('to-remove');

      expect(registry.activeIds, isNot(contains('to-remove')));
    });

    test('unknown subscriptionId has no bridge call', () async {
      await registry.unregister('nonexistent');

      verifyNever(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          ));
    });

    test('bridge.unsubscribe failure still removes from map', () async {
      when(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          )).thenThrow(Exception('network error'));

      await registry.register(
        subscriptionId: 'fail-unsub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );

      await registry.unregister('fail-unsub');

      expect(registry.activeIds, isNot(contains('fail-unsub')));
    });
  });

  // ---------------------------------------------------------------------------
  // resubscribeAll
  // ---------------------------------------------------------------------------
  group('resubscribeAll', () {
    test('re-registers all tracked subscriptions', () async {
      await registry.register(
        subscriptionId: 'sub-1',
        notifType: 'ValueChange',
        referenceList: 'Device.WiFi.SSID.',
      );
      await registry.register(
        subscriptionId: 'sub-2',
        notifType: 'ObjectCreation',
        referenceList: 'Device.Hosts.Host.',
      );

      reset(mockBridge);
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) async => {});

      await registry.resubscribeAll();

      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).called(2);
    });

    test('empty registry has no bridge calls', () async {
      await registry.resubscribeAll();

      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));
    });

    test('one failure does not stop others', () async {
      await registry.register(
        subscriptionId: 'sub-1',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );
      await registry.register(
        subscriptionId: 'sub-2',
        notifType: 'ObjectCreation',
        referenceList: 'Device.Test.',
      );

      reset(mockBridge);
      var callCount = 0;
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('first fails');
        return {};
      });

      await registry.resubscribeAll();

      // Both were attempted
      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).called(2);
    });
  });

  // ---------------------------------------------------------------------------
  // unregisterAll
  // ---------------------------------------------------------------------------
  group('unregisterAll', () {
    test('unregisters each subscription', () async {
      await registry.register(
        subscriptionId: 'sub-1',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );
      await registry.register(
        subscriptionId: 'sub-2',
        notifType: 'ObjectCreation',
        referenceList: 'Device.Test.',
      );

      await registry.unregisterAll();

      verify(() => mockBridge.unsubscribe(
            subscriptionId: 'sub-1',
          )).called(1);
      verify(() => mockBridge.unsubscribe(
            subscriptionId: 'sub-2',
          )).called(1);
    });

    test('activeIds empty after', () async {
      await registry.register(
        subscriptionId: 'sub-1',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
      );

      await registry.unregisterAll();

      expect(registry.activeIds, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // _notifTypeToInt (tested indirectly via register)
  // ---------------------------------------------------------------------------
  group('notifType conversion', () {
    test('ObjectCreation → 2', () async {
      await registry.register(
        subscriptionId: 'oc',
        notifType: 'ObjectCreation',
        referenceList: 'Device.Test.',
      );

      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: 2,
          )).called(1);
    });

    test('ObjectDeletion → 3', () async {
      await registry.register(
        subscriptionId: 'od',
        notifType: 'ObjectDeletion',
        referenceList: 'Device.Test.',
      );

      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: 3,
          )).called(1);
    });

    test('Event → 5', () async {
      await registry.register(
        subscriptionId: 'ev',
        notifType: 'Event',
        referenceList: 'Device.Test.',
      );

      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: 5,
          )).called(1);
    });

    test('unknown type defaults to 1', () async {
      await registry.register(
        subscriptionId: 'unknown',
        notifType: 'CustomType',
        referenceList: 'Device.Test.',
      );

      verify(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: 1,
          )).called(1);
    });
  });
}
