import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// What the router's own firmware-update daemon is doing, as read from
/// `Device.X_LINKSYS_Sysevent.fwup_state`.
///
/// Deliberately not exhaustive over the raw value space: [unknown] is the arm
/// for anything the firmware reports that is not listed here, so a future
/// firmware adding a sixth value costs one enum value and one arm, not a
/// redesign.
///
/// **Every arm below is now measured on `2.0.1.26091515` (2026-09-16), and one of
/// them was wrong.** A full OTA install was observed end to end — `1 → 4 → 5`,
/// then a reboot into the offered build. The corrections, and the sources, are on
/// [rebooting]: this enum previously had a `failed` arm on `5`, which reported
/// every successful install as a failure.
///
/// **`fwup_state` has no failure value at all.** Two failure paths were induced on
/// the bench (`fwupd -m 1` against a refused port, and against a server that
/// answers but offers nothing) and `fwupd`'s own debug output writes
/// `set_stateprogress: state 0` for both, leaving `fwup_progress` at 100. So a
/// failure arrives here as [idle] — which is why the install watcher decides
/// nothing from a lone `0` and why a genuine flash failure is caught after the
/// reboot instead, by comparing versions (`FirmwareFailure.bootedOldImage`).
enum FirmwareAutoUpdateStatus {
  /// Nothing running — **and where every failure lands**, per the class comment.
  ///
  /// Also the value while a check that started and finished between two polls was
  /// in flight, so it does not mean "no check has happened" either. Three
  /// meanings on one value is why no caller may conclude anything from it alone.
  idle,

  /// Asking the OTA server whether a newer build exists.
  ///
  /// Measured at 6.5s on a real install (`10:53:20`–`10:53:26`), not the
  /// sub-second it was documented as: `Download(ota, AutoActivate="true")` is
  /// `fwupd -m 2`, which checks before it downloads.
  checking,

  /// Downloading the image.
  downloading,

  /// Writing the downloaded image to the spare bank. A reboot follows.
  installing,

  /// The router has committed and is rebooting into the new bank. **A success
  /// signal, not a failure.**
  ///
  /// `fwup_state=5`, and it was mapped to a `failed` arm until 2026-09-16. Four
  /// independent sources say reboot:
  ///
  /// * `/usr/sbin/update_nodes_defs:45-48` — the firmware's own constant table:
  ///   `SYS_STATE_CHECKING=1`, `SYS_STATE_DOWNLOADING=3`, `SYS_STATE_FLASHING=4`,
  ///   `SYS_STATE_REBOOT=5`. There is no error constant.
  /// * `fwupd`'s own usage text for the mode this app dispatches:
  ///   `2: checking / downloading / flashing / rebooting` — four phases, and 5 is
  ///   the fourth.
  /// * `/lib/service_autofwup.sh`'s `fwup_updating()` treats `state > 2` as still
  ///   updating, 5 included.
  /// * The observed install: 5 was read at `10:54:10`, the router rebooted, and it
  ///   came back running the offered `2.0.1.26091516` with `boot_part` moved from
  ///   2 to 1.
  ///
  /// **Where `5 = error` came from, since it was not invented here.**
  /// `Architecture#194`'s design comment lists `fwup_state` as `0=Idle, 1=Checking,
  /// 3=Downloading, 4=Flashing` — 5 is absent from its own table — and then its
  /// proposed C carries `case 5: return "InstallationFailed"; // error`. The
  /// shipped `sysmngr` implements exactly that, measured by driving the sysevent:
  /// `FirmwareImage.3.Status` reads `InstallationFailed` at `fwup_state=5`. So the
  /// router publishes an install failure over TR-181 every time an install
  /// succeeds, `usp_framework`'s `firmware_auto_update.yaml` inherited the same
  /// `"5" = Error`, and this app inherited it from there. Only the app half is
  /// fixed here; the other two are cross-repo.
  rebooting,

  /// The firmware reported a value this build does not define. Rendered as an
  /// unknown state, never silently as [idle].
  unknown,
}

/// What the router is allowed to do by itself when a newer build exists, as read
/// from `Device.X_LINKSYS_UCI.linksys.fwup.autoupdate_flags`.
///
/// The app's switch is binary over three values, and which two it writes is a
/// product decision rather than an arithmetic one (Austin, 2026-09-14): **off
/// writes [notifyOnly], not [off]**. A router that stops checking can never tell
/// the app an update exists, so writing `0` would silently disable the dashboard
/// banner as well — and "don't install things behind my back" is not the same
/// request as "never look".
enum FirmwareAutoUpdatePolicy {
  /// `0` — the router neither checks nor installs.
  ///
  /// Read, never written: a router can arrive here from the factory, from a
  /// previous firmware or from the CLI, and the switch has to be able to show it.
  off('0'),

