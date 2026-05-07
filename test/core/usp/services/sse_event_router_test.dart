import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/sse_event_router.dart';

import '../helpers.dart';

void main() {
  late SseEventRouter router;

  setUp(() {
    router = SseEventRouter();
  });

  tearDown(() {
    router.dispose();
  });

  // ---------------------------------------------------------------------------
  // addHandler
  // ---------------------------------------------------------------------------
  group('addHandler', () {
    test('handler receives matching notification', () {
      SseNotification? received;
      router.addHandler('sub-1', (n) => received = n);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
        valueChange: {'param_path': 'Device.WiFi.SSID.1.SSID'},
      ));

      expect(received, isNotNull);
      expect(received!.subscriptionId, 'sub-1');
      expect(received!.type, 'ValueChange');
    });

    test('handler not called for different subscriptionId', () {
      int callCount = 0;
      router.addHandler('sub-1', (_) => callCount++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-2',
        type: 'ValueChange',
      ));

      expect(callCount, 0);
    });

    test('multiple handlers for same subscriptionId all fire', () {
      int callCount1 = 0;
      int callCount2 = 0;
      router.addHandler('sub-1', (_) => callCount1++);
      router.addHandler('sub-1', (_) => callCount2++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));

      expect(callCount1, 1);
      expect(callCount2, 1);
    });

    test('cleanup removes handler', () {
      int callCount = 0;
      final cleanup = router.addHandler('sub-1', (_) => callCount++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));
      expect(callCount, 1);

      cleanup();

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));
      expect(callCount, 1); // no increase
    });

    test('cleanup removes empty subscription key', () {
      final cleanup = router.addHandler('sub-1', (_) {});
      expect(router.registeredIds, contains('sub-1'));

      cleanup();
      expect(router.registeredIds, isNot(contains('sub-1')));
    });

    test('registeredIds reflects added handlers', () {
      router.addHandler('sub-a', (_) {});
      router.addHandler('sub-b', (_) {});
      router.addHandler('sub-c', (_) {});

      expect(router.registeredIds, {'sub-a', 'sub-b', 'sub-c'});
    });
  });

  // ---------------------------------------------------------------------------
  // addWildcardHandler
  // ---------------------------------------------------------------------------
  group('addWildcardHandler', () {
    test('wildcard handler receives all notifications', () {
      final receivedIds = <String>[];
      router.addWildcardHandler((n) => receivedIds.add(n.subscriptionId));

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));
      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-2',
        type: 'ObjectCreation',
      ));

      expect(receivedIds, ['sub-1', 'sub-2']);
    });

    test('cleanup removes wildcard handler', () {
      int callCount = 0;
      final cleanup = router.addWildcardHandler((_) => callCount++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));
      expect(callCount, 1);

      cleanup();

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));
      expect(callCount, 1);
    });

    test('wildcardHandlerCount reflects count', () {
      expect(router.wildcardHandlerCount, 0);
      final c1 = router.addWildcardHandler((_) {});
      expect(router.wildcardHandlerCount, 1);
      final c2 = router.addWildcardHandler((_) {});
      expect(router.wildcardHandlerCount, 2);
      c1();
      expect(router.wildcardHandlerCount, 1);
      c2();
      expect(router.wildcardHandlerCount, 0);
    });

    test('multiple wildcards all fire', () {
      int count1 = 0;
      int count2 = 0;
      router.addWildcardHandler((_) => count1++);
      router.addWildcardHandler((_) => count2++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));

      expect(count1, 1);
      expect(count2, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // routeEvent
  // ---------------------------------------------------------------------------
  group('routeEvent', () {
    test('notification event routes to handler', () {
      SseNotification? received;
      router.addHandler('sub-1', (n) => received = n);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ObjectDeletion',
        objDeletion: {'obj_path': 'Device.Hosts.Host.5.'},
      ));

      expect(received, isNotNull);
      expect(received!.type, 'ObjectDeletion');
    });

    test('heartbeat event does not call handler', () {
      int callCount = 0;
      router.addHandler('sub-1', (_) => callCount++);
      router.addWildcardHandler((_) => callCount++);

      router.routeEvent(heartbeatEvent());

      expect(callCount, 0);
    });

    test('connected event does not call handler', () {
      int callCount = 0;
      router.addWildcardHandler((_) => callCount++);

      router.routeEvent(connectedEvent());

      expect(callCount, 0);
    });

    test('turbo_channel event does not crash', () {
      expect(
        () => router.routeEvent(fakeEvent('turbo_channel', '{"port": 8084}')),
        returnsNormally,
      );
    });

    test('unknown event type does not crash', () {
      expect(
        () => router.routeEvent(fakeEvent('custom_event', 'data')),
        returnsNormally,
      );
    });

    test('invalid JSON in notification does not crash', () {
      int callCount = 0;
      router.addWildcardHandler((_) => callCount++);

      router.routeEvent(fakeEvent('notification', 'not valid json'));

      expect(callCount, 0);
    });

    test('missing subscription_id does not call handler', () {
      int callCount = 0;
      router.addWildcardHandler((_) => callCount++);

      router.routeEvent(fakeEvent('notification', '{"type": "ValueChange"}'));

      expect(callCount, 0);
    });

    test('missing type does not call handler', () {
      int callCount = 0;
      router.addWildcardHandler((_) => callCount++);

      router.routeEvent(
          fakeEvent('notification', '{"subscription_id": "sub-1"}'));

      expect(callCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling & dispose
  // ---------------------------------------------------------------------------
  group('Error handling & dispose', () {
    test('handler throws but other handlers still fire', () {
      int successCount = 0;
      router.addHandler('sub-1', (_) => throw Exception('boom'));
      router.addHandler('sub-1', (_) => successCount++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));

      expect(successCount, 1);
    });

    test('wildcard handler throws but subscription handlers still fire', () {
      int subCount = 0;
      router.addWildcardHandler((_) => throw Exception('wildcard boom'));
      router.addHandler('sub-1', (_) => subCount++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));

      // Subscription handler fires before wildcard (order: sub first, then wildcard)
      expect(subCount, 1);
    });

    test('dispose clears all handlers', () {
      router.addHandler('sub-1', (_) {});
      router.addHandler('sub-2', (_) {});
      router.addWildcardHandler((_) {});

      router.dispose();

      expect(router.registeredIds, isEmpty);
      expect(router.wildcardHandlerCount, 0);
    });

    test('handler and wildcard both receive same notification', () {
      int handlerCount = 0;
      int wildcardCount = 0;
      router.addHandler('sub-1', (_) => handlerCount++);
      router.addWildcardHandler((_) => wildcardCount++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));

      expect(handlerCount, 1);
      expect(wildcardCount, 1);
    });
  });
}
