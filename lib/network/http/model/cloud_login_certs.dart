import 'package:equatable/equatable.dart';

///
/// {
///   "taskType": "CREATE_CERTIFICATE",
///   "data": {
///     "id": "RET-R1:492647359751711213641065353474088091562661625693",
///     "rootCaId": "RET-ROOT1",
///     "expiration": "2032-04-22T09:37:35.000+00:00",
///     "serialNumber": "35ca07cbde04e779b5550bab457eab57",
///     "publikKey": "-----BEGIN CERTIFICATE-----\n*****\n-----END CERTIFICATE-----",
///     "privateKey": "-----BEGIN PRIVATE KEY-----\n*****\n-----END PRIVATE KEY-----"
///   }
/// }
///

class CloudDownloadCertTask extends Equatable {
  const CloudDownloadCertTask({
    required this.taskType,
    required this.data,
  });

  factory CloudDownloadCertTask.fromJson(Map<String, dynamic> json) {
    return CloudDownloadCertTask(
      taskType: json['taskType'],
      data: CloudDownloadCertData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskType': taskType,
      'data': data.toJson(),
    };
  }

  final String taskType;
  final CloudDownloadCertData data;

  @override
  List<Object?> get props => [taskType, data];
}

class CloudDownloadCertData extends Equatable{
  const CloudDownloadCertData({
    required this.id,
    required this.rootCaId,
    required this.expiration,
    required this.serialNumber,
    required this.publicKey,
    required this.privateKey,
  });

  factory CloudDownloadCertData.fromJson(Map<String, dynamic> json) {
    return CloudDownloadCertData(
      id: json['id'],
      rootCaId: json['rootCaId'],
      expiration: json['expiration'],
      serialNumber: json['serialNumber'],
      publicKey: json['publicKey'],
      privateKey: json['privateKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rootCaId': rootCaId,
      'expiration': expiration,
      'serialNumber': serialNumber,
      'publicKey': publicKey,
      'privateKey': privateKey,
    };
  }

  final String id;
  final String rootCaId;
  final String expiration;
  final String serialNumber;
  final String publicKey;
  final String privateKey;

  @override
  List<Object?> get props => [id, rootCaId, expiration, serialNumber, publicKey, privateKey];
}
