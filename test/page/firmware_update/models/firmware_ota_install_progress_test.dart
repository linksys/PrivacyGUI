/// #1551 (W5) — the two rules that decide what a progress bar is allowed to say.
///
/// Both come out of the bench measurements rather than out of taste:
///
///  1. **A percentage may only be drawn from `fwup_state=3`.** `-m 1`'s check
///     phase was measured driving `fwup_progress` 0→100 all by itself, while the
///     USP-triggered check held it at 0 for the whole window. Two different
///     behaviours from one state means the number carries no meaning there, and
///     `Download(ota,"true")` is `-m 2` — check *then* download — so a shared bar
///     would run 0→100 twice for one install.
///  2. **Within one state the number never goes backwards.** `fwup_progress` is a
///     sampled sysevent, and the app polls it; a late sample arriving after an
///     earlier one has already been shown would walk the bar back.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

/// A router reading, built through the **real** `fwup_state` mapping.
///
/// Not a hand-made `FirmwareAutoUpdateUIModel`: the mapping has exactly one site
/// on purpose, and a fixture that bypassed it could pin a `status`/`rawState` pair
/// the router can never produce.
FirmwareAutoUpdateUIModel _reading(String state, int progress) =>
    UspFirmwareUpdateService.mapAutoUpdateStatus(
        FirmwareUpdateTestData.autoUpdate(
      fwupState: state,
      fwupProgress: '$progress',
    ));

