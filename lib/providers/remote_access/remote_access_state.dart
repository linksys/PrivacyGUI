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

  /// Session expiry time (fixed, doesn't change with countdown).
  final DateTime? expiryTime;

  /// True when polling has failed multiple times consecutively.
  final bool hasPollError;

  const RemoteAccessState({
    this.sessionInfo,
    this.sessionToken,
    this.remainingSeconds,
    this.expiryTime,
    this.hasPollError = false,
  });

  RemoteAccessState copyWith({
    GRASessionInfo? sessionInfo,
    String? sessionToken,
    int? remainingSeconds,
    DateTime? expiryTime,
    bool? hasPollError,
    bool clearSessionInfo = false,
  }) {
    return RemoteAccessState(
      sessionInfo: clearSessionInfo ? null : (sessionInfo ?? this.sessionInfo),
      sessionToken:
          clearSessionInfo ? null : (sessionToken ?? this.sessionToken),
      remainingSeconds:
          clearSessionInfo ? null : (remainingSeconds ?? this.remainingSeconds),
      expiryTime: clearSessionInfo ? null : (expiryTime ?? this.expiryTime),
      hasPollError:
          clearSessionInfo ? false : (hasPollError ?? this.hasPollError),
    );
  }

  @override
  List<Object?> get props =>
      [sessionInfo, sessionToken, remainingSeconds, expiryTime, hasPollError];
}
