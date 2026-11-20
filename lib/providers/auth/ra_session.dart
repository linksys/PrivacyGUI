import 'dart:convert';

import 'package:equatable/equatable.dart';

class RASession extends Equatable {
  final String sessionId;

  const RASession({
    required this.sessionId,
  });

  RASession copyWith({
    String? sessionId,
  }) {
    return RASession(
      sessionId: sessionId ?? this.sessionId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sessionId': sessionId,
    };
  }

  factory RASession.fromMap(Map<String, dynamic> map) {
    return RASession(
      sessionId: map['sessionId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory RASession.fromJson(String source) =>
      RASession.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [sessionId];
}
