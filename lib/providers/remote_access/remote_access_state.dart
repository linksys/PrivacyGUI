import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';

/// State for remote assistance session tracking.
///
/// Note: Remote mode determination is now handled by [GlobalConfig.remote].
/// This state only tracks session info and countdown for the UI chip.
class RemoteAccessState extends Equatable {
  /// Current session info (only when in remote mode).
  final GRASessionInfo? sessionInfo;

  /// Session token for API calls (needed to end session).
  final String? sessionToken;

  /// Remaining seconds until session expires.
  final int? remainingSeconds;

  const RemoteAccessState({
    this.sessionInfo,
    this.sessionToken,
    this.remainingSeconds,
  });

  RemoteAccessState copyWith({
    GRASessionInfo? sessionInfo,
    String? sessionToken,
    int? remainingSeconds,
    bool clearSessionInfo = false,
  }) {
    return RemoteAccessState(
      sessionInfo: clearSessionInfo ? null : (sessionInfo ?? this.sessionInfo),
      sessionToken:
          clearSessionInfo ? null : (sessionToken ?? this.sessionToken),
      remainingSeconds:
          clearSessionInfo ? null : (remainingSeconds ?? this.remainingSeconds),
    );
  }

  @override
  List<Object?> get props => [sessionInfo, sessionToken, remainingSeconds];
}
