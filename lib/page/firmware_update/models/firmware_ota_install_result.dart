import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';

/// How watching a router-side firmware update ended.
///
/// Five values because the caller does five different things, and the split is
/// drawn where the *action* differs rather than where the reading does.
enum FirmwareOtaInstallVerdict {
  /// The router is committed and is going to reboot.
  ///
  /// Reached three ways, all of them meaning the same thing to a caller: the read
  /// started failing after `fwup_state` had reached 3 or 4 (the reboot took the
  /// connection with it), the state returned to 0 after having been busy, or the
  /// ceiling elapsed with it still busy. The caller waits for the router to come
  /// back — `enterRecoveryWaiting()` and then `verify()`.
  ///
  /// It is deliberately *not* "the update succeeded". Nothing observable at this
  /// point says the flash worked; `verify()` is what says that, and only for the
  /// master (see the mesh known issues on #1547).
  flashing,

  /// The router is not updating.
  ///
  /// On the install path this is the boundary case `AutoActivate="true"` creates:
  /// mode 2 checks *before* it downloads, so a dispatch can be accepted and then
  /// find nothing to fetch — the version we offered has since been superseded or
  /// was never really there. On the observe path it simply means the update that
  /// was running has stopped being visible.
  idle,

  /// The router named a reason the update failed —
  /// [FirmwareOtaInstallResult.errorCode] is which one.
  ///
  /// **This verdict was deleted on 2026-09-16 and is back for a different reason.**
  /// The version that went away keyed off `fwup_state=5`, which is measured to be
  /// the reboot — see [FirmwareAutoUpdateStatus.rebooting] — so nothing could reach
  /// it that was not a success. `fwup_state` still publishes no failure value at
  /// all; what changed is that `fwup_error_code` does
  /// (`linksys/usp_framework#66`), so there is finally something to report a
  /// failure *from* rather than a state to misread.
  ///
  /// It does not replace `verify()`. A flash that fails silently — no code, wrong
  /// bank booted — is still only separable after the reboot by comparing versions,
  /// and `FirmwareFailure.bootedOldImage` is still the answer for it. This verdict
  /// is the case where the router says so before the reboot, which saves the user
  /// the wait rather than replacing the check.
  failed,

  /// The ceiling elapsed and the update never got as far as downloading.
  ///
  /// Distinct from [idle] because nothing concluded: the state sat at `1`, or at a
  /// value this build does not recognise, for the whole window. Reporting that as
  /// "no update found" would be the one substitution this feature is written to
  /// avoid.
  timedOut,

  /// The caller stopped watching — the page was left, or the flow was cancelled.
  ///
  /// A verdict rather than an exception because nothing went wrong; the poll loop
  /// has to have a way to say "I was asked to stop" that a caller can ignore
  /// without catching anything.
  abandoned,
}

/// The outcome of one `install()` or `observe()`, with the evidence for it.
class FirmwareOtaInstallResult extends Equatable {
  final FirmwareOtaInstallVerdict verdict;

  /// The router's own reason, for [FirmwareOtaInstallVerdict.failed] only.
  final FirmwareUpdateErrorCode? errorCode;

  /// `fwup_state` as the router last spelled it, or empty if it was never read.
  ///
  /// Carried separately from [lastProgress] so REQ-A7 holds without the UI having
  /// to reach through a nullable: a failure keeps the number the router sent, even
  /// when that number is one this build does not recognise.
  final String rawState;

  /// The last reading taken, for a failure card that wants to say where it stopped.
  final FirmwareOtaInstallProgress? lastProgress;

  const FirmwareOtaInstallResult({
    required this.verdict,
    this.rawState = '',
    this.lastProgress,
    this.errorCode,
  }) : assert(
            verdict != FirmwareOtaInstallVerdict.failed ||
                (errorCode != null &&
                    errorCode != FirmwareUpdateErrorCode.none &&
                    errorCode != FirmwareUpdateErrorCode.unknown &&
                    errorCode != FirmwareUpdateErrorCode.unreported),
            'a failed verdict needs a reason the router actually named');

  bool get isFlashing => verdict == FirmwareOtaInstallVerdict.flashing;

  @override
  List<Object?> get props => [verdict, rawState, lastProgress, errorCode];
}
