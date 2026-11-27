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
      router.addWildcardHandler((n) => received = n);

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
      router.addWildcardHandler((_) => throw Exception('boom'));
      router.addWildcardHandler((_) => successCount++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));

      expect(successCount, 1);
    });

    test(
        'a handler that removes itself while notified does not stop the others',
        () {
      int laterCount = 0;
      late void Function() remove;
      remove = router.addWildcardHandler((_) => remove());
      router.addWildcardHandler((_) => laterCount++);

      router.routeEvent(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));

      expect(laterCount, 1);
      expect(router.wildcardHandlerCount, 1);
    });

    test('dispose clears all handlers', () {
      router.addWildcardHandler((_) {});
      router.addWildcardHandler((_) {});

      router.dispose();

      expect(router.wildcardHandlerCount, 0);
    });
  });
}
