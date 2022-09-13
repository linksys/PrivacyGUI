import 'package:equatable/equatable.dart';

class DeviceState extends Equatable {
  final Map<String, DeviceDetailInfo> deviceDetailInfoMap;
  final DeviceDetailInfo? selectedDeviceInfo;

  const DeviceState({
    this.deviceDetailInfoMap = const {},
    this.selectedDeviceInfo,
  });

  DeviceState.init()
      : deviceDetailInfoMap = {},
        selectedDeviceInfo = null;

  DeviceState copyWith({
    Map<String, DeviceDetailInfo>? deviceDetailInfoMap,
    DeviceDetailInfo? selectedDeviceInfo,
  }) {
    return DeviceState(
      deviceDetailInfoMap: deviceDetailInfoMap ?? this.deviceDetailInfoMap,
      selectedDeviceInfo: selectedDeviceInfo ?? this.selectedDeviceInfo,
    );
  }

  @override
  List<Object?> get props => [
        deviceDetailInfoMap,
        selectedDeviceInfo,
      ];
}

enum DeviceListInfoType {
  main,
  guest,
  iot,
}

class DeviceDetailInfo {
  String name;
  String place;
  String frequency;
  String uploadData;
  String downloadData;
  String connection;
  String weeklyData;
  String icon;
  String connectedTo;
  String ipAddress;
  String macAddress;
  String manufacturer;
  String model;
  String os;
  String? profileId;

  DeviceDetailInfo({
    this.name = '',
    this.place = '',
    this.frequency = '',
    this.uploadData = '',
    this.downloadData = '',
    this.connection = '',
    this.weeklyData = '',
    this.icon = 'assets/images/icon_device.png',
    this.connectedTo = '',
    this.ipAddress = '',
    this.macAddress = '',
    this.manufacturer = '',
    this.model = '',
    this.os = '',
    this.profileId,
  });

  factory DeviceDetailInfo.dummy() {
    return DeviceDetailInfo(
      name: 'Device name',
      place: 'Living Room node',
      frequency: '5 GHz',
      uploadData: '0.4',
      downloadData: '12',
      connection: 'wifi',
      icon: 'assets/images/icon_device_detail.png',
      connectedTo: 'Kitchen',
      ipAddress: '192.168.1.120',
      macAddress: '92:98:DD:AF:4E:42',
      manufacturer: 'Apple',
      model: 'iPhone XR',
      os: 'iOS 15.0.2',
    );
  }

  DeviceDetailInfo copyWith({
    String? name,
    String? place,
    String? frequency,
    String? uploadUsage,
    String? downloadUsage,
    String? connection,
    String? weeklyUsage,
    String? icon,
    String? connectedTo,
    String? ipAddress,
    String? macAddress,
    String? manufacturer,
    String? model,
    String? os,
    String? profileId,
  }) {
    return DeviceDetailInfo(
      name: name ?? this.name,
      place: place ?? this.place,
      frequency: frequency ?? this.frequency,
      uploadData: uploadUsage ?? this.uploadData,
      downloadData: downloadUsage ?? this.downloadData,
      connection: connection ?? this.connection,
      weeklyData: weeklyUsage ?? this.weeklyData,
      icon: icon ?? this.icon,
      connectedTo: connectedTo ?? this.connectedTo,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      os: os ?? this.os,
      profileId: profileId ?? this.profileId,
    );
  }
}
