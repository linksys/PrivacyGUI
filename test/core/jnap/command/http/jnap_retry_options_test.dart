import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/command/http/jnap_retry_options.dart';

void main() {
  test('a command retries once, after 3 s, by default', () {
    const options = JNAPRetryOptions();

    expect(options.exceedMaxRetry(0), isFalse);
    expect(options.exceedMaxRetry(1), isTrue);
    expect(options.getRetryDelay(0), const Duration(seconds: 3));
  });

  test('waits the last delay it has for every retry past its list', () {
    const options = JNAPRetryOptions(
      retries: 3,
      retryDelays: [Duration(seconds: 1), Duration(seconds: 2)],
    );

    expect([
      for (var retry = 0; retry < 3; retry++) options.getRetryDelay(retry)
    ], const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 2)
    ]);
    expect(options.exceedMaxRetry(2), isFalse);
    expect(options.exceedMaxRetry(3), isTrue);
  });

  test('copyWith changes only what it names', () {
    const options = JNAPRetryOptions();

    final patient = options.copyWith(retries: 3);
    final quicker = options.copyWith(retryDelays: [Duration(seconds: 1)]);
    final same = options.copyWith();

    expect(patient.retries, 3);
    expect(patient.retryDelays, const [Duration(seconds: 3)]);
    expect(quicker.retries, 1);
    expect(quicker.getRetryDelay(0), const Duration(seconds: 1));
    expect(same.retries, 1);
    expect(same.retryDelays, [const Duration(seconds: 3)]);
  });
}
