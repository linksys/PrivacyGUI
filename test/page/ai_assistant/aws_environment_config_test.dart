import 'package:flutter_test/flutter_test.dart';
import 'package:generative_ui/generative_ui.dart';

/// Pins the failure shape of [AWSConfig.fromEnvironment] when this build has no
/// `assets/agents/.env`.
///
/// `RouterAssistantView` treats "no environment credentials" as the normal path
/// and shows the manual form without an error. That only works if it catches
/// what is actually thrown. `dotenv.env` throws `NotInitializedError`, which
/// extends `Error` — so an `on ConfigurationException` clause does not match it,
/// and an `on Exception` clause would not either.
///
/// Getting this wrong is not a corner case: `.env` is gitignored, so an
/// unloaded dotenv is the usual state, and every launch would show a spurious
/// "Something went wrong" on the configuration screen.
///
/// dotenv is deliberately not loaded here — each test file runs in its own
/// isolate, so this file sees the same uninitialized state a normal build does.
void main() {
  group('AWSConfig.fromEnvironment with no .env loaded', () {
    test('throws something that is not an Exception', () {
      Object? thrown;
      try {
        AWSConfig.fromEnvironment();
      } catch (e) {
        thrown = e;
      }

      expect(thrown, isNotNull,
          reason: 'the view relies on this failing to decide it must show the '
              'manual configuration form');
      expect(thrown, isNot(isA<Exception>()),
          reason: 'so `on Exception catch` would not catch it');
      expect(thrown, isNot(isA<ConfigurationException>()),
          reason: 'and neither would `on ConfigurationException catch` — the '
              'view must catch broadly, which is why it does');
    });
  });
}
