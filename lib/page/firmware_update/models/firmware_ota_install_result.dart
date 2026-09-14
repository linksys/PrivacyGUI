import 'package:equatable/equatable.dart';
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

  /// `fwup_state=5`. The router said the update failed.
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
  });

  bool get isFlashing => verdict == FirmwareOtaInstallVerdict.flashing;

  @override
  List<Object?> get props => [verdict, rawState, lastProgress];
}
