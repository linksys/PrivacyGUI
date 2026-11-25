import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';

/// A result from `GetHealthCheckResults` output, as JSON text, from
/// test/test_data/core_transaction.dart.
const _speedTestText = '''
{
  "resultID": 16557,
  "timestamp": "2023-08-07T08:36:12Z",
  "healthCheckModulesRequested": ["SpeedTest"],
  "speedTestResult": {
    "resultID": 16557,
    "exitCode": "Success",
    "serverID": "38330",
    "latency": 2,
    "uploadBandwidth": 44559,
    "downloadBandwidth": 93356
  }
}
''';

Map<String, dynamic> _decode(String text) =>
    jsonDecode(text) as Map<String, dynamic>;

void main() {
  group('HealthCheckResult', () {
    test('reads a speed test and its result', () {
      final result = HealthCheckResult.fromJson(_decode(_speedTestText));

      expect(result.resultID, 16557);
      expect(result.timestamp, '2023-08-07T08:36:12Z');
      expect(result.healthCheckModulesRequested, ['SpeedTest']);
      final speed = result.speedTestResult!;
      expect(speed.exitCode, 'Success');
      expect(speed.serverID, '38330');
      expect(speed.latency, 2);
      expect(speed.uploadBandwidth, 44559);
      expect(speed.downloadBandwidth, 93356);
    });

    test('survives a trip through JSON text', () {
      final result = HealthCheckResult.fromJson(_decode(_speedTestText));

      expect(HealthCheckResult.fromJson(_decode(jsonEncode(result.toJson()))),
          result);
    });

    test('copyWith changes only what it names', () {
      final result = HealthCheckResult.fromJson(_decode(_speedTestText));

      final later = result.copyWith(timestamp: '2023-08-08T08:00:00Z');

      expect(later.timestamp, '2023-08-08T08:00:00Z');
      expect(later.speedTestResult, result.speedTestResult);
      expect(later, isNot(result));
    });
  });

  group('SpeedTestResult', () {
    test('reads a speed test that did not finish', () {
      final speed = SpeedTestResult.fromJson(
          const {'resultID': 27479, 'exitCode': 'Unavailable'});

      expect(speed.exitCode, 'Unavailable');
      expect((speed.latency, speed.uploadBandwidth, speed.downloadBandwidth),
          (null, null, null));
    });

    test('writes back what it read', () {
      final output =
          _decode(_speedTestText)['speedTestResult'] as Map<String, dynamic>;

      expect(SpeedTestResult.fromJson(output).toJson(), output);
    });

    test('copyWith changes only what it names', () {
      final speed =
          HealthCheckResult.fromJson(_decode(_speedTestText)).speedTestResult!;

      final slower = speed.copyWith(downloadBandwidth: 50000, latency: 9);

      expect((slower.downloadBandwidth, slower.latency), (50000, 9));
      expect(slower.uploadBandwidth, 44559);
      expect(slower, isNot(speed));
    });
  });
}
