import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';

final deviceManagerProvider =
    NotifierProvider<DeviceManagerNotifier, DeviceManagerState>(
  () => DeviceManagerNotifier(),
);

class DeviceManagerNotifier extends Notifier<DeviceManagerState> {
  @override
  DeviceManagerState build() {
    final coreTransactionData = ref.watch(pollingProvider).value;
    return createState(pollingResult: coreTransactionData);
  }

  DeviceManagerState createState({CoreTransactionData? pollingResult}) {
    Map<String, dynamic>? getDevicesData;
    Map<String, dynamic>? getNetworkConnectionsData;
    Map<String, dynamic>? getWANStatusData;
    Map<String, dynamic>? getFirmwareUpdateStatusData;

    final result = pollingResult?.data;
    if (result != null) {
      getDevicesData = (result[JNAPAction.getDevices] as JNAPSuccess?)?.output;
      getNetworkConnectionsData =
          (result[JNAPAction.getNetworkConnections] as JNAPSuccess?)?.output;
      getWANStatusData =
          (result[JNAPAction.getWANStatus] as JNAPSuccess?)?.output;
      getFirmwareUpdateStatusData =
          (result[JNAPAction.getFirmwareUpdateStatus] as JNAPSuccess?)?.output;
    }

    var newState = const DeviceManagerState();
    newState = _getDeviceListAndLocations(newState, getDevicesData);
    newState = _getWirelessConnections(newState, getNetworkConnectionsData);
    newState = _getWANStatusModel(newState, getWANStatusData);
    newState = _getFirmwareStatus(newState, getFirmwareUpdateStatusData);
    return newState.copyWith(
      lastUpdateTime: pollingResult?.lastUpdate,
    );
  }

  DeviceManagerState _getDeviceListAndLocations(
    DeviceManagerState state,
    Map<String, dynamic>? data,
  ) {
    var allDevices = <RouterDevice>[];
    if (data != null) {
      allDevices = List.from(
        data['devices'],
      ).map((e) => RouterDevice.fromJson(e)).toList();
      // Sort the device list in order to correctly build the location map later
      allDevices.sort((device1, device2) {
        if (device1.isAuthority) {
          return -1;
        } else if (device1.nodeType == null) {
          return 1;
        } else if (device2.nodeType != null) {
          return (device1.nodeType == 'Master') ? -1 : 1;
        } else {
          return -1;
        }
      });
    }
    var locationMap = <String, String>{};
    for (final device in allDevices) {
      // Record location(device name) for ALL devices
      locationMap[device.deviceID] = _getDeviceLocation(device);
    }

    return state.copyWith(
      deviceList: allDevices,
      locationMap: locationMap,
    );
  }

  DeviceManagerState _getWirelessConnections(
    DeviceManagerState state,
    Map<String, dynamic>? data,
  ) {
    var connectionsMap = <String, Map<String, dynamic>>{};
    if (data != null) {
      final connections = data['connections'] as List;
      for (final connection in connections) {
        final connectionData = connection as Map<String, dynamic>;
        final macAddress = connectionData['macAddress'];
        final Map<String, dynamic>? wirelessData = connectionData['wireless'];
        if (wirelessData != null) {
          final band = wirelessData['band'];
          final signalDecibels = wirelessData['signalDecibels'];
          connectionsMap[macAddress] = {
            'signalDecibels': signalDecibels,
            'band': band,
          };
        }
      }
    }

    return state.copyWith(
      wirelessConnections: connectionsMap,
    );
  }

  DeviceManagerState _getWANStatusModel(
    DeviceManagerState state,
    Map<String, dynamic>? data,
  ) {
    return state.copyWith(
      wanStatus: data != null ? RouterWANStatus.fromJson(data) : null,
    );
  }

  DeviceManagerState _getFirmwareStatus(
    DeviceManagerState state,
    Map<String, dynamic>? data,
  ) {
    return state.copyWith(
      isFirmwareUpToDate: data?['availableUpdate'] == null,
    );
  }

  String _getDeviceLocation(RouterDevice device) {
    for (final property in device.properties) {
      if (property.name == 'userDeviceLocation' && property.value.isNotEmpty) {
        return property.value;
      }
    }
    return _getDeviceName(device);
  }

