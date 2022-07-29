import 'package:equatable/equatable.dart';

///
/// {
///   "id": "string",
///   "appSecret": "string",
///   "mobileManufacturer": "string",
///   "mobileModel": "string",
///   "os": "iOS",
///   "osVersion": "11",
///   "systemLocale": "zh-TW"
/// }
///
class CloudApp extends Equatable {
  const CloudApp({
    required this.id,
    required this.appSecret,
    required this.deviceInfo,
  });

  factory CloudApp.fromJson(Map<String, dynamic> json) {
    return CloudApp(
      id: json['id'],
      appSecret: json['appSecret'],
      deviceInfo: DeviceInfo.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appSecret': appSecret,
      ...deviceInfo.toJson(),
    };
  }

  final String id;
  final String appSecret;
  final DeviceInfo deviceInfo;

  @override
  List<Object?> get props => [id, appSecret, deviceInfo];
}

class DeviceInfo extends Equatable {
  const DeviceInfo({
    required this.mobileManufacturer,
    required this.mobileModel,
    required this.os,
    required this.osVersion,
    required this.systemLocale,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      mobileManufacturer: json['mobileManufacturer'],
      mobileModel: json['mobileModel'],
      os: json['os'],
      osVersion: json['osVersion'],
      systemLocale: json['systemLocale'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobileManufacturer': mobileManufacturer,
      'mobileModel': mobileModel,
      'os': os,
      'osVersion': osVersion,
      'systemLocale': systemLocale,
    };
  }

  final String mobileManufacturer;
  final String mobileModel;
  final String os;
  final String osVersion;
  final String systemLocale;

  @override
  List<Object?> get props =>
      [mobileManufacturer, mobileModel, os, osVersion, systemLocale];
}
