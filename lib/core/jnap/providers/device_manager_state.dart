import 'package:flutter/foundation.dart';
import 'package:linksys_app/core/jnap/models/back_haul_info.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';

@immutable
class DeviceManagerState {
  // Collected data for a specific network with its own devices shared to overall screens
  final List<RouterDevice> deviceList;
  final Map<String, String> locationMap;
  final Map<String, Map<String, dynamic>> wirelessConnections;
  final RouterWANStatus? wanStatus;
  final List<BackHaulInfoData> backhaulInfoData;
  final bool isFirmwareUpToDate;
  final int lastUpdateTime;

  const DeviceManagerState({
    this.deviceList = const [],
    this.locationMap = const {},
    this.wirelessConnections = const {},
    this.wanStatus,
    this.backhaulInfoData = const [],
    this.isFirmwareUpToDate = false,
    this.lastUpdateTime = 0,
  });

  DeviceManagerState copyWith({
    List<RouterDevice>? deviceList,
    Map<String, String>? locationMap,
    Map<String, Map<String, dynamic>>? wirelessConnections,
    RouterWANStatus? wanStatus,
    List<BackHaulInfoData>? backhaulInfoData,
    bool? isFirmwareUpToDate,
    int? lastUpdateTime,
  }) {
    return DeviceManagerState(
      deviceList: deviceList ?? this.deviceList,
      locationMap: locationMap ?? this.locationMap,
      wirelessConnections: wirelessConnections ?? this.wirelessConnections,
      wanStatus: wanStatus ?? this.wanStatus,
      backhaulInfoData: backhaulInfoData ?? this.backhaulInfoData,
      isFirmwareUpToDate: isFirmwareUpToDate ?? this.isFirmwareUpToDate,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }
}

enum NodeSignalLevel {
  wired(displayTitle: 'Wired'),
  none(displayTitle: 'No signal'),
  weak(displayTitle: 'Weak'),
  good(displayTitle: 'Good'),
  fair(displayTitle: 'Fair'),
  excellent(displayTitle: 'Excellent');

  const NodeSignalLevel({
    required this.displayTitle,
  });

  final String displayTitle;
}
