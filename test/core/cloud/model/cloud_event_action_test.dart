import 'package:privacy_gui/core/cloud/model/cloud_event_action.dart';
import 'package:test/test.dart';

void main() {
  group('test cloud event action model conveter', () {
    test('test data class to JSON String', () async {
      const data = CloudEventAction(
        actionType: 'NOTIFICATION',
        startAt: '2022-03-22T3:21:00Z',
        endAt: '2032-03-22T3:21:00Z',
        timestoTrigger: 1,
        triggerInterval: 12,
        payload: '{"type": "PUSH","value": "SMART_DEVICE_ID"}',
      );
      final actual = data.toJson();
      expect(actual,
          '{"actionType":"NOTIFICATION","startAt":"2022-03-22T3:21:00Z","endAt":"2032-03-22T3:21:00Z","timestoTrigger":1,"triggerInterval":12,"payload":"{\\"type\\": \\"PUSH\\",\\"value\\": \\"SMART_DEVICE_ID\\"}"}');
    });
    test('test data class to JSON', () async {
      const data = CloudEventAction(
        actionType: 'NOTIFICATION',
        startAt: '2022-03-22T3:21:00Z',
        endAt: '2032-03-22T3:21:00Z',
        timestoTrigger: 1,
        triggerInterval: 12,
        payload: '{"type": "PUSH","value": "SMART_DEVICE_ID"}',
      );
      final actual = data.toMap();
      expect(actual, {
        "actionType": "NOTIFICATION",
        "startAt": "2022-03-22T3:21:00Z",
        "endAt": "2032-03-22T3:21:00Z",
        "timestoTrigger": 1,
        "triggerInterval": 12,
        "payload": "{\"type\": \"PUSH\",\"value\": \"SMART_DEVICE_ID\"}",
      });
    });
    test('test JSON string convert to data model', () async {
      const str =
          '{"actionType":"NOTIFICATION","startAt":"2022-03-22T3:21:00Z","endAt":"2032-03-22T3:21:00Z","timestoTrigger":1,"triggerInterval":12,"payload":"{\\"type\\": \\"PUSH\\",\\"value\\": \\"SMART_DEVICE_ID\\"}"}';

      final data = CloudEventAction.fromJson(str);
      expect(data.actionType, 'NOTIFICATION');
      expect(data.startAt, '2022-03-22T3:21:00Z');
      expect(data.endAt, '2032-03-22T3:21:00Z');
      expect(data.timestoTrigger, 1);
      expect(data.triggerInterval, 12);
      expect(data.payload, '{"type": "PUSH","value": "SMART_DEVICE_ID"}');
    });
  });
}
