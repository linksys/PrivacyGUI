import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';

/// One reading of where a router-side firmware update has got to.
///
/// A thin view over the two parameters the router publishes — `fwup_state` and
/// `fwup_progress` — and it exists for one reason: **only one of the two is
/// readable, and only in one of the states.** Everything below is a measurement,
/// not a policy:
///
/// * `fwup_progress` was measured sweeping 0→100 during `fwup_state=1` on one run
///   and staying at 0 for the whole of the same phase on another. A number with
///   two behaviours is not a number a bar can render, so [percent] is null there.
/// * `Download(ota, AutoActivate="true")` is `fwupd -m 2`, whose own usage string
///   reads `checking / downloading / flashing / rebooting`. So one install
///   produces `1 → 3 → 4 → 5`, and `fwup_progress` runs 0→100 more than once. One
///   shared bar would therefore show the same install completing twice, which is
///   why `checking` has no percentage.
/// * **A real install skipped `3` entirely** (2026-09-16, `2.0.1.26091515` →
///   `...16`): the sequence observed was `1 → 4 → 5`, so `downloading` is not a
///   phase a user is guaranteed to see and nothing may wait for it. The image was
///   already cached, or the router folds the fetch into the flash.
/// * `fwup_progress` rests at both `0` and `100` when nothing is running,
///   depending on which mode last ran, so no value of it means "finished". A
///   *failure* also rests at 100 — `fwupd` writes `state 0, progress 100` on both
///   induced failure paths — so a 100 is not even evidence of success.
///
/// It reuses [FirmwareAutoUpdateStatus] rather than declaring a parallel enum: the
/// raw-to-app mapping has exactly one site (`mapAutoUpdateStatus`), and a second
/// enum over the same five values would need a second one.
class FirmwareOtaInstallProgress extends Equatable {
  /// What the router is doing, as the single mapping site reads it.
  final FirmwareAutoUpdateStatus status;

  /// `fwup_progress` verbatim, before clamping and regardless of [status].
  ///
  /// Kept even where it cannot be rendered, because it is the number a bug report
  /// needs and dropping it would make "the bar was stuck" unanswerable.
  final int rawProgress;

  /// `fwup_state` as the router spelled it.
  ///
  /// The identity of the phase, and not derived from [status]: two unrecognised
  /// values both map to [FirmwareAutoUpdateStatus.unknown] while being two
  /// different phases, and [advancedTo] has to be able to tell them apart.
  final String rawState;

  const FirmwareOtaInstallProgress({
    required this.status,
    required this.rawProgress,
    required this.rawState,
  });

  factory FirmwareOtaInstallProgress.from(FirmwareAutoUpdateUIModel reading) =>
      FirmwareOtaInstallProgress(
        status: reading.status,
        rawProgress: reading.progress,
        rawState: reading.rawState,
      );

  /// The number a determinate progress bar may show, or null for a spinner.
  ///
  /// Non-null for `downloading` and `installing`. The second one was excluded as
  /// "never observed" until 2026-09-16, when a full install was watched: during
  /// `fwup_state=4` the router published `0`, then `50`, and held 50 for ~40s
  /// before the state moved on. So it is coarse and it plateaus — which is worth
  /// knowing before "the bar is stuck at 50%" is filed as a bug — but it is a real
  /// number in a phase that lasts long enough to need one, and a bar that moves
  /// once beats a spinner that says nothing for three quarters of a minute.
  ///
  /// Still null for `checking` even though mode 2's check does publish numbers:
  /// the class comment's first bullet is why — the same phase was measured
  /// sweeping 0→100 on one run and staying at 0 on another. And still null for
  /// `rebooting`, where the 100 the router leaves behind is the *flash* finishing,
  /// not the reboot progressing.
  int? get percent => status == FirmwareAutoUpdateStatus.downloading ||
          status == FirmwareAutoUpdateStatus.installing
      ? min(100, max(0, rawProgress))
      : null;

  /// Whether the router is doing something a user should be shown.
  ///
  /// Everything except `idle`. `rebooting` is in — it is the last thing the router
  /// says before the connection drops, and the card it draws is the one that tells
  /// the user not to unplug anything.
  bool get isRunning => status != FirmwareAutoUpdateStatus.idle;

