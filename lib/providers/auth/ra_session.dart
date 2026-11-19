import 'dart:convert';

import 'package:equatable/equatable.dart';

class RASession extends Equatable {
  final String sessionId;
  final String token;

  const RASession({
    required this.sessionId,
    required this.token,
  });

  RASession copyWith({
    String? sessionId,
    String? token,
  }) {
    return RASession(
      sessionId: sessionId ?? this.sessionId,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'token': token,
    };
  }

  factory RASession.fromMap(Map<String, dynamic> map) {
    return RASession(
      sessionId: map['sessionId'] as String,
      token: map['token'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory RASession.fromJson(String source) =>
      RASession.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [sessionId, token];
}
