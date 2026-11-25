import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/traceroute_status.dart';

/// `GetTracerouteStatus` output as JSON text, once the trace is done.
const _doneText = '''
{"isRunning": false, "tracerouteLog": "traceroute to 8.8.8.8 (8.8.8.8), 30 hops max\\n 1  192.168.2.1  1.204 ms\\n"}
''';

void main() {
  test('reads whether the trace runs and what it has printed', () {
    final status = TracerouteStatus.fromJson(_doneText);

    expect(status.isRunning, isFalse);
    expect(status.tracerouteLog.split('\n').first,
        'traceroute to 8.8.8.8 (8.8.8.8), 30 hops max');
  });

  test('writes back what it read, under the router\'s names', () {
    final status = TracerouteStatus.fromJson(_doneText);

    expect(status.toMap(), {
      'isRunning': false,
      'tracerouteLog':
          'traceroute to 8.8.8.8 (8.8.8.8), 30 hops max\n 1  192.168.2.1  1.204 ms\n',
    });
  });

  test('survives a trip through JSON text', () {
    final status = TracerouteStatus.fromJson(_doneText);

    expect(TracerouteStatus.fromJson(status.toJson()), status);
  });

  test('copyWith changes only what it names', () {
    final status = TracerouteStatus.fromJson(_doneText);

    final again = status.copyWith(isRunning: true);

    expect(again.isRunning, isTrue);
    expect(again.tracerouteLog,
        'traceroute to 8.8.8.8 (8.8.8.8), 30 hops max\n 1  192.168.2.1  1.204 ms\n');
    expect(again, isNot(status));
  });
}
