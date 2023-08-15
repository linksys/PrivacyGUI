import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/device/state.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/core/jnap/models/device.dart';
import 'package:linksys_moab/core/jnap/actions/better_action.dart';
import 'package:linksys_moab/core/jnap/result/jnap_result.dart';
import 'package:linksys_moab/core/jnap/extensions/_extensions.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';
import 'package:linksys_moab/core/utils/icon_rules.dart';
import 'package:linksys_moab/utils.dart';

class DeviceCubit extends Cubit<DeviceState> {
  DeviceCubit({required RouterRepository routerRepository})
      : _routerRepository = routerRepository,
        super(DeviceState.init());

  final RouterRepository _routerRepository;

  Future<void> fetchDeviceList() async {
    Map<String, Map<String, dynamic>> wirelessSpeedMap = {};
    List<DeviceDetailInfo> mainOnlineDevices = [];
    List<DeviceDetailInfo> guestOnlineDevices = [];
    List<DeviceDetailInfo> offlineDevices = [];
    emit(state.copyWith(isLoading: true));
    final results = await _routerRepository.fetchDeviceList();
    final networkConnections = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.getNetworkConnections, results)
        ?.output['connections'];
    if (networkConnections != null) {
      for (final connection in networkConnections) {
        if (connection['wireless'] != null) {
          Map<String, dynamic> map = {
            'signalDecibels': connection['wireless']['signalDecibels'],
            'connection': connection['wireless']['band'],
          };
          wirelessSpeedMap[connection['macAddress']] = map;
        }
      }
    }
    final devices = List.from(
            JNAPTransactionSuccessWrap.getResult(JNAPAction.getDevices, results)
                    ?.output['devices'] ??
                [])
        .map((e) => RouterDevice.fromJson(e))
        .toList();
    if (devices.isNotEmpty) {
      final master = devices.firstWhereOrNull(
          (device) => device.isAuthority || device.nodeType == 'Master');
      // To make sure devices can get correct place, sort the device list with
      // priority1: isAuthority, priority2: nodeType == "Master", priority3: nodeType == "Slave"
      devices.sort((e1, e2) {
        if (e1.isAuthority) {
          return -1;
        } else if (e1.nodeType != null) {
          if (e2.nodeType != null) {
            if (e1.nodeType == 'Master') {
              return -1;
            } else if (e2.nodeType == 'Master') {
              return 1;
            }
          }
          return -1;
        }
        return 1;
      });

      String masterPlace = '';
      Map<String, String> placeMap = {};
      if (devices.isNotEmpty) {
        for (RouterDevice device in devices) {
          // Master
          if (device.isAuthority || device.nodeType == 'Master') {
            masterPlace = Utils.getDevicePlace(device);
            placeMap[device.deviceID] = masterPlace;
          } else if (device.nodeType == 'Slave') {
            // Slave
            placeMap[device.deviceID] = Utils.getDevicePlace(device);
          } else {
            // Device
            String macAddress = '';
            String parentDeviceID = '';
            int signal = 0;
            String connection = 'Wired';

            if (device.connections.isEmpty) {
              // Device offline
              offlineDevices.add(DeviceDetailInfo(
                name: Utils.getDeviceName(device),
                deviceID: device.deviceID,
                icon: iconTest(device.toJson()),
                isOnline: false,
              ));
            } else {
              final deviceConnection = device.connections.first;
              macAddress = deviceConnection.macAddress;
              parentDeviceID = deviceConnection.parentDeviceID ?? '';

              final knownInterfaces = device.knownInterfaces;
              if (knownInterfaces != null && knownInterfaces.isNotEmpty) {
                if (knownInterfaces.first.interfaceType == 'Unknown') {
                  // This device is connecting with an unknown type:
                  // If it can be determined by network APIs, update it later (2.4/5 GHz)
                  // If nothing can determine this, assume it is "Wired"
                  connection = 'Wired';
                } else {
                  connection = knownInterfaces.first.interfaceType;
                }
              }
              final wirelessSpeedMap0 = wirelessSpeedMap[macAddress];
              if (wirelessSpeedMap0 != null) {
                signal = wirelessSpeedMap0['signalDecibels'];
                connection = wirelessSpeedMap0['connection'];
              }

              final parent = devices.firstWhereOrNull(
                      (device) => device.deviceID == parentDeviceID) ??
                  master;
              final deviceParentInfo = parent != null
                  ? DeviceParentInfo(
                      place: placeMap[parentDeviceID] ?? masterPlace,
                      deviceId: parent.deviceID,
                      icon: routerIconTest(
                          modelNumber: parent.model.modelNumber ?? '',
                          hardwareVersion: parent.model.hardwareVersion))
                  : null;
              // TODO: #REFACTOR : iotOnlineDevices
              // TODO: #REFACTOR : uploadData, downloadData, weeklyData, icon, profileId
              if (deviceConnection.isGuest != null &&
                  deviceConnection.isGuest == true) {
                guestOnlineDevices.add(DeviceDetailInfo(
                  name: Utils.getDeviceName(device),
                  deviceID: device.deviceID,
                  icon: iconTest(device.toJson()),
                  connection: connection,
                  ipAddress: deviceConnection.ipAddress ?? '',
                  macAddress: macAddress,
                  manufacturer: device.model.manufacturer ?? '',
                  model: device.model.modelNumber ?? '',
                  os: device.unit.operatingSystem ?? '',
                  signal: signal,
                  parentInfo: deviceParentInfo,
                  isOnline: true,
                ));
              } else {
                mainOnlineDevices.add(DeviceDetailInfo(
                  name: Utils.getDeviceName(device),
                  deviceID: device.deviceID,
                  icon: iconTest(device.toJson()),
                  connection: connection,
                  ipAddress: deviceConnection.ipAddress ?? '',
                  macAddress: macAddress,
                  manufacturer: device.model.manufacturer ?? '',
                  model: device.model.modelNumber ?? '',
                  os: device.unit.operatingSystem ?? '',
                  signal: signal,
                  parentInfo: deviceParentInfo,
                  isOnline: true,
                ));
              }
            }
          }
        }
      }
    }

