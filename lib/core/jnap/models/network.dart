// import 'package:equatable/equatable.dart';
// import 'package:privacy_gui/core/jnap/models/device.dart';
// import 'package:privacy_gui/core/jnap/models/device_info.dart';
// import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
// import 'package:privacy_gui/core/jnap/models/radio_info.dart';
// import 'package:privacy_gui/core/jnap/models/wan_status.dart';
// import 'package:privacy_gui/core/jnap/models/health_check_result.dart';

// class AppNetwork extends Equatable {
//   const AppNetwork({
//     required this.id,
//     this.deviceInfo,
//     // this.wanStatus,
//     // this.radioInfo,
//     // this.guestRadioSetting,
//     this.devices,
//     // this.healthCheckResults,
//     // this.currentSpeedTestStatus,
//   });

//   final String id;
//   final NodeDeviceInfo? deviceInfo;
//   // final RouterWANStatus? wanStatus;
//   // final List<RouterRadioInfo>? radioInfo;
//   // final GuestRadioSetting? guestRadioSetting;
//   final List<RawDevice>? devices;
//   // final List<HealthCheckResult>? healthCheckResults;
//   // final SpeedTestResult? currentSpeedTestStatus;

//   @override
//   List<Object?> get props => [
//         id,
//         deviceInfo,
//         // wanStatus,
//         // radioInfo,
//         // guestRadioSetting,
//         devices,
//         // healthCheckResults,
//         // currentSpeedTestStatus,
//       ];

//   AppNetwork copyWith({
//     String? id,
//     NodeDeviceInfo? deviceInfo,
//     // RouterWANStatus? wanStatus,
//     // List<RouterRadioInfo>? radioInfo,
//     // GuestRadioSetting? guestRadioSetting,
//     List<RawDevice>? devices,
//     // List<HealthCheckResult>? healthCheckResults,
//     // SpeedTestResult? currentSpeedTestStatus,
//   }) {
//     return AppNetwork(
//       id: id ?? this.id,
//       deviceInfo: deviceInfo ?? this.deviceInfo,
//       // wanStatus: wanStatus ?? this.wanStatus,
//       // radioInfo: radioInfo ?? this.radioInfo,
//       // guestRadioSetting: guestRadioSetting ?? this.guestRadioSetting,
//       devices: devices ?? this.devices,
//       // healthCheckResults: healthCheckResults ?? this.healthCheckResults,
//       // currentSpeedTestStatus:
//       //     currentSpeedTestStatus ?? this.currentSpeedTestStatus,
//     );
//   }
// }
