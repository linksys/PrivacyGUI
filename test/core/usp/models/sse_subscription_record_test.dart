import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

void main() {
  group('SseSubscriptionRecord', () {
    test('constructor stores all fields', () {
      final now = DateTime(2026, 3, 23);
      final record = SseSubscriptionRecord(
        subscriptionId: 'wifi-ssid-vc',
        notifType: 'ValueChange',
        referenceList: 'Device.WiFi.SSID.',
        createdAt: now,
      );
      expect(record.subscriptionId, 'wifi-ssid-vc');
      expect(record.notifType, 'ValueChange');
      expect(record.referenceList, 'Device.WiFi.SSID.');
      expect(record.createdAt, now);
    });

    test('toString contains key fields', () {
      final record = SseSubscriptionRecord(
        subscriptionId: 'hosts-oc',
        notifType: 'ObjectCreation',
        referenceList: 'Device.Hosts.Host.',
        createdAt: DateTime.now(),
      );
      final str = record.toString();
      expect(str, contains('hosts-oc'));
      expect(str, contains('ObjectCreation'));
      expect(str, contains('Device.Hosts.Host.'));
    });

    test('const constructor works', () {
      final record = SseSubscriptionRecord(
        subscriptionId: 'const-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.WiFi.Radio.',
        createdAt: DateTime(2026),
      );
      expect(record.subscriptionId, 'const-sub');
    });

    test('different notifTypes stored correctly', () {
      for (final type in [
        'ValueChange',
        'ObjectCreation',
        'ObjectDeletion',
        'OperationComplete',
        'Event',
      ]) {
        final record = SseSubscriptionRecord(
          subscriptionId: 'test-$type',
          notifType: type,
          referenceList: 'Device.Test.',
          createdAt: DateTime.now(),
        );
        expect(record.notifType, type);
      }
    });

    test('createdAt is preserved', () {
      final ts = DateTime(2026, 1, 15, 10, 30, 45);
      final record = SseSubscriptionRecord(
        subscriptionId: 'test',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
        createdAt: ts,
      );
      expect(record.createdAt, ts);
      expect(record.createdAt.year, 2026);
      expect(record.createdAt.month, 1);
      expect(record.createdAt.day, 15);
    });
  });
}
