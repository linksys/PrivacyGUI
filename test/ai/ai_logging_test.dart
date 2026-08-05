import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/ai/ai_logging.dart';

void main() {
  group('aiLogSensitive', () {
    test('does not build the message when logging is compiled out', () {
      var built = 0;
      aiLogSensitive(() {
        built++;
        return 'secret';
      });

      // In a debug test run kDebugMode is true, so the callback does run. The
      // property under test is that the *callback* is what gates the work: a
      // release build skips it entirely, so no sensitive string is ever
      // interpolated or held. Asserting on kDebugMode keeps this honest in
      // whichever mode the suite is run.
      expect(built, kDebugMode ? 1 : 0);
    });

    test('evaluates the callback at most once per call', () {
      var built = 0;
      aiLogSensitive(() {
        built++;
        return 'value';
      });

      expect(built, lessThanOrEqualTo(1),
          reason: 'the message must not be built repeatedly for one log line');
    });
  });

  group('aiLog', () {
    test('accepts a plain message without throwing', () {
      // Structural diagnostics are always logged; this guards the signature
      // rather than the sink.
      expect(() => aiLog('loop 1/5'), returnsNormally);
    });
  });
}
