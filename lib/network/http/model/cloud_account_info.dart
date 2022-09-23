import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_preferences.dart';
import 'package:linksys_moab/network/http/model/cloud_task_model.dart';

///
/// {
///   "id":"82248d9d-50a7-4e35-822c-e07ed02d8063",
///   "username":"austin.chang@linksys.com",
///   "usernames":["austin.chang@linksys.com"],
///   "status":"ACTIVE",
///   "type":"NORMAL",
///   "authenticationMode":"PASSWORD",
///   "createdAt":"2022-07-13T09:37:01.665063052Z",
///   "updatedAt":"2022-07-13T09:37:01.665063052Z"
/// }
///
class CloudAccountVerifyInfo extends Equatable {
  const CloudAccountVerifyInfo({
    required this.id,
    required this.username,
    required this.usernames,
    required this.status,
    required this.type,
    required this.authenticationMode,
    required this.createdAt,
    required this.updatedAt,
    required this.certInfo,
  });

  factory CloudAccountVerifyInfo.fromJson(Map<String, dynamic> json) {
    return CloudAccountVerifyInfo(
      id: json['id'],
      username: json['username'],
      usernames: List<String>.from(json['usernames']),
      status: json['status'],
      type: json['type'],
      authenticationMode: json['authenticationMode'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      certInfo: CertInfoData.fromJson(json['certInfo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'usernames': usernames,
      'status': status,
      'type': type,
      'authenticationMode': authenticationMode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'certInfo': certInfo.toJson(),
    };
  }

  final String id;
  final String username;
  final List<String> usernames;
  final String status;
  final String type;
  final String authenticationMode;
  final String createdAt;
  final String updatedAt;
  final CertInfoData certInfo;

  @override
  List<Object?> get props => [
        id,
        username,
        usernames,
        status,
        type,
        authenticationMode,
        createdAt,
        updatedAt,
        certInfo,
      ];
}

class CloudAccountInfo extends Equatable {
  const CloudAccountInfo({
    required this.id,
    required this.username,
    required this.usernames,
    required this.status,
    required this.type,
    required this.authenticationMode,
    required this.createdAt,
    required this.updatedAt,
    required this.preferences,
    required this.communicationMethods,
  });

  factory CloudAccountInfo.fromJson(Map<String, dynamic> json) {
    return CloudAccountInfo(
      id: json['id'],
      username: json['username'],
      usernames: List<String>.from(json['usernames']),
      status: json['status'],
      type: json['type'],
      authenticationMode: json['authenticationMode'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      preferences: CloudPreferences.fromJson(json['preferences']),
      communicationMethods: List.from(List.from(json['communicationMethods'])
          .map((e) => CommunicationMethod.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'usernames': usernames,
      'status': status,
      'type': type,
      'authenticationMode': authenticationMode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'preferences': preferences.toJson(),
      'communicationMethods': communicationMethods.map((e) => e.toJson()),
    };
  }

  final String id;
  final String username;
  final List<String> usernames;
  final String status;
  final String type;
  final String authenticationMode;
  final String createdAt;
  final String updatedAt;
  final CloudPreferences preferences;
  final List<CommunicationMethod> communicationMethods;

  @override
  List<Object?> get props => [
        id,
        username,
        usernames,
        status,
        type,
        authenticationMode,
        createdAt,
        updatedAt,
        preferences,
        communicationMethods
      ];
}
