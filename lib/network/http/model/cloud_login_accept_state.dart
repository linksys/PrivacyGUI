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
      data: CloudLoginAcceptDataV1.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'data': data.toJson(),
    };
  }

  final String state;
  final CloudLoginAcceptDataV1 data;

  @override
  List<Object?> get props => [state, data];
}

///   {
///     "downloadUrl": "string",
///     "certSecret": "string",
///     "downloadTime": "string"
///   }
class CloudLoginAcceptDataV1 extends Equatable {
  const CloudLoginAcceptDataV1(
      {required this.downloadUrl,
      required this.certSecret,
      required this.downloadTime});

  factory CloudLoginAcceptDataV1.fromJson(Map<String, dynamic> json) {
    return CloudLoginAcceptDataV1(
      downloadUrl: json['downloadUrl'],
      certSecret: json['certSecret'],
      downloadTime: json['downloadTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadUrl': downloadUrl,
      'certSecret': certSecret,
      'downloadTime': downloadTime,
    };
  }

  final String downloadUrl;
  final String certSecret;
  final String downloadTime;

  @override
  List<Object?> get props => [downloadUrl, certSecret, downloadTime];
}

///   {
///     "taskId": "string",
///     "certSecret": "string",
///     "downloadTime": "string"
///   }
class CloudLoginAcceptDataV2 extends Equatable {
  const CloudLoginAcceptDataV2(
      {required this.taskId,
      required this.certSecret,
      required this.downloadTime});

  factory CloudLoginAcceptDataV2.fromJson(Map<String, dynamic> json) {
    return CloudLoginAcceptDataV2(
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
  final String downloadTime;

  @override
  List<Object?> get props => [taskId, certSecret, downloadTime];
}
