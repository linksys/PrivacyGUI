import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/cloud/model/guidan_remote_assistance.dart';

class RemoteClientState extends Equatable {
  final GRASessionInfo? sessionInfo;
  final String? pin;
  final List<GRASessionInfo> sessions;

  const RemoteClientState(
      {this.sessionInfo, this.pin, this.sessions = const []});

  RemoteClientState copyWith({
    ValueGetter<GRASessionInfo?>? sessionInfo,
    ValueGetter<String?>? pin,
    ValueGetter<List<GRASessionInfo>>? sessions,
  }) =>
      RemoteClientState(
          sessionInfo: sessionInfo != null ? sessionInfo() : this.sessionInfo,
          pin: pin != null ? pin() : this.pin,
          sessions: sessions != null ? sessions() : this.sessions);

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
      );

  Map<String, dynamic> toMap() => {
        'sessionInfo': sessionInfo?.toMap(),
        'pin': pin,
        'sessions': sessions.map((x) => x.toMap()).toList(),
      };

  factory RemoteClientState.fromJson(String source) =>
      RemoteClientState.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());

  @override
  List<Object?> get props => [sessionInfo, pin, sessions];
}
