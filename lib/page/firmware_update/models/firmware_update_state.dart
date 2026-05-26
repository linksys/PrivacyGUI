import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';

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
  });

  double get uploadProgress =>
      totalChunks == 0 ? 0.0 : uploadedChunks / totalChunks;

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
      ];
}
