import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';

class RemoteClientState extends Equatable {
  final GRASessionInfo? sessionInfo;
  final String? pin;

  /// The session [pin] was minted for.
  ///
  /// A PIN belongs to one session. Without this, "does this session need a PIN?"
  /// could only ask whether *any* PIN existed, so one left over from an earlier
  /// session suppressed `createPin` for every session that followed (#1560).
  final String? pinSessionId;
  final List<GRASessionInfo> sessions;
  final int? expiredCountdown;

  /// Whether a remote assistance dialog is currently shown. Used so the
  /// dashboard does not auto-open a second (passive) dialog while one is
  /// already open.
  final bool isDialogShown;

  const RemoteClientState(
      {this.sessionInfo,
      this.pin,
      this.pinSessionId,
      this.sessions = const [],
      this.expiredCountdown,
      this.isDialogShown = false});

  /// [pin] when it was minted for the session currently in [sessionInfo], and
  /// null when it belongs to an earlier one.
  ///
  /// This answers "is the PIN in state safe to show?". The provider asks a
  /// related but different question - "does the session I have just fetched need
  /// a PIN?" - against the value in its hand rather than against state, so it
  /// keeps its own comparison rather than reusing this.
  String? get pinForCurrentSession =>
      pinSessionId != null && pinSessionId == sessionInfo?.id ? pin : null;

  RemoteClientState copyWith({
    ValueGetter<GRASessionInfo?>? sessionInfo,
    ValueGetter<String?>? pin,
    ValueGetter<String?>? pinSessionId,
    ValueGetter<List<GRASessionInfo>>? sessions,
    ValueGetter<int?>? expiredCountdown,
    ValueGetter<bool>? isDialogShown,
  }) =>
      RemoteClientState(
          sessionInfo: sessionInfo != null ? sessionInfo() : this.sessionInfo,
          pin: pin != null ? pin() : this.pin,
          pinSessionId:
              pinSessionId != null ? pinSessionId() : this.pinSessionId,
          sessions: sessions != null ? sessions() : this.sessions,
          expiredCountdown: expiredCountdown != null
              ? expiredCountdown()
              : this.expiredCountdown,
          isDialogShown:
              isDialogShown != null ? isDialogShown() : this.isDialogShown);

  factory RemoteClientState.fromMap(Map<String, dynamic> map) =>
      RemoteClientState(
        sessionInfo: map['sessionInfo'] != null
            ? GRASessionInfo.fromMap(map['sessionInfo'])
            : null,
        pin: map['pin'],
        pinSessionId: map['pinSessionId'],
        sessions: map['sessions'] != null
            ? List<GRASessionInfo>.from(
                map['sessions'].map((x) => GRASessionInfo.fromMap(x)))
            : [],
        expiredCountdown: map['expiredCountdown'],
        isDialogShown: map['isDialogShown'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'sessionInfo': sessionInfo?.toMap(),
        'pin': pin,
        'pinSessionId': pinSessionId,
        'sessions': sessions.map((x) => x.toMap()).toList(),
        'expiredCountdown': expiredCountdown,
        'isDialogShown': isDialogShown,
      };

  factory RemoteClientState.fromJson(String source) =>
      RemoteClientState.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());

  @override
  List<Object?> get props => [
        sessionInfo,
        pin,
        pinSessionId,
        sessions,
        expiredCountdown,
        isDialogShown
      ];
}
