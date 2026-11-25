import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';

/// `GetPingStatus` output as JSON text, partway through a ping.
const _runningText = '''
{"isRunning": true, "pingLog": "PING 8.8.8.8 (8.8.8.8): 32 data bytes\\n40 bytes from 8.8.8.8: seq=0 ttl=117 time=6.512 ms\\n"}
''';

void main() {
  test('reads whether the ping runs and what it has printed', () {
    final status = PingStatus.fromJson(_runningText);

    expect(status.isRunning, isTrue);
    expect(status.pingLog.split('\n').first,
        'PING 8.8.8.8 (8.8.8.8): 32 data bytes');
  });

  test('writes back what it read', () {
    const output = {'isRunning': false, 'pingLog': ''};

    expect(PingStatus.fromMap(output).toMap(), output);
  });

  test('survives a trip through JSON text', () {
    final status = PingStatus.fromJson(_runningText);

    expect(PingStatus.fromJson(status.toJson()), status);
  });

  test('copyWith changes only what it names', () {
    final status = PingStatus.fromJson(_runningText);

    final finished = status.copyWith(isRunning: false);

    expect(finished.isRunning, isFalse);
    expect(finished.pingLog, status.pingLog);
    expect(finished, isNot(status));
  });
}
