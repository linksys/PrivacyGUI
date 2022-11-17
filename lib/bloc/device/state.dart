import 'package:equatable/equatable.dart';

class DeviceState extends Equatable {
  final DeviceListInfoScope selectedScope;
  final DeviceListInfoType selectedSegment;
  final List<DeviceDetailInfo> displayedDeviceList;
  final DeviceDetailInfo? selectedDeviceInfo;
  final List<DeviceDetailInfo> offlineDeviceList;
  final List<DeviceDetailInfo> mainDeviceList;
  final List<DeviceDetailInfo> guestDeviceList;
  final List<DeviceDetailInfo> iotDeviceList;

  const DeviceState({
    this.selectedScope = DeviceListInfoScope.today,
    this.selectedSegment = DeviceListInfoType.main,
    this.displayedDeviceList = const [],
    this.selectedDeviceInfo,
    this.offlineDeviceList = const [],
    this.mainDeviceList = const [],
    this.guestDeviceList = const [],
    this.iotDeviceList = const [],
  });

  DeviceState.init()
      : selectedScope = DeviceListInfoScope.today,
        selectedSegment = DeviceListInfoType.main,
        displayedDeviceList = [],
        selectedDeviceInfo = null,
        offlineDeviceList = [],
        mainDeviceList = [],
        guestDeviceList = [],
        iotDeviceList = [];

  DeviceState copyWith({
    DeviceListInfoScope? selectedScope,
    DeviceListInfoType? selectedSegment,
    List<DeviceDetailInfo>? displayedDeviceList,
    DeviceDetailInfo? selectedDeviceInfo,
    List<DeviceDetailInfo>? offlineDeviceList,
    List<DeviceDetailInfo>? mainDeviceList,
    List<DeviceDetailInfo>? guestDeviceList,
    List<DeviceDetailInfo>? iotDeviceList,
  }) {
    return DeviceState(
      selectedScope: selectedScope ?? this.selectedScope,
      selectedSegment: selectedSegment ?? this.selectedSegment,
      displayedDeviceList: displayedDeviceList ?? this.displayedDeviceList,
      selectedDeviceInfo: selectedDeviceInfo ?? this.selectedDeviceInfo,
      offlineDeviceList: offlineDeviceList ?? this.offlineDeviceList,
      mainDeviceList: mainDeviceList ?? this.mainDeviceList,
      guestDeviceList: guestDeviceList ?? this.guestDeviceList,
      iotDeviceList: iotDeviceList ?? this.iotDeviceList,
    );
  }

  @override
  List<Object?> get props => [
        selectedScope,
        selectedSegment,
        displayedDeviceList,
        selectedDeviceInfo,
        offlineDeviceList,
        mainDeviceList,
        guestDeviceList,
        iotDeviceList,
      ];
}

enum DeviceListInfoScope {
  today,
  week,
  profile,
}

enum DeviceListInfoType {
  main,
  guest,
  iot,
}

class DeviceDetailInfo extends Equatable {
  final String name;
  final String deviceID;
  final String place;
  final int uploadData;
  final int downloadData;
  final String connection;
  final int weeklyData;
  final String icon;
  final String ipAddress;
  final String macAddress;
  final String manufacturer;
  final String model;
  final String os;
  final int signal;
  final int lastChangeRevision;
  final String? profileId;

  const DeviceDetailInfo({
    required this.name,
    required this.deviceID,
    this.place = '',
    this.uploadData = 0,
    this.downloadData = 0,
    this.connection = '',
    this.weeklyData = 0,
    this.icon = 'assets/images/icon_device.png',
    this.ipAddress = '',
    this.macAddress = '',
    this.manufacturer = '',
    this.model = '',
    this.os = '',
    this.signal = 0,
    this.lastChangeRevision = 0,
    this.profileId,
  });

  DeviceDetailInfo copyWith({
    String? name,
    String? deviceID,
    String? place,
    int? uploadData,
    int? downloadData,
    String? connection,
    int? weeklyData,
    String? icon,
    String? ipAddress,
    String? macAddress,
    String? manufacturer,
    String? model,
    String? os,
    int? signal,
    int? lastChangeRevision,
    String? profileId,
  }) {
    return DeviceDetailInfo(
      name: name ?? this.name,
      deviceID: deviceID ?? this.deviceID,
      place: place ?? this.place,
      uploadData: uploadData ?? this.uploadData,
      downloadData: downloadData ?? this.downloadData,
      connection: connection ?? this.connection,
      weeklyData: weeklyData ?? this.weeklyData,
      icon: icon ?? this.icon,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      os: os ?? this.os,
      signal: signal ?? this.signal,
      lastChangeRevision: lastChangeRevision ?? this.lastChangeRevision,
      profileId: profileId ?? this.profileId,
    );
  }

  @override
  List<Object?> get props => [
        name,
        deviceID,
        place,
        uploadData,
        downloadData,
        connection,
        weeklyData,
        icon,
        ipAddress,
        macAddress,
        manufacturer,
        model,
        os,
        signal,
        lastChangeRevision,
        profileId,
      ];
}
