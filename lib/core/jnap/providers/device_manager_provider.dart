import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';

class DeviceManagerNotifier extends Notifier<DeviceManagerState> {
  @override
  DeviceManagerState build() {
    final pollingResult = ref.watch(pollingProvider).value;
    print(
        "XXXXXX Dev Mgr Notifier Build: polling iTems=${pollingResult?.data.length}, updateTime=${pollingResult?.lastUpdate}");
    return createState(pollingResult);
  }

  DeviceManagerState createState(CoreTransactionData? coreTransactionData) {
    Map<String, dynamic>? getDevicesData;
    Map<String, dynamic>? getNetworkConnectionsData;
    Map<String, dynamic>? getWANStatusData;
    Map<String, dynamic>? getFirmwareUpdateStatusData;

    final result = coreTransactionData?.data;
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
      lastUpdateTime: coreTransactionData?.lastUpdate,
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
      // if (device.isAuthority || device.nodeType == 'Master') {
      //   locationMap[device.deviceID] = _getDeviceLocation(device);
      // } else if (device.nodeType == 'Slave') {
      //   locationMap[device.deviceID] = _getDeviceLocation(device);
      // }
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
      final connections = (data['connections']
          as List); //.whereType<Map<String, dynamic>>().toList();
      for (final connection in connections) {
        final mappp = connection as Map<String, dynamic>;
        final macAddress = mappp['macAddress'];
        final Map<String, dynamic>? wirelessData = mappp['wireless'];
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
}

final deviceManagerProvider =
    NotifierProvider<DeviceManagerNotifier, DeviceManagerState>(
  () => DeviceManagerNotifier(),
);
