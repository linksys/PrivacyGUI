
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/model/router/wan_status.dart';

class MoabNetwork extends Equatable {
  const MoabNetwork({
    required this.id,
    required this.deviceInfo,
    this.wanStatus
  });

  final String id;
  final RouterDeviceInfo deviceInfo;
  final RouterWANStatus? wanStatus;

  @override
  List<Object?> get props => [
    id,
    deviceInfo,
    wanStatus,
  ];

  MoabNetwork copyWith({
    String? id,
    RouterDeviceInfo? deviceInfo,
    RouterWANStatus? wanStatus,
  }) {
    return MoabNetwork(
      id: id ?? this.id,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      wanStatus: wanStatus ?? this.wanStatus,
    );
  }
}