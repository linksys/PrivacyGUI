/// #1551 (W5) — the three fields `copyWith` has to be able to *clear*.
///
/// `FirmwareUpdateState.copyWith` was written with `?? this.x` for every field,
/// which makes it structurally incapable of setting one back to null: passing
/// `errorMessage: null` (the field is now `failure`) reads as "clear the error" at
/// four call sites and does
/// nothing at all. That was invisible while the only way out of a failure was
/// `cancel()`, which replaces the whole state — W5 adds two fields that have to be
/// cleared *without* resetting anything else, so the hole is closed here and the
/// existing four call sites stop lying.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_failure.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';

const _downloading = FirmwareOtaInstallProgress(
  status: FirmwareAutoUpdateStatus.downloading,
  rawProgress: 45,
  rawState: '3',
);

const _refused = FirmwareFailure.routerReportedFailure(fwupState: '5');
const _stalled = FirmwareFailure.progressStalled(fwupState: 'unread');

void main() {
  group('clearing a field', () {
    test('a failure can be cleared, and not by passing null', () {
      const failed = FirmwareUpdateState(
        phase: FirmwareUpdatePhase.failed,
        failure: _refused,
      );

      // The shape every field here has, and the reason the flag exists: a named
      // argument that is absent and one that is explicitly null are the same
      // value in Dart, so `?? this.x` cannot tell "leave it" from "clear it".
      expect(failed.copyWith(failure: null).failure, _refused);
      expect(failed.copyWith(clearFailure: true).failure, isNull);
    });

    test('ota progress can be cleared without disturbing the rest', () {
      const installing = FirmwareUpdateState(
        phase: FirmwareUpdatePhase.installing,
        otaProgress: _downloading,
        failure: _stalled,
      );

      final cleared = installing.copyWith(
        phase: FirmwareUpdatePhase.idle,
        clearOtaProgress: true,
      );

      expect(cleared.otaProgress, isNull);
      expect(cleared.failure, _stalled);
    });

    test('a state read error can be cleared', () {
      const unreadable =
          FirmwareUpdateState(stateReadError: 'could not reach the router');

      expect(unreadable.copyWith(clearStateReadError: true).stateReadError,
          isNull);
    });

    test('clearing and setting the same field in one call clears it', () {
      // Not a case any caller should write, but it has to have one answer rather
      // than depending on argument order. Clear wins: it is the more explicit of
      // the two, since a value can also arrive from an unrelated `??`.
      const failed = FirmwareUpdateState(failure: _stalled);

      expect(
        failed.copyWith(failure: _refused, clearFailure: true).failure,
        isNull,
      );
    });
  });

  group('what the new fields mean', () {
    test('progress survives into a failure', () {
      // REQ-A7: a failure card has to be able to say where the update stopped, so
      // the last reading is not discarded when the phase becomes `failed`.
      const state = FirmwareUpdateState(
        phase: FirmwareUpdatePhase.installing,
        otaProgress: _downloading,
      );

      final failed = state.copyWith(
        phase: FirmwareUpdatePhase.failed,
        failure: _refused,
      );

      expect(failed.otaProgress?.rawState, '3');
      expect(failed.otaProgress?.percent, 45);
    });

    test('a state read error draws no install card and vetoes no back arrow',
        () {
      // The #1549 handover: `loadBanks()` used to report its failure through
      // `_fail()`, so an unreachable router painted "Update Failed / Try Again" on
      // a page where nothing had been attempted. The two are separate fields
      // because they need separate copy and separate retries — one re-reads, the
      // other starts over.
      //
      // Asserted against the two consumers rather than against the constructor:
      // "phase is idle and failure is null" restates the defaults and could
      // not fail. What can fail is either consumer starting to key on the wrong
      // field — `handles` would draw the failure card this field exists to avoid,
      // and `isUpdating` would hand `_firmwareExitGuard` a veto on a page where
      // nothing was ever dispatched, leaving the user unable to navigate away from
      // a failed read.
      const unreadable =
          FirmwareUpdateState(stateReadError: 'could not reach the router');

      expect(FirmwareInstallPhaseCard.handles(unreadable.phase), isFalse);
      expect(unreadable.isUpdating, isFalse);
    });

    test('both new fields are part of equality', () {
      // Riverpod compares with `==`, so a field left out of `props` is a field
      // whose change never repaints. A progress bar is exactly the widget that
      // would fail silently.
      expect(
        const FirmwareUpdateState(otaProgress: _downloading),
        isNot(const FirmwareUpdateState()),
      );
      expect(
        const FirmwareUpdateState(stateReadError: 'x'),
        isNot(const FirmwareUpdateState()),
      );
      expect(
        const FirmwareUpdateState(otaProgress: _downloading),
        const FirmwareUpdateState(otaProgress: _downloading),
      );
      // Which also pins both defaults: were either field to gain a non-null
      // default, the two `isNot`s above would compare equal.
    });
  });
}
