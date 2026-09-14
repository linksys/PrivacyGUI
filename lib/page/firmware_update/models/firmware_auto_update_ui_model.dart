import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// What the router's own firmware-update daemon is doing, as read from
/// `Device.X_LINKSYS_Sysevent.fwup_state`.
///
/// Deliberately not exhaustive over the raw value space: [unknown] is the arm
/// for anything the firmware reports that is not listed here. Only `0` has ever
/// been observed on real hardware — the bench points at a stage OTA server with
/// no newer build — so every other arm is written from the data-model
/// definition, and a future firmware adding a sixth value must cost one enum
/// value and one arm, not a redesign.
enum FirmwareAutoUpdateStatus {
  /// Nothing running. Note this is also the value while a check that started and
  /// finished between two polls was in flight, so it does not mean "no check has
  /// happened".
  idle,

  /// Asking the OTA server whether a newer build exists. Measured to last well
  /// under a second, so it is usually not observable.
  checking,

  /// Downloading the image. This is the only phase where a percentage means
  /// anything to the user.
  downloading,

  /// Writing the downloaded image to the spare bank. A reboot follows.
  installing,

  /// The daemon reported a failure. Download failure and flash failure share
  /// this value, so they cannot be told apart — see [FirmwareAutoUpdateUIModel
  /// .rawState], which keeps the number the router sent so a future split does
  /// not need a new data path.
  failed,

  /// The firmware reported a value this build does not define. Rendered as an
  /// unknown state, never silently as [idle].
  unknown,
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

  const FirmwareAutoUpdateUIModel({
    required this.status,
    required this.progress,
    required this.rawState,
  });

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
      };
}
