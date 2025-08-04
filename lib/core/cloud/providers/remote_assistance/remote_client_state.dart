import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/cloud/model/guidan_remote_assistance.dart';

class RemoteClientState extends Equatable {
  final GRASessionInfo? sessionInfo;
  final String? pin;
  final List<GRASessionInfo> sessions;
  final int? expiredCountdown;

  const RemoteClientState(
      {this.sessionInfo,
      this.pin,
      this.sessions = const [],
      this.expiredCountdown});

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
              : this.expiredCountdown);

  factory RemoteClientState.fromMap(Map<String, dynamic> map) =>
      RemoteClientState(
        sessionInfo: map['sessionInfo'] != null
            ? GRASessionInfo.fromMap(map['sessionInfo'])
            : null,
        pin: map['pin'],
        sessions: map['sessions'] != null
            ? List<GRASessionInfo>.from(
                map['sessions'].map((x) => GRASessionInfo.fromMap(x)))
            : [],
        expiredCountdown: map['expiredCountdown'],
      );

  Map<String, dynamic> toMap() => {
        'sessionInfo': sessionInfo?.toMap(),
        'pin': pin,
        'sessions': sessions.map((x) => x.toMap()).toList(),
        'expiredCountdown': expiredCountdown,
      };

  factory RemoteClientState.fromJson(String source) =>
      RemoteClientState.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());

  @override
  List<Object?> get props => [sessionInfo, pin, sessions, expiredCountdown];
}
