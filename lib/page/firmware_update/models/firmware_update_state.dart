import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_info.dart';
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
  final String? targetStatus;
  final Duration? rebootRemaining;
  final String? errorMessage;

  /// The upload method used for the current/last upload (null if not started).
  final UploadMethod? uploadMethod;

  /// OTA check result: available update info, or null if up to date / not checked.
  final FirmwareOtaInfo? otaInfo;

  /// Whether OTA check has been performed and no update was found.
  final bool otaUpToDate;

  const FirmwareUpdateState({
    this.phase = FirmwareUpdatePhase.idle,
    this.activeBank,
    this.targetBank,
    this.selectedFileName,
    this.selectedFileSize,
    this.selectedFileMd5,
    this.uploadedChunks = 0,
    this.totalChunks = 0,
    this.targetStatus,
    this.rebootRemaining,
    this.errorMessage,
    this.uploadMethod,
    this.otaInfo,
    this.otaUpToDate = false,
  });

  double get uploadProgress =>
      totalChunks == 0 ? 0.0 : uploadedChunks / totalChunks;

  /// True if firmware update is in progress and navigation should be blocked.
  bool get isUpdating =>
      phase != FirmwareUpdatePhase.idle &&
      phase != FirmwareUpdatePhase.done &&
      phase != FirmwareUpdatePhase.failed;

  FirmwareUpdateState copyWith({
    FirmwareUpdatePhase? phase,
    FirmwareImageUIModel? activeBank,
    FirmwareImageUIModel? targetBank,
    String? selectedFileName,
    int? selectedFileSize,
    String? selectedFileMd5,
    int? uploadedChunks,
    int? totalChunks,
    String? targetStatus,
    Duration? rebootRemaining,
    String? errorMessage,
    UploadMethod? uploadMethod,
    FirmwareOtaInfo? otaInfo,
    bool? otaUpToDate,
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
      targetStatus: targetStatus ?? this.targetStatus,
      rebootRemaining: rebootRemaining ?? this.rebootRemaining,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadMethod: uploadMethod ?? this.uploadMethod,
      otaInfo: otaInfo ?? this.otaInfo,
      otaUpToDate: otaUpToDate ?? this.otaUpToDate,
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
        targetStatus,
        rebootRemaining,
        errorMessage,
        uploadMethod,
        otaInfo,
        otaUpToDate,
      ];
}
