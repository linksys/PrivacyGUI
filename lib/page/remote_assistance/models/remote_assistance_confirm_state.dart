import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';

/// Where the support agent's confirm page is.
///
/// The names are an E2E contract: the page card's identifier is
/// `ra-confirm-state-<name>`, and the real-router spec waits on them.
enum RemoteAssistanceConfirmPhase {
  idle,
  validating,
  validated,
  connecting,
  error,
}

/// What the confirm page shows while it validates a session and connects.
class RemoteAssistanceConfirmState extends Equatable {
  final RemoteAssistanceConfirmPhase phase;

  /// Shown in the error box. Set in [RemoteAssistanceConfirmPhase.error], and
  /// also in `validated` after a Connect that failed.
  final String? errorMessage;

  /// What Guardian said about the session, once it has answered.
  final GRASessionInfo? sessionInfo;

  /// Seconds until the session expires, counting down once validated.
  final int? remainingSeconds;

  const RemoteAssistanceConfirmState({
    this.phase = RemoteAssistanceConfirmPhase.idle,
    this.errorMessage,
    this.sessionInfo,
    this.remainingSeconds,
  });

  /// Connect is offered only on a validated, ACTIVE session, so it is gone
  /// while a connect is in flight.
  bool get canConnect =>
      phase == RemoteAssistanceConfirmPhase.validated &&
      sessionInfo?.status == GRASessionStatus.active;

  RemoteAssistanceConfirmState copyWith({
    RemoteAssistanceConfirmPhase? phase,
    String? errorMessage,
    bool clearError = false,
    GRASessionInfo? sessionInfo,
    int? remainingSeconds,
  }) {
    return RemoteAssistanceConfirmState(
      phase: phase ?? this.phase,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sessionInfo: sessionInfo ?? this.sessionInfo,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  @override
  List<Object?> get props =>
      [phase, errorMessage, sessionInfo, remainingSeconds];
}
