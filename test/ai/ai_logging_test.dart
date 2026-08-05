import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/ai/ai_logging.dart';

void main() {
  tearDown(resetAiLoggingForTest);

  group('aiLogSensitive in a release build', () {
    test('does not build the message, and logs orElse instead', () {
      final lines = stubAiLoggingAsRelease();
      var built = 0;

      aiLogSensitive(
        () {
          built++;
          return 'ip=192.168.1.1';
        },
        orElse: () => 'wan.isUp=true',
      );

      // The point of the callback: in release the sensitive string is never
      // interpolated, so it cannot end up in memory or in the log file.
      expect(built, 0, reason: 'the sensitive message must not be built');
      expect(lines, ['[AI]: wan.isUp=true']);
    });

    test('logs nothing at all when there is no orElse', () {
      final lines = stubAiLoggingAsRelease();
      var built = 0;

      aiLogSensitive(() {
        built++;
        return 'secret';
      });

      expect(built, 0);
      expect(lines, isEmpty,
          reason: 'a line with no release-safe alternative is dropped');
    });
  });

  group('aiLogSensitive in a debug build', () {
    test('logs the sensitive message, not orElse', () {
      final lines = captureAiLogs();

      aiLogSensitive(
        () => 'ip=192.168.1.1',
        orElse: () => 'wan.isUp=true',
      );

      expect(lines, ['[AI]: ip=192.168.1.1'],
          reason: 'debug builds get the detail; orElse is the fallback only');
    });

    test('evaluates the callback exactly once per call', () {
      captureAiLogs();
      var built = 0;

      aiLogSensitive(() {
        built++;
        return 'value';
      });

      expect(built, 1,
          reason: 'the message must not be built repeatedly for one log line');
    });
  });

  group('aiLog', () {
    test('is emitted in a release build', () {
      final lines = stubAiLoggingAsRelease();

      aiLog('loop 1/5');

      // Structural diagnostics are what make a field report useful, so they
      // must survive the release gate.
      expect(lines, ['[AI]: loop 1/5']);
    });
  });
}
