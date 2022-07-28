import 'package:equatable/equatable.dart';

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
class CloudAccountInfo extends Equatable {
  const CloudAccountInfo({
    required this.id,
    required this.username,
    required this.usernames,
    required this.status,
    required this.type,
    required this.authenticationMode,
    required this.createAt,
    required this.updateAt,
  });

  factory CloudAccountInfo.fromJson(Map<String, dynamic> json) {
    return CloudAccountInfo(
      id: json['id'],
      username: json['username'],
      usernames: json['usernames'],
      status: json['status'],
      type: json['type'],
      authenticationMode: json['authenticationMode'],
      createAt: json['createdAt'],
      updateAt: json['updatedAt'],
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
      'createAt': createAt,
      'updateAt': updateAt,
    };
  }

  final String id;
  final String username;
  final List<String> usernames;
  final String status;
  final String type;
  final String authenticationMode;
  final String createAt;
  final String updateAt;

  @override
  List<Object?> get props => [id, username, usernames, status, type, authenticationMode, createAt, updateAt];
}