    offlineDevices.sort(
        (e1, e2) => e2.lastChangeRevision.compareTo(e1.lastChangeRevision));
    mainOnlineDevices.sort(
        (e1, e2) => e2.lastChangeRevision.compareTo(e1.lastChangeRevision));
    guestOnlineDevices.sort(
        (e1, e2) => e2.lastChangeRevision.compareTo(e1.lastChangeRevision));

    emit(state.copyWith(
      isLoading: false,
      offlineDeviceList: offlineDevices,
      mainDeviceList: mainOnlineDevices,
      guestDeviceList: guestOnlineDevices,
    ));

    updateDisplayedDeviceList();
  }

  void updateDisplayedDeviceList() {
    switch (state.selectedScope) {
      case DeviceListInfoScope.today:
        _updateTodayDisplayedDeviceList();
        break;
      case DeviceListInfoScope.week:
        _updateWeeklyDisplayedDeviceList();
        break;
      case DeviceListInfoScope.profile:
        _updateProfileDisplayedDeviceList();
        break;
    }
  }

  void _updateTodayDisplayedDeviceList() {
    switch (state.selectedSegment) {
      case DeviceListInfoType.main:
        emit(state.copyWith(displayedDeviceList: state.mainDeviceList));
        break;
      case DeviceListInfoType.guest:
        emit(state.copyWith(displayedDeviceList: state.guestDeviceList));
        break;
      case DeviceListInfoType.iot:
        // TODO: #REFACTOR
        emit(state.copyWith(displayedDeviceList: []));
        break;
    }
  }

  void _updateWeeklyDisplayedDeviceList() {
    List<DeviceDetailInfo> deviceList =
        state.mainDeviceList + state.guestDeviceList;
    deviceList.sort((e1, e2) => e2.weeklyData.compareTo(e1.weeklyData));
    emit(state.copyWith(displayedDeviceList: deviceList));
  }

  void _updateProfileDisplayedDeviceList() {
    List<DeviceDetailInfo> deviceList =
        state.mainDeviceList + state.guestDeviceList + state.offlineDeviceList;
    deviceList.sort((e1, e2) => e2.name.compareTo(e1.name));
    emit(state.copyWith(displayedDeviceList: deviceList));
  }

  void updateSelectedInterval(DeviceListInfoScope scope) {
    emit(state.copyWith(selectedScope: scope));
    updateDisplayedDeviceList();
  }

  void updateSelectedSegment(DeviceListInfoType type) {
    emit(state.copyWith(selectedSegment: type));
    updateDisplayedDeviceList();
  }

  void updateSelectedDeviceInfo(DeviceDetailInfo deviceInfo) {
    emit(state.copyWith(selectedDeviceInfo: deviceInfo));
  }

  Future<void> updateDeviceInfoName(
      DeviceDetailInfo deviceInfo, String name) async {
    await _routerRepository.send(JNAPAction.setDeviceProperties, data: {
      'deviceID': deviceInfo.deviceID,
      'propertiesToModify': {
        'name': userDefinedDeviceName,
        'value': name,
      },
    }).then((value) {
      emit(state.copyWith(
          selectedDeviceInfo: state.selectedDeviceInfo!.copyWith(name: name)));
      fetchDeviceList();
    });
  }

  List<DeviceDetailInfo> getDisplayedDeviceList() {
    return state.displayedDeviceList;
  }

  Future<void> deleteDeviceList(List<DeviceDetailInfo> deviceInfoList) async {
    List<String> deviceIdList = deviceInfoList.map((e) => e.deviceID).toList();
    await _routerRepository
        .deleteDevices(deviceIdList)
        .then((value) => fetchDeviceList());
  }
}
