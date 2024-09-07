import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/cloud/model/cloud_account.dart';

class RASession extends Equatable {
  final String sessionId;
  final String token;
  final String? email;
  final CAMobile? mobile;
  final String serialNumber;
  const RASession({
    required this.sessionId,
    required this.token,
    this.email,
    this.mobile,
    this.serialNumber = '',
  });

  RASession copyWith({
    String? sessionId,
    String? token,
    String? email,
    CAMobile? mobile,
    String? serialNumber,
  }) {
    return RASession(
      sessionId: sessionId ?? this.sessionId,
      token: token ?? this.token,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'token': token,
      'email': email,
      'mobile': mobile?.toMap(),
      'serialNumber': serialNumber,
    };
  }

  factory RASession.fromMap(Map<String, dynamic> map) {
    return RASession(
      sessionId: map['sessionId'] as String,
      token: map['token'] as String,
      email: map['email'] != null ? map['email'] as String : null,
      mobile: map['mobile'] != null
          ? CAMobile.fromMap(map['mobile'] as Map<String, dynamic>)
          : null,
      serialNumber: map['serialNumber'],
    );
  }

  String toJson() => json.encode(toMap());

  factory RASession.fromJson(String source) =>
      RASession.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [sessionId, token, email, mobile];
}
