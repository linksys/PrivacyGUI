import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generative_ui/generative_ui.dart';

/// Pins the failure shapes of [AWSConfig.fromEnvironment], because
/// `RouterAssistantView` treats *every* one of them as "this build has no
/// environment credentials" and shows the manual form with no error.
///
/// That only works if the catch is broad. These two modes are why it cannot be
/// narrowed to a single `on` clause:
///
/// * dotenv never loaded — throws `NotInitializedError`, which extends `Error`.
///   Neither `on Exception` nor `on ConfigurationException` matches it. This is
///   the usual state, since `assets/agents/.env` is gitignored.
/// * dotenv loaded with blank keys — throws `ConfigurationException`, which is
///   an `Exception`. This is what a developer gets after copying
///   `assets/agents/env.template`, whose credential values are empty.
///
/// The two are mutually exclusive per run, so both are exercised here in order:
/// dotenv is a per-isolate mutable global, and each test file is its own
/// isolate, so the first test must run before anything loads it.
void main() {
  test('unloaded dotenv throws an Error, which is not an Exception', () {
    // Must come first: nothing has loaded dotenv yet.
    expect(dotenv.isInitialized, isFalse,
        reason: 'this test is about the uninitialized state');

    Object? thrown;
    try {
      AWSConfig.fromEnvironment();
    } catch (e) {
      thrown = e;
    }

    expect(thrown, isNotNull);
    expect(thrown, isNot(isA<Exception>()),
        reason: 'an `on Exception catch` would let this through uncaught, '
            'which is why the view catches every throwable');
  });

  test('blank credentials throw a ConfigurationException', () {
    dotenv.testLoad(fileInput: '''
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=us-east-1
BEDROCK_MODEL_ID=some-model
''');
    addTearDown(dotenv.clean);

    // A different type from the case above, and an Exception rather than an
    // Error — the view must treat both as simply "not configured".
    expect(() => AWSConfig.fromEnvironment(),
        throwsA(isA<ConfigurationException>()));
  });

  test('a complete environment yields a config', () {
    dotenv.testLoad(fileInput: '''
AWS_ACCESS_KEY_ID=AKIAEXAMPLE
AWS_SECRET_ACCESS_KEY=secret
AWS_REGION=us-west-2
BEDROCK_MODEL_ID=some-model
''');
    addTearDown(dotenv.clean);

    // The positive case, so the tests above cannot pass merely because
    // `fromEnvironment` always throws.
    expect(AWSConfig.fromEnvironment().accessKeyId, 'AKIAEXAMPLE');
  });
}
