import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_failure.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_upload_strategy.dart';

class FirmwareUpdateState extends Equatable {
  final FirmwareUpdatePhase phase;
  final FirmwareImageUIModel? activeBank;
  final FirmwareImageUIModel? targetBank;
  final String? selectedFileName;
  final int? selectedFileSize;
  final String? selectedFileMd5;
  final int uploadedChunks;
  final int totalChunks;

  /// Why the update failed, as a value the view localizes.
  ///
  /// A `String? errorMessage` until this was localized, and that is the whole
  /// reason it is a value now: the notifier writes this field and the notifier has
  /// no `BuildContext`, so any sentence it could put here would be English in all
  /// 26 locales. See [FirmwareFailure] and `localizeFirmwareFailure`.
  final FirmwareFailure? failure;

  /// The upload method used for the current/last upload (null if not started).
  final UploadMethod? uploadMethod;

  /// What the last OTA check found, if one has run.
  ///
  /// One field where there used to be two (`otaInfo` + `otaUpToDate`), because a
  /// pair of independent flags could express "no info and not up to date", which
  /// is both the resting state and the state after a check that failed — and the
  /// card had no way to tell those from each other. See
  /// [FirmwareOtaCheckVerdict].
  final FirmwareOtaCheckResult otaCheck;

  /// Where a router-side OTA install has got to, if one is being watched.
  ///
  /// Only ever set from a `fwup_state` reading. **Absent means no reading has
  /// landed — not 0%**, which is why this is nullable rather than a default-zero
  /// progress: `fwup_progress` rests at both 0 and 100 depending on which `fwupd`
  /// mode last ran, so no value of it can stand in for "nothing known yet".
  ///
  /// Retained when the phase becomes [FirmwareUpdatePhase.failed] rather than
  /// cleared, and deliberately **not rendered there**. It is the record of how far
  /// the attempt got, including a `rawState` this build does not recognise; what
  /// the user is shown is [failure], which already carries that number. A
  /// percentage cannot be shown on a failure card in any case — the last reading
  /// before a failure *is* the failing one, and
  /// [FirmwareOtaInstallProgress.percent] is null for every status except
  /// `downloading`. Cleared by the next [FirmwareUpdatePhase.triggering] and by
  /// `cancel()`.
  final FirmwareOtaInstallProgress? otaProgress;

  /// Why the router's firmware state could not be read.
  ///
  /// Separate from [failure] because the two are different events with
  /// different copy and different retries: [failure] is an update that was
  /// attempted and went wrong, this is a page that has nothing to show. Reporting
  /// a failed read as an update failure — which is what `loadBanks()` used to do —
  /// paints "Update Failed / Try Again" over a router nobody has touched, and its
  /// Try Again starts an update instead of re-reading.
  final String? stateReadError;

  const FirmwareUpdateState({
    this.phase = FirmwareUpdatePhase.idle,
    this.activeBank,
    this.targetBank,
    this.selectedFileName,
    this.selectedFileSize,
    this.selectedFileMd5,
    this.uploadedChunks = 0,
    this.totalChunks = 0,
    this.failure,
    this.uploadMethod,
    this.otaCheck = const FirmwareOtaCheckResult.notChecked(),
    this.otaProgress,
    this.stateReadError,
  });

  double get uploadProgress =>
      totalChunks == 0 ? 0.0 : uploadedChunks / totalChunks;

  /// True if firmware update is in progress and navigation should be blocked.
  bool get isUpdating =>
      phase != FirmwareUpdatePhase.idle &&
      phase != FirmwareUpdatePhase.done &&
      phase != FirmwareUpdatePhase.failed;

  /// A copy with some fields replaced, and three that can be *cleared*.
  ///
  /// Every field here is `?? this.x`, which cannot express "set this back to
  /// null": an absent named argument and an explicit `null` are the same value in
  /// Dart. So the three fields that genuinely need clearing get a flag each rather
  /// than a sentinel, and passing `failure: null` is a no-op — it used to
  /// read like a clear at four call sites and do nothing.
  ///
  /// A flag beats making these fields nullable-with-sentinel because the compiler
  /// can see it, and beats adding a clear flag to all thirteen because the other
  /// ten have no caller that wants one.
  FirmwareUpdateState copyWith({
    FirmwareUpdatePhase? phase,
    FirmwareImageUIModel? activeBank,
    FirmwareImageUIModel? targetBank,
    String? selectedFileName,
    int? selectedFileSize,
    String? selectedFileMd5,
    int? uploadedChunks,
    int? totalChunks,
    FirmwareFailure? failure,
    UploadMethod? uploadMethod,
    FirmwareOtaCheckResult? otaCheck,
    FirmwareOtaInstallProgress? otaProgress,
    String? stateReadError,
    bool clearFailure = false,
    bool clearOtaProgress = false,
    bool clearStateReadError = false,
  }) {
    return FirmwareUpdateState(
      phase: phase ?? this.phase,
      activeBank: activeBank ?? this.activeBank,
      targetBank: targetBank ?? this.targetBank,
      selectedFileName: selectedFileName ?? this.selectedFileName,
      selectedFileSize: selectedFileSize ?? this.selectedFileSize,
      selectedFileMd5: selectedFileMd5 ?? this.selectedFileMd5,
      uploadedChunks: uploadedChunks ?? this.uploadedChunks,
      totalChunks: totalChunks ?? this.totalChunks,
      // The clear wins when both are given: it is the more explicit of the two,
      // where a value can also arrive from an unrelated `??` further up.
      failure: clearFailure ? null : failure ?? this.failure,
      uploadMethod: uploadMethod ?? this.uploadMethod,
      otaCheck: otaCheck ?? this.otaCheck,
      otaProgress: clearOtaProgress ? null : otaProgress ?? this.otaProgress,
      stateReadError:
          clearStateReadError ? null : stateReadError ?? this.stateReadError,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        activeBank,
        targetBank,
        selectedFileName,
        selectedFileSize,
        selectedFileMd5,
        uploadedChunks,
        totalChunks,
        failure,
        uploadMethod,
        otaCheck,
        otaProgress,
        stateReadError,
      ];
}
