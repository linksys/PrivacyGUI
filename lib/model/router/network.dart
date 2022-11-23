import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/model/router/guest_radio_settings.dart';
import 'package:linksys_moab/model/router/iot_network_settings.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/model/router/health_check_result.dart';

class MoabNetwork extends Equatable {
  const MoabNetwork({
    required this.id,
    this.deviceInfo,
    this.wanStatus,
    this.radioInfo,
    this.guestRadioSetting,
    this.iotNetworkSetting,
    this.devices,
    this.healthCheckResults,
    this.currentSpeedTestStatus,
  });

  final String id;
  final RouterDeviceInfo? deviceInfo;
  final RouterWANStatus? wanStatus;
  final List<RouterRadioInfo>? radioInfo;
  final GuestRadioSetting? guestRadioSetting;
  final IoTNetworkSetting? iotNetworkSetting;
  final List<RouterDevice>? devices;
  final List<HealthCheckResult>? healthCheckResults;
  final SpeedTestResult? currentSpeedTestStatus;

  @override
  List<Object?> get props => [
        id,
        deviceInfo,
        wanStatus,
        radioInfo,
        guestRadioSetting,
        iotNetworkSetting,
        devices,
        healthCheckResults,
        currentSpeedTestStatus,
      ];

  MoabNetwork copyWith({
    String? id,
    RouterDeviceInfo? deviceInfo,
    RouterWANStatus? wanStatus,
    List<RouterRadioInfo>? radioInfo,
    GuestRadioSetting? guestRadioSetting,
    IoTNetworkSetting? iotNetworkSetting,
    List<RouterDevice>? devices,
    List<HealthCheckResult>? healthCheckResults,
    SpeedTestResult? currentSpeedTestStatus,
  }) {
    return MoabNetwork(
      id: id ?? this.id,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      wanStatus: wanStatus ?? this.wanStatus,
      radioInfo: radioInfo ?? this.radioInfo,
      guestRadioSetting: guestRadioSetting ?? this.guestRadioSetting,
      iotNetworkSetting: iotNetworkSetting ?? this.iotNetworkSetting,
      devices: devices ?? this.devices,
      healthCheckResults: healthCheckResults ?? this.healthCheckResults,
      currentSpeedTestStatus:
          currentSpeedTestStatus ?? this.currentSpeedTestStatus,
    );
  }
}
