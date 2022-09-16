import 'package:equatable/equatable.dart';

///
///{
///   "state": "REQUIRE_2SV",
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
      data: CertInfoData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'data': data.toJson(),
    };
  }

  final String state;
  final CertInfoData data;

  @override
  List<Object?> get props => [state, data];
}

///   {
///     "taskId": "string",
///     "certSecret": "string",
///     "downloadTime": "string"
///   }
class CertInfoData extends Equatable {
  const CertInfoData({
    required this.taskId,
    required this.certSecret,
    required this.downloadTime,
  });

  factory CertInfoData.fromJson(Map<String, dynamic> json) {
    return CertInfoData(
      taskId: json['taskId'],
      certSecret: json['certSecret'],
      downloadTime: json['downloadTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'certSecret': certSecret,
      'downloadTime': downloadTime,
    };
  }

  final String taskId;
  final String certSecret;
  final int downloadTime;

  @override
  List<Object?> get props => [taskId, certSecret, downloadTime];
}
