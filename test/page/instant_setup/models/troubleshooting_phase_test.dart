import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_phase.dart';

/// The no-internet troubleshooting flow's own phases (#1511 P1).
///
/// Its notifier moves by building a new phase, and Riverpod only tells the
/// pages when the new one is not equal to the old — so equality is what decides
/// whether a page hears about a change.
void main() {
  group('TroubleshootingNoInternet.saveError', () {
    test('is null unless given', () {
      expect(const TroubleshootingNoInternet().saveError, isNull);
    });

    test(
        'the hub after a failed save is a different phase, so the form '
        'hears it', () {
      expect(const TroubleshootingNoInternet(saveError: UnexpectedError()),
          isNot(const TroubleshootingNoInternet()));
    });

    test('keeps the error typed, for the form to localize', () {
      const error = TimeoutError(detail: 'the mutation lock timed out');

      expect(const TroubleshootingNoInternet(saveError: error).saveError,
          same(error));
    });
  });

  group('the modem restart', () {
    test('counts down from 150 seconds and checks up to 30 times by default',
        () {
      expect(
          const ModemRestartCountdown(remainingSeconds: 150).totalSeconds, 150);
      expect(
          const ModemRestartCheckingInternet(attemptCount: 1).maxAttempts, 30);
    });

    test('each tick and each attempt is a new phase', () {
      expect(const ModemRestartCountdown(remainingSeconds: 149),
          isNot(const ModemRestartCountdown(remainingSeconds: 150)));
      expect(const ModemRestartCheckingInternet(attemptCount: 2),
          isNot(const ModemRestartCheckingInternet(attemptCount: 1)));
    });
  });

  group('IspSaving', () {
    test('each step of the save is a new phase', () {
      final phases = IspSaveStep.values.map((s) => IspSaving(step: s)).toSet();

      expect(phases, hasLength(IspSaveStep.values.length));
    });
  });

  group('the endings', () {
    test('carry nothing, so any two are the same ending', () {
      expect(
          const TroubleshootingRecovered(), const TroubleshootingRecovered());
      expect(const TroubleshootingReadFailure(),
          const TroubleshootingReadFailure());
    });

    test('a read failure is not a confirmed "no internet" (#1098)', () {
      expect(const TroubleshootingReadFailure(),
          isNot(const TroubleshootingNoInternet()));
      expect(const TroubleshootingReadFailure(),
          isNot(const TroubleshootingRecovered()));
    });
  });
}
