import 'package:privacy_gui/core/cloud/model/cloud_event_subscription.dart';
import 'package:test/test.dart';

void main() {
  group('test cloud event subscription model conveter', () {
    test('test data class to JSON String', () async {
      const data = CloudEventSubscription(
        name: 'Device Left Network Notification',
        eventType: CloudEventType.deviceLeftNetwork,
        timeFilters: [
          ('2022-03-22T3:21:00Z', '2032-03-22T3:21:00Z'),
        ],
      );
      final actual = data.toJson();
      expect(actual,
          '{"name":"Device Left Network Notification","eventType":"DEVICE_LEFT_NETWORK","timeFilters":[{"timeFilter":{"startAt":"2022-03-22T3:21:00Z","endAt":"2032-03-22T3:21:00Z"}}]}');
    });
    test('test data class to JSON', () async {
      const data = CloudEventSubscription(
        name: 'Device Left Network Notification',
        eventType: CloudEventType.deviceLeftNetwork,
        timeFilters: [
          ('2022-03-22T3:21:00Z', '2032-03-22T3:21:00Z'),
        ],
      );
      final actual = data.toMap();
      expect(actual, {
        "name": "Device Left Network Notification",
        "eventType": "DEVICE_LEFT_NETWORK",
        "timeFilters": [
          {
            "timeFilter": {
              "startAt": "2022-03-22T3:21:00Z",
              "endAt": "2032-03-22T3:21:00Z"
            }
          }
        ]
      });
    });
    test('test JSON string convert to data model', () async {
      const str =
          '{"name":"Device Left Network Notification","eventType":"DEVICE_LEFT_NETWORK","timeFilters":[{"timeFilter":{"startAt":"2022-03-22T3:21:00Z","endAt":"2032-03-22T3:21:00Z"}}]}';

      final data = CloudEventSubscription.fromJson(str);
      expect(data.name, 'Device Left Network Notification');
      expect(data.eventType, CloudEventType.deviceLeftNetwork);
      expect(data.timeFilters.length, 1);
      expect(data.timeFilters[0].$1, '2022-03-22T3:21:00Z');
      expect(data.timeFilters[0].$2, '2032-03-22T3:21:00Z');
    });
  });
}