  /// `1` — keep checking, install nothing. What the switch writes when turned
  /// off, and the one mode the dashboard banner exists to serve.
  notifyOnly('1'),

  /// `2` — check and install unattended. The firmware's own default, and what the
  /// switch writes when turned on.
  autoInstall('2'),

  /// A value this build does not define. Never silently treated as [off], for the
  /// same reason [FirmwareAutoUpdateStatus.unknown] is never treated as idle.
  unknown('');

  const FirmwareAutoUpdatePolicy(this.rawValue);

  /// The string this app writes to `autoupdate_flags` for this policy. Empty for
  /// [unknown], which is why writing it is rejected rather than sent.
  final String rawValue;

  /// The policy a raw `autoupdate_flags` reading means.
  static FirmwareAutoUpdatePolicy fromRaw(String raw) => switch (raw) {
        '0' => off,
        '1' => notifyOnly,
        '2' => autoInstall,
        _ => unknown,
      };
}

/// Why the router's last firmware operation failed, as read from
/// `Device.X_LINKSYS_Sysevent.fwup_error_code`.
///
/// Not a sysevent despite the path: `dm-reflector` computes it at read time by
/// substring-matching the UCI value `linksys.fwup.newfirmware_status_details`, which
/// is why `sysevent get fwup_error_code` returns nothing on a router that answers
/// this parameter perfectly well over USP. The consequence for us is that the value
/// has **no run identity and no timestamp** — see [FirmwareAutoUpdateUIModel.errorCode]
/// for the rule that follows from it.
///
/// Measured on the bench (M60, FW `2.0.1.26091601`, 2026-09-17): a check against
/// a refused port produced `newfirmware_status_details = "ERROR: Connecting server"`
/// and this parameter read `1`; an interrupted run produced `"ERROR: Interrupted"` and
/// `7`. [serverResponse] could not be induced — a server answering HTTP 404 left the
/// details empty and the code at `0` — so it is mapped on the strength of the
/// definition rather than of a measurement.
enum FirmwareUpdateErrorCode {
  /// `0` — the last operation did not fail. **Also the value during one**, since the
  /// details are cleared when a run starts, so it never means "finished cleanly".
  none,

  /// `1` — could not reach the update server.
  serverUnreachable,

  /// `2` — the server answered, but not with something `fwupd` could use.
  serverResponse,

  /// `3` — the image could not be fetched.
  download,

  /// `4` — the image could not be written to the spare bank.
  flash,

  /// `5` — the image failed signature verification.
  signature,

  /// `6` — the router reported a failure with no reason of its own.
  ///
  /// Distinct from [unknown] and from [unreported], and all three have to stay
  /// distinct: this one is the router saying "it broke and I do not know why", which
  /// is a fact worth showing. The other two are the app not being told anything.
  routerUnspecified,

  /// `7` — a run was interrupted: `fwupd` died, or a watchdog killed it.
  ///
  /// **A post-hoc diagnostic, never a live signal.** The shell that writes it runs
  /// from `cron_every_minute`, and `/etc/crontabs/root` schedules that handler
  /// **hourly** — measured 2026-09-17: `fwupd` killed at `fwup_state=1` left the
  /// state at `1` with this code still `0` seventy-five seconds later. So nothing may
  /// wait for it, and a stuck `fwup_state` is bounded only by the app's own ceiling.
  interrupted,

  /// A code this build does not define. The definition reserves `8+`, so this arm is
  /// the forward-compatibility one, and it must never render as a failure sentence —
  /// an unrecognised number is not a reason.
  unknown,

  /// The router did not report the parameter at all.
  ///
  /// A separate value from [unknown] rather than a sentinel in it, for the reason the
  /// definition was changed before merge: `optional: true` with a `default_value`
  /// would have made this indistinguishable from [none], and "no error" is a claim
  /// while "nobody told me" is not.
  unreported;

