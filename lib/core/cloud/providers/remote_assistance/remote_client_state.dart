import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';

/// State for Remote Assistance client (device owner side).
///
/// Tracks the current RA session, PIN, and countdown timer.
class RemoteClientState extends Equatable {
  final GRASessionInfo? sessionInfo;
  final String? pin;
  final List<GRASessionInfo> sessions;
  final int? expiredCountdown;

  const RemoteClientState({
    this.sessionInfo,
    this.pin,
    this.sessions = const [],
    this.expiredCountdown,
  });

  RemoteClientState copyWith({
    ValueGetter<GRASessionInfo?>? sessionInfo,
    ValueGetter<String?>? pin,
    ValueGetter<List<GRASessionInfo>>? sessions,
    ValueGetter<int?>? expiredCountdown,
  }) =>
      RemoteClientState(
        sessionInfo: sessionInfo != null ? sessionInfo() : this.sessionInfo,
        pin: pin != null ? pin() : this.pin,
        sessions: sessions != null ? sessions() : this.sessions,
        expiredCountdown: expiredCountdown != null
            ? expiredCountdown()
            : this.expiredCountdown,
      );

  @override
  List<Object?> get props => [sessionInfo, pin, sessions, expiredCountdown];
}
