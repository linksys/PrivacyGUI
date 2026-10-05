import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';

/// The production values of the WiFi save's waits (#1000).
///
/// Every other test overrides them to milliseconds, so this is the only place
/// the real numbers are read. Each was set against a bench measurement on
/// FLWRT 2.0.2 (2026-10-05, recorded in the providers' docs), and the relation
/// between them is what the save relies on — so a change here should be a
/// deliberate one, made with a new measurement.
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('the answer window covers a guest-only write that answered in 25 s', () {
    expect(container.read(pnpWifiAnswerWindowProvider),
        const Duration(seconds: 30));
  });

  test(
      'the save deadline covers the renamed network going on the air 40 s after '
      'the write', () {
    expect(
        container.read(pnpSaveDeadlineProvider), const Duration(seconds: 60));
  });

  test('polling starts inside the save deadline and leaves room to repeat', () {
    final window = container.read(pnpWifiAnswerWindowProvider);
    final interval = container.read(pnpReconnectPollIntervalProvider);
    final deadline = container.read(pnpSaveDeadlineProvider);

    // The deadline is counted from the write, so a window as long as the
    // deadline would leave no poll at all: an unanswered write would go
    // straight to the reconnect step, which is what polling exists to avoid.
    expect(window, lessThan(deadline));
    expect(interval, const Duration(seconds: 3));
    expect((deadline - window).inSeconds ~/ interval.inSeconds,
        greaterThanOrEqualTo(5));
  });

  test('the reconnect step backs off 2, 4, 8, 16, 32 seconds', () {
    final backoff = container.read(pnpReconnectBackoffProvider);

    expect(
        [for (var n = 1; n <= 5; n++) backoff(n).inSeconds], [2, 4, 8, 16, 32]);
  });
}