  /// The code a raw reading means, or [unreported] for an absent parameter.
  static FirmwareUpdateErrorCode fromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return unreported;
    return switch (raw) {
      '0' => none,
      '1' => serverUnreachable,
      '2' => serverResponse,
      '3' => download,
      '4' => flash,
      '5' => signature,
      '6' => routerUnspecified,
      '7' => interrupted,
      _ => unknown,
    };
  }

  /// Whether this code names a failure the app is allowed to report.
  ///
  /// Everything except the three that are not failures. [unknown] is out on purpose:
  /// it is the weakest possible evidence of anything, and the cost of excluding it is
  /// only that a verdict is withheld — the same trade
  /// `FirmwareOtaInstallProgress.namesAnUpdatePhase` makes for an unrecognised state.
  bool get isFailure => this != none && this != unknown && this != unreported;

  /// Whether a *check* could have produced this code.
  ///
  /// [download], [flash] and [signature] could not: by definition they happen after a
  /// check has already succeeded and found something. So a line that says "last check
  /// did not finish" must not be drawn for them — a failed flash would be reported as
  /// a failed check, on the very check that found the update. [interrupted] is in
  /// because a watchdog can kill a check as readily as a flash, and
  /// [routerUnspecified] is in because it names no phase at all.
  bool get couldBeACheck =>
      this == serverUnreachable ||
      this == serverResponse ||
      this == routerUnspecified ||
      this == interrupted;
}

/// Who started the router's last firmware operation, as read from
/// `Device.X_LINKSYS_Sysevent.fwup_trigger_source`.
///
/// **Mapped for logs and bug reports, and never rendered.** Measured 2026-09-17: the
/// verb this app dispatches — `FirmwareImage.{ota}.Download()` — does **not** set the
/// parameter, while `sysevent set update_firmware_now` does. So an operation started
/// from this app, from another tab, or from another client all leave whatever the
/// previous operation wrote, and no reading distinguishes "this run was automatic"
/// from "the last automatic run was, and nobody has overwritten it since". A card
/// saying "your router started this on its own" would therefore say it about an
/// update a person started.
enum FirmwareUpdateTriggerSource {
  /// The forced check on first boot. Observed live on the bench.
  boot,

  /// The scheduled check.
  auto,

  /// A user-initiated operation — but only via `update_firmware_now`; see the class
  /// comment for why this app never causes it.
  user,

  /// Backhaul recovery.
  recovery,

  /// A value this build does not define. The definition reserves `upload` and `mesh`
  /// for a later phase, and this arm is what absorbs them at no cost.
  unknown,

  /// The router did not report the parameter, or it was cleared on boot and nothing
  /// has run since.
  unreported;

  static FirmwareUpdateTriggerSource fromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return unreported;
    return switch (raw) {
      'boot' => boot,
      'auto' => auto,
      'user' => user,
      'recovery' => recovery,
      _ => unknown,
    };
  }
}

/// Reads the router's auto-update state in one round trip.
///
/// Declared here, beside the model it returns, rather than in either service that
/// takes it. Both did, under different names, and the reason given was that the check
/// service must not import the install service — which is true, and is met by the
/// *service* boundary, not by the typedef. A shared signature in a neutral file
/// removes the duplication without creating that import: from inside either service
/// `FirmwareRouterOtaInstallService` is still unnameable.
typedef FirmwareAutoUpdateReader = Future<FirmwareAutoUpdateUIModel> Function();

/// The router's auto-update progress, mapped once in the service layer.
class FirmwareAutoUpdateUIModel extends Equatable with DiagnosticLoggable {
  final FirmwareAutoUpdateStatus status;

  /// `fwup_progress`, 0–100. Only meaningful **within** [status]: an install runs
  /// a check first, so the raw value sweeps 0→100 twice over one install, and its
  /// resting value after a check has been measured as both `0` and `100`. Never
  /// read it as an overall percentage and never read `100` as "just finished".
  final int progress;

  /// The raw `fwup_state` string exactly as the router reported it, kept for
  /// every status rather than only failures so diagnostics of an [unknown] value
  /// have the value itself.
  final String rawState;

  /// What the router may do on its own — the setting the OTA card's switch owns.
  ///
  /// On the same model as [status] because it arrives in the same `Get`: one fetch,
  /// one mapping site. They are not the same kind of value, though — this one is
  /// written by the user and that one only observed.
  final FirmwareAutoUpdatePolicy policy;

  /// `autoupdate_flags` exactly as the router reported it, kept for the same
  /// reason as [rawState] and read by [checksForUpdates].
  final String rawFlags;

