import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
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
    Map<String, dynamic>? getNetworkConnectionsData;
    Map<String, dynamic>? getDevicesData;
    Map<String, dynamic>? getWANStatusData;
    Map<String, dynamic>? getFirmwareUpdateStatusData;
    Map<String, dynamic>? getBackHaulInfoData;

    final result = pollingResult?.data;
    if (result != null) {
      getNetworkConnectionsData =
          (result[JNAPAction.getNetworkConnections] as JNAPSuccess?)?.output;
      getDevicesData = (result[JNAPAction.getDevices] as JNAPSuccess?)?.output;
      getWANStatusData =
          (result[JNAPAction.getWANStatus] as JNAPSuccess?)?.output;
      getFirmwareUpdateStatusData =
          (result[JNAPAction.getFirmwareUpdateStatus] as JNAPSuccess?)?.output;
      getBackHaulInfoData =
          (result[JNAPAction.getBackhaulInfo] as JNAPSuccess?)?.output;
    }

    var newState = const DeviceManagerState();
    newState = _getWirelessConnections(newState, getNetworkConnectionsData);
    // The data process of NetworkConnections MUST be done before building device list
    newState = _getDeviceListAndLocations(newState, getDevicesData);
    newState = _getWANStatusModel(newState, getWANStatusData);
    newState = _getFirmwareStatus(newState, getFirmwareUpdateStatusData);
    newState = _getBackhaukInfoData(newState, getBackHaulInfoData);
    return newState.copyWith(
      lastUpdateTime: pollingResult?.lastUpdate,
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

    // Collect all the connected devices for nodes
    nodes = nodes.fold(<LinksysDevice>[], (list, node) {
      final connectedDevices = externalDevices.where((device) {
        // Make sure the external device is online
        if (device.connections.isNotEmpty) {
          // There usually be only one item
          final parentDeviceId = device.connections.firstOrNull?.parentDeviceID;
          // Count it if this item's parentId is the target node,
          // or if its parentId is null and the target node is master
          return ((parentDeviceId == node.deviceID) ||
              (parentDeviceId == null &&
                  node.deviceID == masterNode?.deviceID));
        }
        return false;
      }).toList();

      return list..add(node.copyWith(connectedDevices: connectedDevices));
    }).toList();

    // Determine connected Wi-Fi network for each external deivce
    final wirelessConnections = state.wirelessConnections;
    externalDevices = externalDevices.map((device) {
      final wirelessData = wirelessConnections[getDeviceMacAddress(device)];
      final isGuestDevice = (wirelessData?['isGuest'] as bool?) ?? false;
      return device.copyWith(
        connectedWifiType:
            isGuestDevice ? WifiConnectionType.guest : WifiConnectionType.main,
      );
    }).toList();

    return state.copyWith(
      deviceList: [...nodes, ...externalDevices],
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

  DeviceManagerState _getBackhaukInfoData(
    DeviceManagerState state,
    Map<String, dynamic>? data,
  ) {
    var newState = state.copyWith(
      backhaulInfoData: List.from(
        data?['backhaulDevices'] ?? [],
      ).map((e) => BackHaulInfoData.fromMap(e)).toList(),
    );
    // Update IP address
    newState = newState.copyWith(
      deviceList: newState.deviceList.map((device) {
        final deviceId = device.deviceID;
        final backhaulInfo = newState.backhaulInfoData
            .firstWhereOrNull((backhaul) => backhaul.deviceUUID == deviceId);
        if (backhaulInfo != null && device.connections.isNotEmpty) {
          // Replace the IP in Devices with the one from BackhaulInfo
          final updatedConnections = device.connections
              .map(
                (connection) => connection.copyWith(
                  ipAddress: backhaulInfo.ipAddress,
                ),
              )
              .toList();
          return device.copyWith(connections: updatedConnections);
        }
        return device;
      }).toList(),
    );
    return newState;
  }

  // Used in cases where the watched DeviceManager is still empty at very beginning stage
  bool isEmptyState() => state.deviceList.isEmpty;

  String getDeviceMacAddress(RawDevice device) {
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

  int getWirelessSignal(RawDevice device) {
    final wirelessConnections = state.wirelessConnections;
    final wirelessData = wirelessConnections[getDeviceMacAddress(device)];
    final signalDecibels = wirelessData?['signalDecibels'] as int?;
    return signalDecibels ?? 0;
  }

  String getWirelessBand(RawDevice device) {
    final wirelessConnections = state.wirelessConnections;
    final wirelessData = wirelessConnections[getDeviceMacAddress(device)];
    final band = (wirelessData?['band'] ?? _getWirelessBandFromDevices(device))
        as String?;
    return band ?? (checkIsWiredConnection(device) ? 'Ethernet' : '');
  }

  String? _getWirelessBandFromDevices(RawDevice device) {
    return device.knownInterfaces
        ?.firstWhereOrNull(
            (knownInterface) => knownInterface.interfaceType == 'Wireless')
        ?.band;
  }

  bool checkIsWiredConnection(RawDevice device) {
    final interfaces = device.knownInterfaces;
    return interfaces
            ?.firstWhereOrNull((element) => element.interfaceType == 'Wired') !=
        null;
  }

  RawDevice? findParent(String deviceID) {
    final device = state.deviceList
        .firstWhereOrNull((element) => element.deviceID == deviceID);
    if (device == null) {
      return null;
    }
    if (device.connections.isEmpty) {
      return null;
    }
    String? parentIpAddr;
    for (var element in device.connections) {
      for (var backhaul in state.backhaulInfoData) {
        if (backhaul.ipAddress == element.ipAddress) {
          parentIpAddr = backhaul.parentIPAddress;
          break;
        }
      }
    }
    //
    if (parentIpAddr != null) {
      return state.deviceList.firstWhereOrNull((element) =>
          element.connections.firstWhereOrNull(
              (element) => element.ipAddress == parentIpAddr) !=
          null);
    }
    //
    // There usually be only one item
    final parentDeviceId = device.connections.firstOrNull?.parentDeviceID;
    // Count it if this item's parentId is the target node,
    // or if its parentId is null and the target node is master
    return state.deviceList
        .firstWhereOrNull((element) => parentDeviceId == element.deviceID);
  }

  // Update the name(location) of nodes and external devices
  Future<void> updateDeviceName({
    required String newName,
    required bool isLocation,
  }) async {
    // Get the current target device Id
    final targetId = ref.read(deviceDetailIdProvider);
    final routerRepository = ref.read(routerRepositoryProvider);
    List<RawDeviceProperty> properties = [
      if (isLocation)
        RawDeviceProperty(name: 'userDeviceLocation', value: newName),
      RawDeviceProperty(name: 'userDeviceName', value: newName)
    ];
    final result = await routerRepository.send(
      JNAPAction.setDeviceProperties,
      data: {
        'deviceID': targetId,
        'propertiesToModify': properties.map((e) => e.toMap()).toList(),
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

  Future<bool> getLEDLight() async {
    final routerRepository = ref.read(routerRepositoryProvider);
    final result = await routerRepository.send(
      JNAPAction.getLedNightModeSetting,
      auth: true,
      cacheLevel: CacheLevel.noCache,
    );
    if (result.result == 'OK') {
      return result.output['Enable'];
    }
    return false;
  }

  Future<void> setLEDLight(bool isOn) async {
    final routerRepository = ref.read(routerRepositoryProvider);
    await routerRepository.send(
      JNAPAction.setLedNightModeSetting,
      data: {'Enable': isOn},
      auth: true,
    );
  }

  Future<void> deleteDevices({required List<String> deviceIds}) {
    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository.deleteDevices(deviceIds).then((dataResults) {
      final idResults = Map.fromIterables(deviceIds, dataResults)
          .entries
          .map((entry) => MapEntry(entry.key, entry.value.value));
      final idResultsMap = Map.fromEntries(idResults);
      idResultsMap.removeWhere((key, value) => value.result != 'OK');
      final completedIds = idResultsMap.keys.toList();
      final newDeviceList = state.deviceList;
      newDeviceList.removeWhere(
        (device) => completedIds.contains(device.deviceID),
      );
      state = state.copyWith(
        deviceList: newDeviceList,
      );
    });
  }

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
