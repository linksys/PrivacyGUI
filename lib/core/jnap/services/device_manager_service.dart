import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/layer2_connection.dart';
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

final deviceManagerServiceProvider = Provider<DeviceManagerService>((ref) {
  return DeviceManagerService(ref.watch(routerRepositoryProvider));
});

/// Service for device management operations.
///
/// Handles JNAP communication and transforms raw API responses
/// into DeviceManagerState. This isolates JNAP protocol details
/// from the DeviceManagerNotifier.
class DeviceManagerService {
  final RouterRepository _routerRepository;

  DeviceManagerService(this._routerRepository);

  // === Data Transformation ===

  /// Transforms polling data into DeviceManagerState.
  ///
  /// [pollingResult] - Raw JNAP transaction data from pollingProvider.
  ///                   Can be null during initial load.
  ///
  /// Returns: Complete DeviceManagerState with all device information.
  ///
  /// Behavior:
  /// - If [pollingResult] is null, returns empty default state
  /// - Processes all available JNAP action results
  /// - Skips failed actions gracefully (partial state)
  /// - Never throws - always returns valid state
  DeviceManagerState transformPollingData(CoreTransactionData? pollingResult) {
    Map<String, dynamic>? getNetworkConnectionsData;
    Map<String, dynamic>? getNodesWirelessNetworkConnectionsData;
    Map<String, dynamic>? getRadioInfo;
    Map<String, dynamic>? guestRadioSettings;
    Map<String, dynamic>? getDevicesData;
    Map<String, dynamic>? getWANStatusData;
    Map<String, dynamic>? getBackHaulInfoData;

    final result = pollingResult?.data;
    if (result != null) {
      // Safely extract output only from successful results
      JNAPSuccess? getSuccess(JNAPAction action) {
        final r = result[action];
        return r is JNAPSuccess ? r : null;
      }

      getNetworkConnectionsData =
          getSuccess(JNAPAction.getNetworkConnections)?.output;
      getNodesWirelessNetworkConnectionsData =
          getSuccess(JNAPAction.getNodesWirelessNetworkConnections)?.output;
      getRadioInfo = getSuccess(JNAPAction.getRadioInfo)?.output;
      getDevicesData = getSuccess(JNAPAction.getDevices)?.output;
      getWANStatusData = getSuccess(JNAPAction.getWANStatus)?.output;
      getBackHaulInfoData = getSuccess(JNAPAction.getBackhaulInfo)?.output;
      guestRadioSettings =
          getSuccess(JNAPAction.getGuestRadioSettings)?.output;
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
    newState = _getBackhaulInfoData(newState, getBackHaulInfoData);
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
    var externalDevices =
        allDevices.where((device) => device.nodeType == null).toList();

    // Collect all the connected devices for nodes
    nodes = nodes.fold(<LinksysDevice>[], (list, node) {
      final connectedDevices = externalDevices.where((device) {
        // Make sure the external device is online
        if (device.isOnline()) {
          // There usually be only one item
          final parentDeviceId = device.connections.firstOrNull?.parentDeviceID;
          // For orphan nodes, don't calculate into any nodes
          return parentDeviceId == node.deviceID;
        }
        return false;
      }).toList();

      return list..add(node.copyWith(connectedDevices: connectedDevices));
    }).toList();

    // Determine connected Wi-Fi network for each external device
    final wirelessConnections = state.wirelessConnections;
    externalDevices = externalDevices.map((device) {
      final wirelessData = wirelessConnections[device.getMacAddress()];
      final isGuestDevice = wirelessData?.isGuest ?? false;
      // Get the list of MLO capable radio IDs
      final mloList = device.knownInterfaces?.map((e) {
        final wirelessData = wirelessConnections[e.macAddress];
        if (wirelessData != null) {
          return wirelessData.isMLOCapable == true
              ? wirelessData.radioID ?? ''
              : '';
        }
        return '';
      }).toList()
        ?..removeWhere((e) => e.isEmpty);
      return device.copyWith(
        connectedWifiType:
            isGuestDevice ? WifiConnectionType.guest : WifiConnectionType.main,
        mloList: mloList,
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

  DeviceManagerState _getBackhaulInfoData(
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
    final wirelessConnectionInfo = newState.wirelessConnections;
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
        wirelessConnectionInfo[mac] = WirelessConnection(
          bssid: bssid ?? '',
          isGuest: false,
          radioID: 'RADIO_${band}z',
          band: '${band}z',
          signalDecibels: rssi,
        );
      }
    });
    newState = newState.copyWith(wirelessConnections: wirelessConnectionInfo);

    // update wireless signal for each device
    final devices = newState.deviceList
        .map((e) => e.copyWith(
              signalDecibels: e.wirelessConnectionInfo?.stationRSSI ??
                  _getWirelessSignalOf(e, newState),
              connectedDevices: e.connectedDevices
                  .map((e) =>
                      e.copyWith(signalDecibels: _getWirelessSignalOf(e, newState)))
                  .toList(),
            ))
        .toList();
    newState = newState.copyWith(deviceList: devices);
    return newState;
  }

  DeviceManagerState _checkUpstream(DeviceManagerState state) {
    return state.copyWith(
        deviceList: List<LinksysDevice>.from(state.deviceList)
            .map((e) => e.isAuthority
                ? e
                : e.copyWith(upstream: _findParent(e.deviceID, state)))
            .toList());
  }

  int? _getWirelessSignalOf(RawDevice device, DeviceManagerState currentState) {
    final wirelessConnections = currentState.wirelessConnections;
    final wirelessData = wirelessConnections[device.getMacAddress()];
    final signalDecibels = wirelessData?.signalDecibels;
    return signalDecibels;
  }

  LinksysDevice? _findParent(String deviceID, DeviceManagerState currentState) {
    final master = currentState.masterDevice;
    final device = currentState.deviceList
        .firstWhereOrNull((element) => element.deviceID == deviceID);
    if (device == null) {
      return null;
    }
    if (!device.isOnline()) {
      return null;
    }
    String? parentIpAddr;

    // Check connections from backhaul info data.
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
        (device.nodeType != null ? master : null);
  }

  // === Write Operations ===

  /// Updates device name and/or icon.
  ///
  /// [targetId] - Device ID to update
  /// [newName] - New display name for the device
  /// [isLocation] - If true, also updates userDeviceLocation
  /// [icon] - Optional icon category to set
  ///
  /// Returns: List of updated device properties
  ///
  /// Throws: [ServiceError] on JNAP failure
  Future<List<RawDeviceProperty>> updateDeviceNameAndIcon({
    required String targetId,
    required String newName,
    required bool isLocation,
    IconDeviceCategory? icon,
  }) async {
    List<RawDeviceProperty> properties = [
      RawDeviceProperty(name: 'userDeviceName', value: newName),
      if (isLocation)
        RawDeviceProperty(name: 'userDeviceLocation', value: newName),
      if (icon != null)
        RawDeviceProperty(name: 'userDeviceType', value: icon.name),
    ];

    try {
      final result = await _routerRepository.send(
        JNAPAction.setDeviceProperties,
        data: {
          'deviceID': targetId,
          'propertiesToModify': properties.map((e) => e.toMap()).toList(),
        },
        auth: true,
      );

      // Refresh device list after update
      await _routerRepository.send(
        JNAPAction.getDevices,
        fetchRemote: true,
        auth: true,
      );

      if (result.result != 'OK') {
        throw UnexpectedError(
          originalError: result,
          message: 'Failed to update device properties: ${result.result}',
        );
      }

      return properties;
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Deletes devices from the network.
  ///
  /// [deviceIds] - List of device IDs to delete
  ///
  /// Returns: Map of deviceId → success/failure status
  ///
  /// Behavior:
  /// - Empty list returns empty map immediately (no-op)
  /// - Processes deletions in bulk
  /// - Partial failures are reflected in return map
  Future<Map<String, bool>> deleteDevices(List<String> deviceIds) async {
    if (deviceIds.isEmpty) {
      return {};
    }

    final dataResults = await _routerRepository.deleteDevices(deviceIds);
    final idResults = Map.fromIterables(deviceIds, dataResults)
        .entries
        .map((entry) => MapEntry(entry.key, entry.value.value.result == 'OK'));
    return Map.fromEntries(idResults);
  }

  /// Deauthenticates a client device.
  ///
  /// [macAddress] - MAC address of device to disconnect
  ///
  /// Throws: [ServiceError] on JNAP failure
  Future<void> deauthClient(String macAddress) async {
    try {
      await _routerRepository.send(
        JNAPAction.clientDeauth,
        data: {
          'macAddress': macAddress,
        }..removeWhere((key, value) => value == null),
        auth: true,
        cacheLevel: CacheLevel.noCache,
        fetchRemote: true,
      );
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Maps JNAP errors to ServiceError types
  ServiceError _mapJnapError(JNAPError error) {
    return switch (error.result) {
      '_ErrorUnauthorized' => const UnauthorizedError(),
      'ErrorDeviceNotFound' => const ResourceNotFoundError(),
      'ErrorInvalidInput' => InvalidInputError(message: error.error),
      _ => UnexpectedError(originalError: error, message: error.result),
    };
  }
}
