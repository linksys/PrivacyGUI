import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/layer2_connection.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/models/node_wireless_connection.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/models/wirless_connection.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';

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
    Map<String, dynamic>? getNodesWirelessNetworkConnectionsData;
    Map<String, dynamic>? getRadioInfo;
    Map<String, dynamic>? guestRadioSettings;
    Map<String, dynamic>? getDevicesData;
    Map<String, dynamic>? getWANStatusData;
    Map<String, dynamic>? getBackHaulInfoData;

    final result = pollingResult?.data;
    if (result != null) {
      getNetworkConnectionsData =
          (result[JNAPAction.getNetworkConnections] as JNAPSuccess?)?.output;
      getNodesWirelessNetworkConnectionsData =
          (result[JNAPAction.getNodesWirelessNetworkConnections]
                  as JNAPSuccess?)
              ?.output;
      getRadioInfo = (result[JNAPAction.getRadioInfo] as JNAPSuccess?)?.output;
      getDevicesData = (result[JNAPAction.getDevices] as JNAPSuccess?)?.output;
      getWANStatusData =
          (result[JNAPAction.getWANStatus] as JNAPSuccess?)?.output;
      getBackHaulInfoData =
          (result[JNAPAction.getBackhaulInfo] as JNAPSuccess?)?.output;
      guestRadioSettings =
          (result[JNAPAction.getGuestRadioSettings] as JNAPSuccess?)?.output;
    }
    final List<Layer2Connection> connectionData;
    if (getNodesWirelessNetworkConnectionsData != null) {
      final nodeWirelessConnections = List.from(
          getNodesWirelessNetworkConnectionsData['nodeWirelessConnections'] ??
              []);
      connectionData = nodeWirelessConnections.fold<List<Layer2Connection>>([],
          (previousValue, element) {
        final nodeWirelessConnection = NodeWirelessConnections.fromMap(element);

        previousValue.addAll(nodeWirelessConnection.connections);
        return previousValue;
      });
    } else {
      connectionData =
          List.from(getNetworkConnectionsData?['connections'] ?? [])
              .map((e) => Layer2Connection.fromMap(e))
              .toList();
    }

    // Radio settings
    final radioList = List.from(getRadioInfo?['radios'] ?? [])
        .map((e) => RouterRadio.fromMap(e))
        .toList();
    final radioMap =
        Map.fromEntries(radioList.map((e) => MapEntry(e.radioID, e)));

    var newState = const DeviceManagerState();
    newState = _getWirelessConnections(newState, connectionData);
    // The data process of NetworkConnections MUST be done before building device list
    newState = _getDeviceListAndLocations(newState, getDevicesData);
    newState = _getWANStatusModel(newState, getWANStatusData);
    newState = _getBackhaukInfoData(newState, getBackHaulInfoData);
    newState = newState.copyWith(radioInfos: radioMap);
    newState = newState.copyWith(
        guestRadioSettings: guestRadioSettings == null
            ? null
            : GuestRadioSettings.fromMap(guestRadioSettings));
    newState = _checkUpstream(newState);

    newState = newState.copyWith(
      lastUpdateTime: pollingResult?.lastUpdate,
    );
    return newState;
  }

  DeviceManagerState _getWirelessConnections(
    DeviceManagerState state,
    List<Layer2Connection>? data,
  ) {
    var connectionsMap = <String, WirelessConnection>{};
    if (data != null) {
      final connections = data;
      for (final connectionData in connections) {
        final macAddress = connectionData.macAddress;
        final wirelessData = connectionData.wireless;
        if (wirelessData != null) {
          connectionsMap[macAddress] = wirelessData;
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
      )
          .map((e) => LinksysDevice.fromMap(e))
          // .map((e) => e.copyWith(signalDecibels: getWirelessSignalOf(e, state)))
          .toList();
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
    var externalDevices =
        allDevices.where((device) => device.nodeType == null).toList();
    final masterId =
        nodes.firstWhereOrNull((node) => node.isAuthority)?.deviceID;

    // Collect all the connected devices for nodes
    nodes = nodes.fold(<LinksysDevice>[], (list, node) {
      final connectedDevices = externalDevices.where((device) {
        // Make sure the external device is online
        if (device.isOnline()) {
          // There usually be only one item
          final parentDeviceId = device.connections.firstOrNull?.parentDeviceID;
          // Count it if this item's parentId is the target node,
          // or if its parentId is null and the target node is master
          return ((parentDeviceId == node.deviceID) ||
              (parentDeviceId == null && node.deviceID == masterId));
        }
        return false;
      }).toList();

      return list..add(node.copyWith(connectedDevices: connectedDevices));
    }).toList();

    // Determine connected Wi-Fi network for each external deivce
    final wirelessConnections = state.wirelessConnections;
    externalDevices = externalDevices.map((device) {
      final wirelessData = wirelessConnections[device.getMacAddress()];
      final isGuestDevice = wirelessData?.isGuest ?? false;
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
      wanStatus: data != null ? RouterWANStatus.fromMap(data) : null,
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
        if (backhaulInfo != null && device.isOnline()) {
          // Replace the IP in Devices with the one from BackhaulInfo
          final updatedConnections = device.connections
              .map(
                (connection) => connection.copyWith(
                  ipAddress: backhaulInfo.ipAddress,
                ),
              )
              .toList();
          final newDevice = device.copyWith(
            connections: updatedConnections,
            wirelessConnectionInfo: backhaulInfo.wirelessConnectionInfo,
            speedMbps: backhaulInfo.speedMbps,
            connectionType: backhaulInfo.connectionType,
          );
          return newDevice;
        }
        return device;
      }).toList(),
    );
    final wireleeConnectionInfo = newState.wirelessConnections;
    newState.backhaulInfoData
        .where((element) =>
            element.connectionType == 'Wireless' &&
            element.wirelessConnectionInfo != null)
        .forEach((element) {
      final mac = element.wirelessConnectionInfo?.stationBSSID;
      final rssi = element.wirelessConnectionInfo?.stationRSSI;
      final band = element.wirelessConnectionInfo?.radioID;
      final bssid = element.wirelessConnectionInfo?.apBSSID;
      if (mac != null && rssi != null) {
        wireleeConnectionInfo[mac] = WirelessConnection(
          bssid: bssid ?? '',
          isGuest: false,
          radioID: 'RADIO_${band}z',
          band: '${band}z',
          signalDecibels: rssi,
        );
      }
    });
    newState = newState.copyWith(wirelessConnections: wireleeConnectionInfo);

    // update wireless signal for each device
    final devices = newState.deviceList
        .map((e) => e.copyWith(
              signalDecibels: e.wirelessConnectionInfo?.stationRSSI ??
                  _getWirelessSignalOf(e, state),
              connectedDevices: e.connectedDevices
                  .map((e) => e.copyWith(
                      signalDecibels: _getWirelessSignalOf(e, state)))
                  .toList(),
            ))
        .toList();
    newState = newState.copyWith(deviceList: devices);
    return newState;
  }

  DeviceManagerState _checkUpstream(
    DeviceManagerState state,
  ) {
    return state.copyWith(
        deviceList: List<LinksysDevice>.from(state.deviceList)
            .map((e) => e.isAuthority
                ? e
                : e.copyWith(upstream: findParent(e.deviceID, state)))
            .toList());
  }

  // Used in cases where the watched DeviceManager is still empty at very beginning stage
  bool isEmptyState() => state.deviceList.isEmpty;

  String? getSsidConnectedBy(LinksysDevice device) {
    // Get the SSID to the RadioID connected by the given device
    final wirelessConnections = state.wirelessConnections;
    final wirelessData = wirelessConnections[device.getMacAddress()];
    final radioID = wirelessData?.radioID;
    return device.connectedWifiType == WifiConnectionType.guest
        ? state.guestRadioSettings?.radios
            .firstWhereOrNull((element) => element.radioID == radioID)
            ?.guestSSID
        : state.radioInfos[radioID]?.settings.ssid;
  }

  int? _getWirelessSignalOf(RawDevice device,
      [DeviceManagerState? currentState]) {
    final wirelessConnections = (currentState ?? state).wirelessConnections;
    final wirelessData = wirelessConnections[device.getMacAddress()];
    final signalDecibels = wirelessData?.signalDecibels;
    return signalDecibels;
  }

  String getBandConnectedBy(LinksysDevice device) {
    final wirelessConnections = state.wirelessConnections;
    final wirelessData = wirelessConnections[device.getMacAddress()];
    // If the band data is absent in (NodesWireless)NetworkConnection,
    // check the knownInterface in GetDevices
    final band = wirelessData?.band ?? _getBandFromKnownInterfacesOf(device);
    return band ??
        (device.getConnectionType() == DeviceConnectionType.wired
            ? 'Ethernet'
            : '');
  }

  String? _getBandFromKnownInterfacesOf(RawDevice device) {
    return device.knownInterfaces
        ?.firstWhereOrNull(
            (knownInterface) => knownInterface.interfaceType == 'Wireless')
        ?.band;
  }

  LinksysDevice? findParent(String deviceID, [DeviceManagerState? current]) {
    final currentState = current ?? state;
    final master = currentState.masterDevice;
    final device = currentState.deviceList
        .firstWhereOrNull((element) => element.deviceID == deviceID);
    if (device == null) {
      return master;
    }
    if (!device.isOnline()) {
      return master;
    }
    String? parentIpAddr;
    for (var element in device.connections) {
      for (var backhaul in currentState.backhaulInfoData) {
        if (backhaul.ipAddress == element.ipAddress) {
          parentIpAddr = backhaul.parentIPAddress;
          break;
        }
      }
    }
    //
    if (parentIpAddr != null) {
      return currentState.deviceList.firstWhereOrNull((element) =>
              element.connections.firstWhereOrNull(
                  (element) => element.ipAddress == parentIpAddr) !=
              null) ??
          master;
    }
    //
    // There usually be only one item
    final parentDeviceId = device.connections.firstOrNull?.parentDeviceID;
    // Count it if this item's parentId is the target node,
    // or if its parentId is null and the target node is master
    return currentState.deviceList.firstWhereOrNull(
            (element) => parentDeviceId == element.deviceID) ??
        master;
  }

  // Update the name(location) of nodes and external devices
  Future<void> updateDeviceNameAndIcon({
    required String targetId,
    required String newName,
    required bool isLocation,
    IconDeviceCategory? icon,
  }) async {
    final routerRepository = ref.read(routerRepositoryProvider);
    List<RawDeviceProperty> properties = [
      RawDeviceProperty(name: 'userDeviceName', value: newName),
      if (isLocation)
        RawDeviceProperty(name: 'userDeviceLocation', value: newName),
      if (icon != null)
        RawDeviceProperty(name: 'userDeviceType', value: icon.name),
    ];
    final result = await routerRepository.send(
      JNAPAction.setDeviceProperties,
      data: {
        'deviceID': targetId,
        'propertiesToModify': properties.map((e) => e.toMap()).toList(),
      },
      auth: true,
    );
    await routerRepository.send(JNAPAction.getDevices,
        fetchRemote: true, auth: true);
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

  Future<NodeLightSettings> getLEDLight() async {
    final routerRepository = ref.read(routerRepositoryProvider);
    final result = await routerRepository.send(
      JNAPAction.getLedNightModeSetting,
      auth: true,
      cacheLevel: CacheLevel.noCache,
    );
    return NodeLightSettings.fromMap(result.output);
  }

  Future<void> setLEDLight(NodeLightSettings settings) async {
    final routerRepository = ref.read(routerRepositoryProvider);
    await routerRepository.send(
      JNAPAction.setLedNightModeSetting,
      data: {
        'Enable': settings.isNightModeEnable,
        'StartingTime': settings.startHour,
        'EndingTime': settings.endHour,
      }..removeWhere((key, value) => value == null),
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
      final newDeviceList = List<LinksysDevice>.from(state.deviceList);
      newDeviceList.removeWhere(
        (device) => completedIds.contains(device.deviceID),
      );
      state = state.copyWith(
        deviceList: newDeviceList,
      );
    }).then((value) => routerRepository.send(
          JNAPAction.getDevices,
          fetchRemote: true,
          auth: true,
        ));
  }
}
