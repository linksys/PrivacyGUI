import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/back_haul_info.dart';
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
    Map<String, dynamic>? getBackHaulInfoData;

    final result = pollingResult?.data;
    if (result != null) {
      getDevicesData = (result[JNAPAction.getDevices] as JNAPSuccess?)?.output;
      getNetworkConnectionsData =
          (result[JNAPAction.getNetworkConnections] as JNAPSuccess?)?.output;
      getWANStatusData =
          (result[JNAPAction.getWANStatus] as JNAPSuccess?)?.output;
      getFirmwareUpdateStatusData =
          (result[JNAPAction.getFirmwareUpdateStatus] as JNAPSuccess?)?.output;
      getBackHaulInfoData =
          (result[JNAPAction.getBackhaulInfo] as JNAPSuccess?)?.output;
    }

    var newState = const DeviceManagerState();
    newState = _getDeviceListAndLocations(newState, getDevicesData);
    newState = _getWirelessConnections(newState, getNetworkConnectionsData);
    newState = _getWANStatusModel(newState, getWANStatusData);
    newState = _getFirmwareStatus(newState, getFirmwareUpdateStatusData);
    newState = _getBackhaukInfoData(newState, getBackHaulInfoData);
    return newState.copyWith(
      lastUpdateTime: pollingResult?.lastUpdate,
    );
  }

  DeviceManagerState _getBackhaukInfoData(
      DeviceManagerState state, Map<String, dynamic>? data) {
    var newState = state.copyWith(
        backhaulInfoData: List.from(data?['backhaulDevices'] ?? [])
            .map((e) => BackHaulInfoData.fromMap(e))
            .toList());
    // update ipAddr
    newState = newState.copyWith(
        deviceList: newState.deviceList.map((device) {
      final deviceID = device.deviceID;
      final backhaulInfo = newState.backhaulInfoData
          .firstWhereOrNull((backhaul) => backhaul.deviceUUID == deviceID);
      if (backhaulInfo != null && device.connections.isNotEmpty) {
        final updatedConnections = device.connections
            .map((connection) =>
                connection.copyWith(ipAddress: backhaulInfo.ipAddress))
            .toList();
        return device.copyWith(connections: updatedConnections);
      }
      return device;
    }).toList());
    return newState;
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
        final wirelessData =
            connectionData['wireless'] as Map<String, dynamic>?;
        if (wirelessData != null) {
          final band = wirelessData['band'];
          final signalDecibels = wirelessData['signalDecibels'];
          final isGuest = wirelessData['isGuest'];
          connectionsMap[macAddress] = {
            'signalDecibels': signalDecibels,
            'band': band,
            'isGuest': isGuest,
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
      // Check if it's connecting to the guest network
      // NOTE: This value can also be derived from 'NetworkConnections', but they should be identical
      final isGuest = device.connections.firstOrNull?.isGuest ?? false;
      return isGuest ? 'Guest Network Device' : 'Network Device';
    }
  }

  String getDeviceMacAddress(RouterDevice device) {
    var macAddress = '';
    if (device.knownInterfaces != null) {
      final knownInterface = device.knownInterfaces!.firstOrNull;
      macAddress = knownInterface?.macAddress ?? '';
    } else if (device.knownMACAddresses != null) {
      // This case is only for a part of old routers that does not support 'GetDevices3' action
      macAddress = device.knownMACAddresses!.firstOrNull ?? '';
    }
    return macAddress;
  }

  int getWirelessSignal(RouterDevice device) {
    final wirelessConnections = state.wirelessConnections;
    final wirelessData = wirelessConnections[getDeviceMacAddress(device)];
    final signalDecibels = wirelessData?['signalDecibels'] as int?;
    return signalDecibels ?? 0;
  }

  String getWirelessBand(RouterDevice device) {
    final wirelessConnections = state.wirelessConnections;
    final wirelessData = wirelessConnections[getDeviceMacAddress(device)];
    final band = wirelessData?['band'] as String?;
    return band ?? '';
  }

  bool checkIsGuestNetwork(RouterDevice device) {
    final wirelessConnections = state.wirelessConnections;
    final wirelessData = wirelessConnections[getDeviceMacAddress(device)];
    final isGuest = wirelessData?['isGuest'] as bool?;
    return isGuest ?? false;
  }

  bool checkIsWiredConnection(RouterDevice device) {
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

  RouterDevice? findParent(String deviceID) {
    final node = state.deviceList
        .firstWhereOrNull((element) => element.deviceID == deviceID);
    if (node == null) {
      return null;
    }
    if (node.connections.isEmpty) {
      return null;
    }
    String? parentIpAddr;
    for (var element in node.connections) {
      for (var backhaul in state.backhaulInfoData) {
        if (backhaul.ipAddress == element.ipAddress) {
          parentIpAddr = backhaul.parentIPAddress;
          break;
        }
      }
    }
    if (parentIpAddr == null) {
      return null;
    }
    return state.deviceList.firstWhereOrNull((element) =>
        element.connections
            .firstWhereOrNull((element) => element.ipAddress == parentIpAddr) !=
        null);
  }

  // Update the name(location) of nodes and external devices
  Future<void> updateDeviceName({
    required String newName,
    required bool isLocation,
  }) async {
    // Get the current target device Id
    final targetId = ref.read(deviceDetailIdProvider);
    final routerRepository = ref.read(routerRepositoryProvider);
    final result = await routerRepository.send(
      JNAPAction.setDeviceProperties,
      data: {
        'deviceID': targetId,
        'propertiesToModify': [
          if (isLocation)
            {
              'name': 'userDeviceLocation',
              'value': newName,
            },
          {
            'name': 'userDeviceName',
            'value': newName,
          }
        ],
      },
      auth: true,
    );
    if (result.result == 'OK') {
      final newLocationMap = state.locationMap;
      newLocationMap[targetId] = newName;
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
