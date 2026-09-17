/// #1550 (W4) — the value the OTA card renders its verdict from.
///
/// Constitution Article I §1.7 asks for this file, and the two things worth
/// pinning in it are the ones the card and the notifier both lean on: that a
/// failed check and a check that found nothing are *not* equal, and that equality
/// includes the version — because the notifier publishes this into state and
/// riverpod suppresses a rebuild when the new value equals the old.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';

void main() {
  group('FirmwareOtaCheckResult - construction', () {
    test('notChecked carries no version', () {
      const result = FirmwareOtaCheckResult.notChecked();

      expect(result.verdict, FirmwareOtaCheckVerdict.notChecked);
      expect(result.version, isEmpty);
      expect(result.isUpdateAvailable, isFalse);
    });

    test('updateAvailable keeps the version it was given', () {
      const result = FirmwareOtaCheckResult.updateAvailable(version: '2.0.2.1');

      expect(result.verdict, FirmwareOtaCheckVerdict.updateAvailable);
      expect(result.version, '2.0.2.1');
      expect(result.isUpdateAvailable, isTrue);
    });

    test('updateAvailable with no version is still an offer', () {
      // The router is allowed to publish `Available=true` with an empty
      // `Version`, so this is a reading the bench produces rather than a
      // defensive default. The card renders the sentence and drops the version
      // line; what it must not do is stop offering.
      const result = FirmwareOtaCheckResult.updateAvailable();

      expect(result.isUpdateAvailable, isTrue);
      expect(result.version, isEmpty);
    });

    test('noUpdateFound carries no version', () {
      const result = FirmwareOtaCheckResult.noUpdateFound();

      expect(result.verdict, FirmwareOtaCheckVerdict.noUpdateFound);
      expect(result.version, isEmpty);
      expect(result.isUpdateAvailable, isFalse);
    });
  });

  group('FirmwareOtaCheckResult - equality', () {
    test('notChecked is not noUpdateFound', () {
      // The one assertion this file exists for. Both render nothing about a
      // version and both mean "no update to offer", which is exactly why they are
      // easy to collapse into one — and a check that *failed* lands on the first
      // one. Collapsing them tells a user whose check never ran that their
      // firmware is current.
      expect(const FirmwareOtaCheckResult.notChecked(),
          isNot(const FirmwareOtaCheckResult.noUpdateFound()));
    });

    test('same verdict and version are equal', () {
      expect(const FirmwareOtaCheckResult.updateAvailable(version: '2.0.2.1'),
          const FirmwareOtaCheckResult.updateAvailable(version: '2.0.2.1'));
    });

    test('the version is part of equality', () {
      // Not a formality: the notifier publishes this inside `FirmwareUpdateState`,
      // and a value that compares equal to the previous one is a rebuild riverpod
      // is entitled to skip. If two offers of different versions were equal, a
      // second check would leave the first version on screen.
      expect(
          const FirmwareOtaCheckResult.updateAvailable(version: '2.0.2.1'),
          isNot(
              const FirmwareOtaCheckResult.updateAvailable(version: '2.0.3')));
    });

    test('props are the verdict, the version and the error code', () {
      expect(
          const FirmwareOtaCheckResult.updateAvailable(version: '2.0.2.1')
              .props,
          [FirmwareOtaCheckVerdict.updateAvailable, '2.0.2.1', null]);
    });

    test('two failed checks with different reasons are not equal', () {
      // The code has to be in `props` or a second failure would not republish: the
      // notifier writes the result into state, and a state that compares equal is a
      // state riverpod does not notify on — so the card would keep the first reason.
      expect(
        const FirmwareOtaCheckResult.checkFailed(
            FirmwareUpdateErrorCode.serverUnreachable),
        isNot(const FirmwareOtaCheckResult.checkFailed(
            FirmwareUpdateErrorCode.flash)),
      );
    });

    test('checkFailed carries its reason and claims no version', () {
      const result =
          FirmwareOtaCheckResult.checkFailed(FirmwareUpdateErrorCode.signature);

      expect(result.verdict, FirmwareOtaCheckVerdict.checkFailed);
      expect(result.errorCode, FirmwareUpdateErrorCode.signature);
      expect(result.isUpdateAvailable, isFalse);
      expect(result.version, isEmpty,
          reason: 'a check that failed has no version to offer');
    });

    test('a non-failure code cannot become a failed check', () {
      // The same assert `FirmwareFailure.routerReported` carries, for the same
      // reason: this verdict is what makes the page say the check failed.
      for (final code in [
        FirmwareUpdateErrorCode.none,
        FirmwareUpdateErrorCode.unknown,
        FirmwareUpdateErrorCode.unreported,
      ]) {
        expect(() => FirmwareOtaCheckResult.checkFailed(code),
            throwsA(isA<AssertionError>()),
            reason: '${code.name} is not a failure');
      }
    });
  });
}
