import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';

/// Where a Channel Finder scan is.
enum ChannelFinderPhase {
  /// No scan this session.
  idle,

  /// A scan is running.
  scanning,

  /// The last scan finished; [ChannelFinderState.lastResult] is its result.
  done,

  /// The last scan failed; [ChannelFinderState.error] says why, and
  /// [ChannelFinderState.lastResult] still holds the scan before it, if any.
  failed,
}

/// The session's Channel Finder scan, shared by the page, the dashboard card
/// and the diagnostics link (#1778).
class ChannelFinderState extends Equatable {
  final ChannelFinderPhase phase;

  /// The part of the scan that is running, while [phase] is
  /// [ChannelFinderPhase.scanning]; null before the first part starts.
  final ChannelFinderScanStage? stage;

  /// The newest result this session, kept while a new scan runs or fails.
  final ChannelFinderResultUIModel? lastResult;

  /// Why the last scan failed, when [phase] is [ChannelFinderPhase.failed].
  final ServiceError? error;

  const ChannelFinderState({
    this.phase = ChannelFinderPhase.idle,
    this.stage,
    this.lastResult,
    this.error,
  });

  bool get isScanning => phase == ChannelFinderPhase.scanning;

  ChannelFinderState copyWith({
    ChannelFinderPhase? phase,
    ChannelFinderScanStage? stage,
    bool clearStage = false,
    ChannelFinderResultUIModel? lastResult,
    ServiceError? error,
    bool clearError = false,
  }) =>
      ChannelFinderState(
        phase: phase ?? this.phase,
        stage: clearStage ? null : stage ?? this.stage,
        lastResult: lastResult ?? this.lastResult,
        error: clearError ? null : error ?? this.error,
      );

  @override
  List<Object?> get props => [phase, stage, lastResult, error];
}