  String _getDeviceName(RouterDevice device) {
    for (final property in device.properties) {
      if (property.name == 'userDeviceName' && property.value.isNotEmpty) {
        return property.value;
      }
    }

    bool isAndroidDevice = false;
    if (device.friendlyName != null) {
      final regExp =
          RegExp(r'^Android$|^android-[a-fA-F0-9]{16}.*|^Android-[0-9]+');
      isAndroidDevice = regExp.hasMatch(device.friendlyName!);
    }

    String? androidDeviceName;
    if (isAndroidDevice &&
        ['Mobile', 'Phone', 'Tablet'].contains(device.model.deviceType)) {
      final manufacturer = device.model.manufacturer;
      final modelNumber = device.model.modelNumber;
      if (manufacturer != null && modelNumber != null) {
        // e.g. 'Samsung Galaxy S8'
        androidDeviceName = '$manufacturer $modelNumber';
      } else if (device.unit.operatingSystem != null) {
        // e.g. 'Android Oreo Mobile'
        androidDeviceName =
            '${device.unit.operatingSystem!} ${device.model.deviceType}';
        if (manufacturer != null) {
          // e.g. 'Samsung Android Oreo Mobile'
          androidDeviceName = manufacturer + androidDeviceName;
        }
      }
    }

    if (androidDeviceName != null) {
      return androidDeviceName;
    } else if (device.friendlyName != null) {
      return device.friendlyName!;
    } else if (device.model.modelNumber != null) {
      return device.model.modelNumber!;
    } else {
      // Check if it's a guest device
      bool isGuest = false;
      for (final connectionDevice in device.connections) {
        isGuest = connectionDevice.isGuest ?? false;
      }
      return isGuest ? 'Guest Network Device' : 'Network Device';
    }
  }

  bool checkWiredConnection(RouterDevice device) {
    final interfaces = device.knownInterfaces;
    if (interfaces != null) {
      for (final interface in interfaces) {
        if (interface.interfaceType == 'Wired') {
          return true;
        }
      }
    }
    return false;
  }

  int getWirelessSignal(RouterDevice device) {
    var macAddress = '';
    if (device.knownInterfaces != null) {
      final knownInterface = device.knownInterfaces!.first;
      macAddress = knownInterface.macAddress;
    } else if (device.knownMACAddresses != null) {
      // This case is only for a part of old routers that does not support 'GetDevices3' action
      macAddress = device.knownMACAddresses!.firstOrNull ?? '';
    }
    final connections = state.wirelessConnections;
    final wirelessData = connections[macAddress];
    final signalDecibels = wirelessData?['signalDecibels'] as int?;
    return signalDecibels ?? 0;
  }

  Future<void> updateLocation(String newLocation) async {
    // Get the current target device Id
    final targetId = ref.read(deviceDetailIdProvider);
    final routerRepository = ref.read(routerRepositoryProvider);
    final result = await routerRepository.send(
      JNAPAction.setDeviceProperties,
      data: {
        'deviceID': targetId,
        'propertiesToModify': [
          {
            'name': 'userDeviceLocation',
            'value': newLocation,
          },
          {
            'name': 'userDeviceName',
            'value': newLocation,
          }
        ],
      },
      auth: true,
    );
    if (result.result == 'OK') {
      final newLocationMap = state.locationMap;
      newLocationMap[targetId] = newLocation;
      state = state.copyWith(
        locationMap: newLocationMap,
      );
    }
  }

  //TODO: Delete device by Ids function
  // Future<void> deleteDeviceList(List<DeviceDetailInfo> deviceInfoList) async {
  //   List<String> deviceIdList = deviceInfoList.map((e) => e.deviceID).toList();
  //   await _routerRepository
  //       .deleteDevices(deviceIdList)
  //       .then((value) => fetchDeviceList());
  // }

  //TODO: Update external device name function
  // Future<void> updateDeviceInfoName() async {
  //   await _routerRepository.send(JNAPAction.setDeviceProperties, data: {
  //     'deviceID': deviceInfo.deviceID,
  //     'propertiesToModify': {
  //       'name': userDefinedDeviceName,
  //       'value': name,
  //     },
  //   }).then((value) {
  //     //Update state
  //     fetchDeviceList();
  //   });
  // }

  //TODO: Reboot mesh system function
  // Future rebootMeshSystem() async {
  // emit(state.copyWith(
  //   isSystemRestarting: true,
  // ));
  // final results = await _repository.send(
  //   JNAPAction.reboot,
  //   auth: true,
  // );
  // if (results.result == 'OK') {
  //   Future.delayed(const Duration(seconds: 130), () {
  //     emit(state.copyWith(
  //       isSystemRestarting: false,
  //     ));
  //   });
  // } else {
  //   emit(state.copyWith(
  //     isSystemRestarting: false,
  //   ));
  // }
  // }
}
