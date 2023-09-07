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
    var allDevices = <LinksysDevice>[];
    if (data != null) {
      allDevices = List.from(
        data['devices'],
      ).map((e) => LinksysDevice.fromMap(e)).toList();
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
    var nodes = allDevices.where((device) => device.nodeType != null).toList();
    final masterNode = nodes.firstWhereOrNull((node) => node.isAuthority);
    var externalDevices =
        allDevices.where((device) => device.nodeType == null).toList();
    // collect all the connected devices for nodes
    nodes = nodes.fold(<LinksysDevice>[], (list, node) {
      final connectedDevices = externalDevices.where((device) {
        // Make sure the external device is online
        if (device.connections.isNotEmpty) {
          // There usually be only one item
          final parentDeviceId = device.connections.firstOrNull?.parentDeviceID;
          // Count it if this item's parentId is the target device,
          // or if its parentId is null and the target device is master
          return ((parentDeviceId == node.deviceID) ||
              (parentDeviceId == null &&
                  node.deviceID == masterNode?.deviceID));
        }
        return false;
      }).toList();

      return list..add(node.copyWith(connectedDevices: connectedDevices));
    }).toList();

    return state.copyWith(
      deviceList: [...nodes, ...externalDevices],
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
    List<PropertyDevice> properties = [
      if (isLocation)
        PropertyDevice(name: 'userDeviceLocation', value: newName),
      PropertyDevice(name: 'userDeviceName', value: newName)
    ];
    final result = await routerRepository.send(
      JNAPAction.setDeviceProperties,
      data: {
        'deviceID': targetId,
        'propertiesToModify': properties.map((e) => e.toMap()),
      },
      auth: true,
    );
    if (result.result == 'OK') {
      final newList = state.deviceList.fold(<LinksysDevice>[], (list, element) {
        if (element.deviceID == targetId) {
          list.add(element.copyWith(properties: properties));
        } else {
          list.add(element);
        }
        return list;
      });
      state = state.copyWith(deviceList: newList);
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