  /// Why the last operation failed — **and not, by itself, whose failure it is.**
  ///
  /// The underlying UCI value is cleared on every boot and at the start of every
  /// `fwupd` run *before any work*, which was measured rather than taken on trust: on
  /// a good check dispatched over a standing code `1`, the clear landed in the same
  /// 220 ms sample that `fwup_state` became `1`, and no sample ever showed a started
  /// run beside the previous run's code. So a non-zero code read **after a run this
  /// app dispatched was seen to start** belongs to that run.
  ///
  /// A code read cold — on page open, with nothing dispatched — does not. The
  /// definition says so itself: with `autoupdate_flags=0` the error "persists until
  /// the next user-triggered operation or the next reboot", so a check that failed at
  /// 09:00 still reads its code at 17:00. There is no timestamp, and
  /// `fwup_checked_after_boot` plus this cannot supply one. Reporting it as *this*
  /// update's failure is the mistake that once told users a healthy router had failed.
  final FirmwareUpdateErrorCode errorCode;

  /// `fwup_error_code` exactly as the router reported it, or null when the parameter
  /// was absent. Kept for the same reason as [rawState]: a diagnostic of
  /// [FirmwareUpdateErrorCode.unknown] needs the number itself.
  final String? rawErrorCode;

  /// Who started the last operation, for logs only — see
  /// [FirmwareUpdateTriggerSource] for why it is never rendered.
  final FirmwareUpdateTriggerSource triggerSource;

  /// Whether `fwupd` has run since boot, or null when the router did not say.
  ///
  /// Three states rather than a `bool`, and the third is the point: `false` is the
  /// router telling us it has not checked, and null is the router not answering. Only
  /// the first may become "not checked yet" on screen.
  ///
  /// A one-way latch — measured going `0`→`1` after the boot check and staying — so it
  /// answers "has anything checked since boot" and cannot answer "has the check I
  /// just started finished".
  final bool? checkedAfterBoot;

  const FirmwareAutoUpdateUIModel({
    required this.status,
    required this.progress,
    required this.rawState,
    required this.policy,
    required this.rawFlags,
    this.errorCode = FirmwareUpdateErrorCode.unreported,
    this.rawErrorCode,
    this.triggerSource = FirmwareUpdateTriggerSource.unreported,
    this.checkedAfterBoot,
  });

  /// Whether the router looks for newer builds at all — REQ-C3's `flags > 0`,
  /// which is half of what puts the dashboard banner on screen.
  ///
  /// Read off [rawFlags] rather than off [policy] deliberately. The requirement is
  /// a numeric comparison, and an unrecognised positive value (say a firmware that
  /// adds a `3`) is a router that is checking — withholding a banner for an update
  /// the router has already *found* would hide real information behind a gap in
  /// this app's enum.
  bool get checksForUpdates => (int.tryParse(rawFlags) ?? 0) > 0;

  /// The same reading with a different policy — the one field a user can change.
  ///
  /// Deliberately narrower than a `copyWith`: [status], [progress] and
  /// [rawState] describe what the daemon is doing, and a policy write is not an
  /// observation of that, so no caller should be able to rewrite them from the
  /// UI side. [rawFlags] moves with [policy] because a confirmed write means the
  /// router now holds exactly [FirmwareAutoUpdatePolicy.rawValue].
  FirmwareAutoUpdateUIModel withPolicy(FirmwareAutoUpdatePolicy newPolicy) =>
      FirmwareAutoUpdateUIModel(
        status: status,
        progress: progress,
        rawState: rawState,
        policy: newPolicy,
        rawFlags: newPolicy.rawValue,
        // Carried, not reset: a policy write changes what the router is allowed to
        // do next and says nothing about what its last operation did.
        errorCode: errorCode,
        rawErrorCode: rawErrorCode,
        triggerSource: triggerSource,
        checkedAfterBoot: checkedAfterBoot,
      );

  /// True while the router is doing work the user should see a progress view
  /// for. A router with `autoupdate_flags` at its default can enter these states
  /// without anyone pressing anything.
  bool get isBusy =>
      status == FirmwareAutoUpdateStatus.checking ||
      status == FirmwareAutoUpdateStatus.downloading ||
      status == FirmwareAutoUpdateStatus.installing;

  @override
  String get diagnosticName => 'FirmwareAutoUpdateUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'status': status,
        'progress': progress,
        'rawState': rawState,
        'policy': policy,
        'errorCode': errorCode,
        'rawErrorCode': rawErrorCode,
        'triggerSource': triggerSource,
        'checkedAfterBoot': checkedAfterBoot,
        'rawFlags': rawFlags,
      };
}
