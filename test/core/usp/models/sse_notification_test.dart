import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/models/sse_notification.dart';

void main() {
  group('SseNotification', () {
    test('constructor stores all fields', () {
      final notification = SseNotification(
        subscriptionId: 'test-sub-1',
        type: 'ValueChange',
        payload: {'key': 'value'},
      );
      expect(notification.subscriptionId, 'test-sub-1');
      expect(notification.type, 'ValueChange');
      expect(notification.payload, {'key': 'value'});
    });

    test('toString contains subscriptionId and type', () {
      final notification = SseNotification(
        subscriptionId: 'wifi-ssid-vc',
        type: 'ObjectCreation',
        payload: {},
      );
      final str = notification.toString();
      expect(str, contains('wifi-ssid-vc'));
      expect(str, contains('ObjectCreation'));
    });

    test('payload is accessible as Map', () {
      final notification = SseNotification(
        subscriptionId: 'test',
        type: 'ValueChange',
        payload: {
          'value_change': {'param_path': 'Device.WiFi.SSID.1.SSID'}
        },
      );
      final vc = notification.payload['value_change'] as Map<String, dynamic>;
      expect(vc['param_path'], 'Device.WiFi.SSID.1.SSID');
    });

    test('const constructor works', () {
      const notification = SseNotification(
        subscriptionId: 'const-sub',
        type: 'ValueChange',
        payload: {},
      );
      expect(notification.subscriptionId, 'const-sub');
    });

    test('different instances with same values have same fields', () {
      final a = SseNotification(
        subscriptionId: 'sub-1',
        type: 'ObjectDeletion',
        payload: {'key': 42},
      );
      final b = SseNotification(
        subscriptionId: 'sub-1',
        type: 'ObjectDeletion',
        payload: {'key': 42},
      );
      expect(a.subscriptionId, b.subscriptionId);
      expect(a.type, b.type);
      expect(a.payload, b.payload);
    });
  });
}
