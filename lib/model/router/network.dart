import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/model/router/wan_status.dart';

class MoabNetwork extends Equatable {
  const MoabNetwork({
    required this.id,
    required this.deviceInfo,
    this.wanStatus,
    this.radioInfo,
    this.devices,
  });

  final String id;
  final RouterDeviceInfo deviceInfo;
  final RouterWANStatus? wanStatus;
  final List<RouterRadioInfo>? radioInfo;
  final List<Device>? devices;

  @override
  List<Object?> get props => [
        id,
        deviceInfo,
        wanStatus,
        radioInfo,
        devices,
      ];

  MoabNetwork copyWith({
    String? id,
    RouterDeviceInfo? deviceInfo,
    RouterWANStatus? wanStatus,
    List<RouterRadioInfo>? radioInfo,
    List<Device>? devices,
  }) {
    return MoabNetwork(
      id: id ?? this.id,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      wanStatus: wanStatus ?? this.wanStatus,
      radioInfo: radioInfo ?? this.radioInfo,
      devices: devices ?? this.devices,
    );
  }
}
