import 'package:equatable/equatable.dart';

///
///
///
class CloudSmartDeviceStatus extends CloudSmartDevice {
  const CloudSmartDeviceStatus({
    required super.appType,
    required super.smartDeviceType,
    required super.platform,
    required super.deviceToken,
    required this.snsArn,
    required this.smartDeviceStatus,
  });

  factory CloudSmartDeviceStatus.fromJson(Map<String, dynamic> json) {
    return CloudSmartDeviceStatus(
      appType: json['appType'],
      smartDeviceType: json['smartDeviceType'],
      platform: json['platform'],
      deviceToken: json['deviceToken'],
      snsArn: json['snsArn'],
      smartDeviceStatus: json['smartDeviceStatus'],
    );
  }

  final String snsArn;
  final String smartDeviceStatus;

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({'snsArn': snsArn, 'smartDeviceStatus': smartDeviceStatus});
  }

  @override
  List<Object?> get props => super.props..addAll([snsArn, smartDeviceStatus]);
}

///
/// {
///   "appType": "DISTRIBUTION",
///   "smartDeviceType": "PRODUCTION",
///   "platform": "APNS",
///   "deviceToken": "fls5MCxWT5WjM3j_Z7PsRd:APA91bH6cJ6y8wZsN4hOL66N7oN7mJEc-DuLRFnkJFAFVlAE_g09Kbcy2y2aqR2rrdbMRg1b6PG9tYQw_xs2wfB09XwWvT6V0y6f9wXHbIUPfQPfB7Bxxj1nHnrX8Ee2CCSYP5Qv8nl7"
/// }
///
class CloudSmartDevice extends Equatable {
  const CloudSmartDevice({
    this.appType,
    this.smartDeviceType,
    required this.platform,
    required this.deviceToken,
  });

  factory CloudSmartDevice.fromJson(Map<String, dynamic> json) {
    return CloudSmartDevice(
      appType: json['appType'],
      smartDeviceType: json['smartDeviceType'],
      platform: json['platform'],
      deviceToken: json['deviceToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appType': appType,
      'smartDeviceType': smartDeviceType,
      'platform': platform,
      'deviceToken': deviceToken,
    };
  }

  final String? appType;
  final String? smartDeviceType;
  final String platform;
  final String deviceToken;

  @override
  List<Object?> get props => [appType, smartDeviceType, platform, deviceToken];
}