  /// Whether this reading is an update **in progress**, as opposed to merely
  /// something happening.
  ///
  /// [isRunning] minus `checking`, and the difference between the two is the whole
  /// reason both exist. `fwup_state=1` is `fwupd` deciding whether an image exists,
  /// and the auto-update daemon reaches it on its own schedule — so on the observe
  /// path (REQ-A6, an update this app did not start) a reading of 1 says only that
  /// a routine check is under way. Treating that as an update in progress moves the
  /// phase to `installing`, which is `isUpdating`, which `_firmwareExitGuard`
  /// vetoes the back arrow on: a user who opened the OTA page during a scheduled
  /// check could not leave it.
  ///
  /// `unknown` stays in, deliberately. REQ-A7: an unrecognised `fwup_state` cannot
  /// be ruled out being a flash, and offering "Update Now" to a router that is
  /// writing NAND is the worse of the two mistakes — the service's twenty-minute
  /// ceiling bounds how long it can be wrong.
  ///
  /// The install path uses [isRunning] instead, because there the check is mode 2's
  /// own first step: something *was* started, and "Checking for new firmware" is
  /// the accurate card for it.
  bool get isInstalling =>
      isRunning && status != FirmwareAutoUpdateStatus.checking;

  /// Whether this reading names a phase that could only be an update.
  ///
  /// [isInstalling] minus `unknown`, and the pair differ for one purpose: what a
  /// *later* verdict is allowed to be blamed on. [isInstalling] decides what to
  /// **draw**, and REQ-A7 is why `unknown` is drawn — a value that cannot be ruled
  /// out being a flash must not read as "nothing is happening". This decides what
  /// to **claim**, and there `unknown` is the opposite: an unrecognised value is
  /// the weakest possible evidence that an update was running, so a watch whose
  /// only sighting was one must not go on to report "the firmware update failed"
  /// for an update it never identified.
  ///
  /// `checking` is out for the reason [isInstalling] gives — the auto-update daemon
  /// reaches `fwup_state=1` on its own schedule, so it is not evidence of an
  /// install either.
  /// `rebooting` counts, and it is the strongest of the three: a router at
  /// `fwup_state=5` has already written the image.
  bool get namesAnUpdatePhase =>
      status == FirmwareAutoUpdateStatus.downloading ||
      status == FirmwareAutoUpdateStatus.installing ||
      status == FirmwareAutoUpdateStatus.rebooting;

  /// Whether this reading names something `fwupd` was actually doing.
  ///
  /// [namesAnUpdatePhase] plus `checking`, and the third predicate exists for the
  /// one verdict that needs the *check* to count as work. `Download(ota,"true")` is
  /// `fwupd -m 2`, which checks before it downloads, so a dispatched install can
  /// legitimately end at `fwup_state=0` — but only a run that was seen reaching 1
  /// has concluded anything. A dispatch that never moved `fwup_state` at all has
  /// concluded nothing, which is the shape of the firmware defect measured on
  /// `2.0.1.26091319`: the trigger is accepted and never consumed.
  ///
  /// `unknown` stays out, for the reason [namesAnUpdatePhase] gives — an
  /// unrecognised value is the weakest possible evidence of anything — and here the
  /// cost of excluding it is only that a verdict is withheld.
  bool get namesRouterWork =>
      namesAnUpdatePhase || status == FirmwareAutoUpdateStatus.checking;

  /// This reading updated by the next one, without ever walking backwards.
  ///
  /// Within one `fwup_state` the number only rises: the parameter is a sampled
  /// sysevent read by a poller, so an older sample can arrive after a newer one
  /// has been shown, and a bar that dropped from 60% to 10% would be reporting the
  /// sampling rather than the download.
  ///
  /// A change of `fwup_state` resets it, because the phases do not share a scale —
  /// `1` finishing at 100 and `3` starting at 0 is one install, not a regression.
  FirmwareOtaInstallProgress advancedTo(FirmwareAutoUpdateUIModel reading) {
    final next = FirmwareOtaInstallProgress.from(reading);
    if (next.rawState != rawState) return next;
    return FirmwareOtaInstallProgress(
      status: next.status,
      rawProgress: max(rawProgress, next.rawProgress),
      rawState: next.rawState,
    );
  }

  @override
  List<Object?> get props => [status, rawProgress, rawState];
}
