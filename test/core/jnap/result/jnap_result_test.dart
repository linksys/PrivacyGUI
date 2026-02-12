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

    test('test error result without error or output keys', () async {
      // This is the bug scenario from Issue #85:
      // Router returns {"result": "ErrorInvalidHostName"} with no error/output keys.
      // Previously this would produce error = "null" (from jsonEncode(null)).
      const sample = '''
        {
          "result": "ErrorInvalidHostName"
        }
      ''';

      final actual = JNAPResult.fromJson(jsonDecode(sample));

      expect(actual.runtimeType, JNAPError);
      expect(actual.result, 'ErrorInvalidHostName');
      // Should fallback to result code, NOT "null"
      expect((actual as JNAPError).error, 'ErrorInvalidHostName');
    });

    test('test error result with output key but null value', () async {
      // Edge case from Qodo review: output key exists but value is null
      const sample = '''
        {
          "result": "ErrorInvalidHostName",
          "output": null
        }
      ''';

      final actual = JNAPResult.fromJson(jsonDecode(sample));

      expect(actual.runtimeType, JNAPError);
      expect(actual.result, 'ErrorInvalidHostName');
      // Should fallback to result code, NOT "null"
      expect((actual as JNAPError).error, 'ErrorInvalidHostName');
    });

    test('test error result with output but no error key', () async {
      const sample = '''
        {
          "result": "ErrorSomething",
          "output": {"detail": "some detail"}
        }
      ''';

      final actual = JNAPResult.fromJson(jsonDecode(sample));

      expect(actual.runtimeType, JNAPError);
      expect(actual.result, 'ErrorSomething');
      // Should encode the output as the error message
      expect(
          (actual as JNAPError).error, jsonEncode({"detail": "some detail"}));
    });
  });
}