void main() {
  group('what a percentage may be drawn from', () {
    test('downloading is the only state with a percentage', () {
      expect(FirmwareOtaInstallProgress.from(_reading('3', 45)).percent, 45);
    });

    test('checking has none, however far fwup_progress has run', () {
      // The ticket's `(1,57)` case. 57 is a real reading and it means nothing:
      // the same state was measured both sweeping 0→100 on its own and sitting
      // at 0 for the entire check.
      expect(
          FirmwareOtaInstallProgress.from(_reading('1', 57)).percent, isNull);
      expect(
          FirmwareOtaInstallProgress.from(_reading('1', 100)).percent, isNull);
    });

    test('installing has one, now that the flash has been watched', () {
      // `fwup_state=4` is the flash, and it had the indeterminate treatment while
      // nothing had been observed about `fwup_progress` during it — the bench could
      // never be made to find an image. A real install on 2026-09-16 published `0`
      // and then `50`, holding 50 for ~40s before the state moved on. Coarse and
      // plateau-prone, but a real number in a phase long enough to need one.
      expect(FirmwareOtaInstallProgress.from(_reading('4', 80)).percent, 80);
      expect(FirmwareOtaInstallProgress.from(_reading('4', 50)).percent, 50);
    });

    test('rebooting has none, whatever the flash left behind', () {
      // `fwup_state=5` arrives with `fwup_progress` at 100, and that 100 is the
      // flash finishing rather than the reboot progressing. A bar at 100% for the
      // length of a reboot claims the reboot is nearly done, which nothing knows.
      expect(
          FirmwareOtaInstallProgress.from(_reading('5', 100)).percent, isNull);
    });

    test('idle has none, at either of its two resting values', () {
      // `(0,0)` and `(0,100)` are both ordinary idle: the resting value depends
      // on which mode last ran. Neither may render as a bar at 0% or 100%.
      expect(FirmwareOtaInstallProgress.from(_reading('0', 0)).percent, isNull);
      expect(
          FirmwareOtaInstallProgress.from(_reading('0', 100)).percent, isNull);
    });

    test('a number outside 0..100 is clamped, not rejected', () {
      expect(FirmwareOtaInstallProgress.from(_reading('3', 140)).percent, 100);
      expect(FirmwareOtaInstallProgress.from(_reading('3', -5)).percent, 0);
    });

    test('carries the raw state through unparsed', () {
      // REQ-A7: an unrecognised state must still be reportable as the number the
      // router sent, and must not read as idle.
      final progress = FirmwareOtaInstallProgress.from(_reading('7', 12));
      expect(progress.rawState, '7');
      expect(progress.status, FirmwareAutoUpdateStatus.unknown);
      expect(progress.percent, isNull);
    });
  });

  /// The three sighting predicates, and the two places they deliberately differ.
  ///
  /// Each one licenses a different claim about a *later* verdict, so a state that
  /// slid from one into another would let the page say something the router never
  /// supported: `isInstalling` decides what to **draw**, `namesAnUpdatePhase`
  /// decides what a failure may be **blamed** on, and `namesRouterWork` decides
  /// whether an idle router has **concluded** anything.
  group('what a reading is evidence of', () {
    test('a check is the router working, but not an update running', () {
      // The install path's `idle` verdict turns on exactly this: mode 2 checks
      // before it downloads, so `1 → 0` is the router disagreeing about the
      // version — a real answer — while a dispatch that never left 0 has answered
      // nothing.
      final checking = FirmwareOtaInstallProgress.from(_reading('1', 0));

      expect(checking.namesRouterWork, isTrue);
      expect(checking.namesAnUpdatePhase, isFalse);
      expect(checking.isInstalling, isFalse);
      expect(checking.isRunning, isTrue);
    });

    test('an unrecognised state is drawn, and claimed for nothing', () {
      // REQ-A7 in one line. A value that cannot be ruled out being a flash must
      // keep the progress UI up (`isInstalling`), and is simultaneously the weakest
      // evidence there is — so neither a failure nor a "nothing was found" may be
      // built on it.
      final unknown = FirmwareOtaInstallProgress.from(_reading('9', 0));

      expect(unknown.isInstalling, isTrue);
      expect(unknown.namesRouterWork, isFalse);
      expect(unknown.namesAnUpdatePhase, isFalse);
    });

    test('downloading and installing are evidence of everything', () {
      for (final state in ['3', '4']) {
        final progress = FirmwareOtaInstallProgress.from(_reading(state, 20));
        expect(progress.namesAnUpdatePhase, isTrue,
            reason: 'fwup_state=$state');
        expect(progress.namesRouterWork, isTrue, reason: 'fwup_state=$state');
      }
    });

    test('idle alone is evidence of nothing', () {
      // `0` is the only value that is not evidence of work, and it carries three
      // meanings — nothing started, a check that began and ended between two polls,
      // and **every failure**, since `fwup_state` has no failure value. That is why
      // no caller may conclude anything from a lone 0.
      final progress = FirmwareOtaInstallProgress.from(_reading('0', 100));
      expect(progress.isRunning, isFalse);
      expect(progress.namesRouterWork, isFalse);
    });

    test('rebooting is the strongest evidence of all', () {
      // It used to be grouped with `0` as evidence of nothing, because 5 was read
      // as a failure. A router at 5 has already written the image, so it is both
      // running and unambiguously an update phase — and the exit guard depends on
      // that: the back arrow must stay vetoed while the router is restarting.
      final progress = FirmwareOtaInstallProgress.from(_reading('5', 100));
      expect(progress.isRunning, isTrue);
      expect(progress.namesAnUpdatePhase, isTrue);
      expect(progress.namesRouterWork, isTrue);
    });
  });

  group('advancing', () {
    test('within one state the number only rises', () {
      final at40 = FirmwareOtaInstallProgress.from(_reading('3', 40));
      final backwards = at40.advancedTo(_reading('3', 10));

      expect(backwards.percent, 40);
      expect(backwards.advancedTo(_reading('3', 60)).percent, 60);
    });

    test('a new state starts over', () {
      // `1/100 → 3/0` is the sequence mode 2 produces, and the reset is the
      // point: the download's 0% is not a regression from the check's 100%,
      // which is also why the check never showed one.
      final checked = FirmwareOtaInstallProgress.from(_reading('1', 100));
      final downloading = checked.advancedTo(_reading('3', 0));

      expect(downloading.rawState, '3');
      expect(downloading.percent, 0);
    });

    test('two different unrecognised states are two states', () {
      // Keyed on the raw value rather than on the mapped status, so `7` then `9`
      // — both `unknown` — do not merge into one phase whose progress can only
      // go up. The status is what the UI reads; the raw value is what changed.
      final at7 = FirmwareOtaInstallProgress.from(_reading('7', 90));
      final at9 = at7.advancedTo(_reading('9', 10));

      expect(at9.rawState, '9');
      expect(at9.rawProgress, 10);
    });

    test('is a value type', () {
      expect(FirmwareOtaInstallProgress.from(_reading('3', 45)),
          FirmwareOtaInstallProgress.from(_reading('3', 45)));
      expect(FirmwareOtaInstallProgress.from(_reading('3', 45)),
          isNot(FirmwareOtaInstallProgress.from(_reading('3', 46))));
    });
  });
}
