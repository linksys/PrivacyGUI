import 'package:equatable/equatable.dart';

///
///{
///   "state": "REQUIRED_2SV",
///   "data": {
///     "taskId": "string",
///     "certToken": "string",
///     "certSecret": "string",
///     "downloadTime": "string"
///   }
/// }
///
class CloudLoginAcceptState extends Equatable {
  const CloudLoginAcceptState({
    required this.state,
    required this.data,
  });

  factory CloudLoginAcceptState.fromJson(Map<String, dynamic> json) {
    return CloudLoginAcceptState(
      state: json['state'],
      data: CloudLoginAcceptData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'data': data.toJson(),
    };
  }

  final String state;
  final CloudLoginAcceptData data;

  @override
  List<Object?> get props => [state, data];
}

///   {
///     "taskId": "string",
///     "certSecret": "string",
///     "downloadTime": "string"
///   }
class CloudLoginAcceptData extends Equatable {
  const CloudLoginAcceptData(
      {required this.taskId,
      required this.certToken,
      required this.certSecret,
      required this.downloadTime});

  factory CloudLoginAcceptData.fromJson(Map<String, dynamic> json) {
    return CloudLoginAcceptData(
      taskId: json['taskId'],
      certToken: json['certToken'],
      certSecret: json['certSecret'],
      downloadTime: json['downloadTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'certToken': certToken,
      'certSecret': certSecret,
      'downloadTime': downloadTime,
    };
  }

  final String taskId;
  final String certToken;
  final String certSecret;
  final int downloadTime;

  @override
  List<Object?> get props => [taskId, certSecret, downloadTime];
}
