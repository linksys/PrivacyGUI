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

  const FirmwareAutoUpdateUIModel({
    required this.status,
    required this.progress,
    required this.rawState,
    required this.policy,
    required this.rawFlags,
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
        'rawFlags': rawFlags,
      };
}
