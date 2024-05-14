import 'dart:convert';

import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:test/test.dart';

void main() {
  group('test jnap result', () {
    test('test success result', () async {
      const sample = '''
      {
        "result": "OK",
        "output": {}
      }
      ''';

      final actual = JNAPResult.fromJson(jsonDecode(sample));
      expect(actual.runtimeType, JNAPSuccess);
      expect(actual.result, 'OK');
      expect((actual as JNAPSuccess).output, {});
    });

    test('test success result 2', () async {
      const sample = '''
      {
        "result": "OK",
        "output": {
        "isWirelessSchedulerEnabled": false,
        "wirelessSchedule": {
        "sunday": "111111111111111111111111111111111111111111111111",
        "monday": "111111111111111111111111111111111111111111111111",
        "tuesday": "111111111111111111111111111111111111111111111111",
        "wednesday": "111111111111111111111111111111111111111111111111",
        "thursday": "111111111111111111111111111111111111111111111111",
        "friday": "111111111111111111111111111111111111111111111111",
        "saturday": "111111111111111111111111111111111111111111111111"
        },
        "configuredRadios": [],
        "configurableRadios": [
        {
        "radioID": "RADIO_2.4GHz",
        "isGuestRadio": false
        },
        {
        "radioID": "RADIO_5GHz",
        "isGuestRadio": false
        },
        {
        "radioID": "RADIO_6GHz",
        "isGuestRadio": false
        },
        {
        "radioID": "RADIO_2.4GHz",
        "isGuestRadio": true
        },
        {
        "radioID": "RADIO_5GHz",
        "isGuestRadio": true
        },
        {
        "radioID": "RADIO_6GHz",
        "isGuestRadio": true
        }
        ]
        }
      }
      ''';

      final actual = JNAPResult.fromJson(jsonDecode(sample));
      expect(actual.runtimeType, JNAPSuccess);
      expect(actual.result, 'OK');
      expect(
          (actual as JNAPSuccess).output['isWirelessSchedulerEnabled'], false);
    });

    test('test error result', () async {
      const sample = '''
        {
        "result": "_ErrorInvalidInput",
        "error": "Validation of element \\"SetSimpleWiFiSettings\\" failed due to unexpected count (0) of child element \\"simpleWiFiSettings\\""
        }
      ''';

      final actual = JNAPResult.fromJson(jsonDecode(sample));

      expect(actual.runtimeType, JNAPError);
      expect(actual.result, '_ErrorInvalidInput');
      expect((actual as JNAPError).error,
          'Validation of element "SetSimpleWiFiSettings" failed due to unexpected count (0) of child element "simpleWiFiSettings"');
    });
  });
}
