import 'package:equatable/equatable.dart';
import 'package:linksys_moab/network/http/model/cloud_smart_device.dart';

///
/// {
///   "id": "819e2172-1509-470a-a60c-1984239b50d7",
///   "mobileManufacturer": "Samsung",
///   "mobileModel": "A71",
///   "os": "Android",
///   "osVersion": 11,
///   "systemLocale": "zh-TW",
///   "appType": "DISTRIBUTION",
///   "smartDeviceType": "PRODUCTION",
///   "platform": "GCM",
///   "deviceToken": "fls5MCxWT5WjM3j_Z7PsRd:APA91bH6cJ6y8wZsN4hOL66N7oN7mJEc-DuLRFnkJFAFVlAE_g09Kbcy2y2aqR2rrdbMRg1b6PG9tYQw_xs2wfB09XwWvT6V0y6f9wXHbIUPfQPfB7Bxxj1nHnrX8Ee2CCSYP5Qv8nl7",
///   "snsArn": "arn:aws:sns:ap-northeast-1:193713173851:endpoint/GCM/MoabLocalFCM/8e84557d-2af7-3508-a736-ead83177f377",
///   "smartDeviceStatus": "ACTIVE"
/// }
///
class CloudSmartDeviceApp extends CloudApp {
  const CloudSmartDeviceApp(
      {required super.id,
      required super.appSecret,
      required super.deviceInfo,
      required this.smartDevice});

  factory CloudSmartDeviceApp.fromJson(Map<String, dynamic> json) {
    return CloudSmartDeviceApp(
      id: json['id'],
      appSecret: json['appSecret'],
      deviceInfo: DeviceInfo.fromJson(json),
      smartDevice: CloudSmartDeviceStatus.fromJson(json),
    );
  }

  final CloudSmartDeviceStatus smartDevice;

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..addAll(smartDevice.toJson());
  }
  @override
  List<Object?> get props => super.props..addAll([smartDevice]);
}

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
    this.appSecret,
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
  final String? appSecret;
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
