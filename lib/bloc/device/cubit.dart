import 'dart:ffi';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/device/state.dart';
import 'package:linksys_moab/util/logger.dart';

class DeviceCubit extends Cubit<DeviceState> {
  DeviceCubit() : super(DeviceState.init());

  void fetchTodayDevicesList() {
    // TODO: fetch Today DevicesList
    Map<String, DeviceDetailInfo> _deviceMap = {
      '92:98:DD:AF:4E:00': DeviceDetailInfo(
          name: 'iPhone XR',
          place: 'Living Room node',
          frequency: '5 GHz',
          uploadData: '0.4',
          downloadData: '12',
          connection: 'wifi',
          weeklyData: '345',
          profileId: 'PROFILE_ID_0001',
          macAddress: '92:98:DD:AF:4E:00'),
      '92:98:DD:AF:4E:01': DeviceDetailInfo.dummy()
          .copyWith(weeklyUsage: '128', macAddress: '92:98:DD:AF:4E:01'),
      '92:98:DD:AF:4E:02': DeviceDetailInfo.dummy()
          .copyWith(weeklyUsage: '359', macAddress: '92:98:DD:AF:4E:02'),
      '92:98:DD:AF:4E:03': DeviceDetailInfo.dummy()
          .copyWith(weeklyUsage: '23', macAddress: '92:98:DD:AF:4E:03'),
      '92:98:DD:AF:4E:04': DeviceDetailInfo.dummy()
          .copyWith(weeklyUsage: '19', macAddress: '92:98:DD:AF:4E:04'),
      '92:98:DD:AF:4E:05': DeviceDetailInfo.dummy()
          .copyWith(weeklyUsage: '5', macAddress: '92:98:DD:AF:4E:05'),
      '92:98:DD:AF:4E:06': DeviceDetailInfo.dummy()
          .copyWith(weeklyUsage: '4', macAddress: '92:98:DD:AF:4E:06'),
      '92:98:DD:AF:4E:07': DeviceDetailInfo.dummy()
          .copyWith(weeklyUsage: '4', macAddress: '92:98:DD:AF:4E:07'),
      '92:98:DD:AF:4E:08': DeviceDetailInfo.dummy()
          .copyWith(weeklyUsage: '4', macAddress: '92:98:DD:AF:4E:08'),
    };

    emit(state.copyWith(deviceDetailInfoMap: _deviceMap));
  }

  void showMainDevices() {
    // TODO: filter or sort device list to Main category
  }

  void showGuestDevices() {
    // TODO: filter or sort device list to Guest category
  }

  void showIotDevices() {
    // TODO: filter or sort device list to Iot category
  }

  void fetchWeekDevicesList() {
    // TODO: fetch Week DevicesList
    Map<String, DeviceDetailInfo> _deviceMap = state.deviceDetailInfoMap;

    // Sort by weekly data
    var _sortedDeviceMap = Map.fromEntries(_deviceMap.entries.toList()
      ..sort((e1, e2) => double.parse(e2.value.weeklyData)
          .compareTo(double.parse(e1.value.weeklyData))));

    emit(DeviceState.init());
    emit(DeviceState(deviceDetailInfoMap: _sortedDeviceMap));
  }

  void setSelectedDeviceInfo(DeviceDetailInfo deviceInfo) {
    emit(state.copyWith(selectedDeviceInfo: deviceInfo));
  }

  void updateDeviceInfoName(String? selectedDeviceMacAddress, String name) {
    Map<String, DeviceDetailInfo> _deviceMap = state.deviceDetailInfoMap;
    DeviceDetailInfo? _selectedDevice;
    if (selectedDeviceMacAddress != null) {
      _selectedDevice = _deviceMap[selectedDeviceMacAddress];
    } else {
      _selectedDevice = state.selectedDeviceInfo;
    }

    if (_selectedDevice != null) {
      _selectedDevice.name = name;
      _deviceMap[_selectedDevice.macAddress] = _selectedDevice;

      emit(state.copyWith(deviceDetailInfoMap: _deviceMap));
    } else {
      logger.d('DeviceCubit: updateDeviceInfoName: _selectedDevice is null');
    }
  }
}
