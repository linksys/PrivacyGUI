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

  group('path', () {
    test('is the param_path of a ValueChange', () {
      expect(_valueChange('Device.WiFi.SSID.1.SSID').path,
          'Device.WiFi.SSID.1.SSID');
    });

    test('is the obj_path of an ObjectCreation and an ObjectDeletion', () {
      const creation = SseNotification(
        subscriptionId: 'cpe-3',
        type: 'ObjectCreation',
        payload: {
          'obj_creation': {'obj_path': 'Device.Hosts.Host.5.'},
        },
      );
      const deletion = SseNotification(
        subscriptionId: 'cpe-3',
        type: 'ObjectDeletion',
        payload: {
          'obj_deletion': {'obj_path': 'Device.Hosts.Host.5.'},
        },
      );

      expect(creation.path, 'Device.Hosts.Host.5.');
      expect(deletion.path, 'Device.Hosts.Host.5.');
    });

    test('is null for an OperationComplete, whose local payload has no path',
        () {
      const complete = SseNotification(
        subscriptionId: 'cpe-3',
        type: 'OperationComplete',
        payload: {
          'oper_complete': {'command_name': 'IPPing()'},
        },
      );

      expect(complete.path, isNull);
    });

    test('is null when the payload lacks it', () {
      const bare = SseNotification(
        subscriptionId: 'cpe-3',
        type: 'ValueChange',
        payload: {},
      );

      expect(bare.path, isNull);
    });
  });

  group('isFor', () {
    bool covers(String referenceList, String path) => _valueChange(path).isFor(
          notifType: 'ValueChange',
          referenceList: referenceList,
        );

    test('an object reference list covers the object and everything under it',
        () {
      expect(covers('Device.WiFi.SSID.', 'Device.WiFi.SSID.1.SSID'), isTrue);
      expect(covers('Device.WiFi.SSID.1.', 'Device.WiFi.SSID.1.SSID'), isTrue);
      expect(
          covers('Device.WiFi.SSID.1.', 'Device.WiFi.SSID.10.SSID'), isFalse);
      expect(covers('Device.WiFi.SSID.', 'Device.WiFi.SSIDX.1.SSID'), isFalse);
    });

    test('a parameter reference list covers that parameter only', () {
      expect(covers('Device.X.Enable', 'Device.X.Enable'), isTrue);
      expect(covers('Device.X.Enable', 'Device.X.EnableExtra'), isFalse);
      expect(covers('Device.X.Enable', 'Device.X.Enable.Y'), isFalse);
    });

    test('a * segment matches any one instance', () {
      expect(
          covers('Device.WiFi.SSID.*.SSID', 'Device.WiFi.SSID.3.SSID'), isTrue);
      expect(covers('Device.WiFi.SSID.*.SSID', 'Device.WiFi.SSID.3.Status'),
          isFalse);
      expect(
          covers('Device.WiFi.SSID.*.', 'Device.WiFi.SSID.3.Status'), isTrue);
    });

    test('from a search expression on, it covers everything', () {
      expect(
          covers('Device.WiFi.SSID.[Enable==true].SSID',
              'Device.WiFi.SSID.2.Status'),
          isTrue);
      expect(
          covers('Device.WiFi.SSID.[Enable==true].SSID',
              'Device.WiFi.Radio.1.Channel'),
          isFalse,
          reason: 'the segments before the expression still have to match');
    });

    test('another type is not for it', () {
      expect(
          _valueChange('Device.X.Value')
              .isFor(notifType: 'ObjectCreation', referenceList: 'Device.X.'),
          isFalse);
    });

    test('a notification with no path is for nothing', () {
      const complete = SseNotification(
        subscriptionId: 'cpe-3',
        type: 'OperationComplete',
        payload: {},
      );

      expect(
          complete.isFor(
              notifType: 'OperationComplete', referenceList: 'Device.'),
          isFalse);
    });
  });
}

SseNotification _valueChange(String path) => SseNotification(
      subscriptionId: 'cpe-15',
      type: 'ValueChange',
      payload: {
        'value_change': {'param_path': path, 'param_value': 'v'},
      },
    );
