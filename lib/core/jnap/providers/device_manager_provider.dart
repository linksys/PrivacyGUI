import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/services/device_manager_service.dart';
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
    final service = ref.read(deviceManagerServiceProvider);
    return service.transformPollingData(coreTransactionData);
  }

  void init() {
    state = const DeviceManagerState();
  }

  // Used in cases where the watched DeviceManager is still empty at very beginning stage
  bool isEmptyState() => state.deviceList.isEmpty;

  String? getSsidConnectedBy(LinksysDevice device) {
    // Get the SSID to the RadioID connected by the given device
    final wirelessConnections = state.wirelessConnections;
    final wirelessData = wirelessConnections[device.getMacAddress()];
    final radioID = wirelessData?.radioID;

    /// if connection type is guest just return any one of ssid, because it is all the same
    return device.connectedWifiType == WifiConnectionType.guest
        ? state.guestRadioSettings?.radios.firstOrNull?.guestSSID
        : state.radioInfos[radioID]?.settings.ssid;
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

  String? _getBandFromKnownInterfacesOf(LinksysDevice device) {
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

  // Update the name(location) of nodes and external devices
  Future<void> updateDeviceNameAndIcon({
    required String targetId,
    required String newName,
    required bool isLocation,
    IconDeviceCategory? icon,
  }) async {
    final service = ref.read(deviceManagerServiceProvider);
    final properties = await service.updateDeviceNameAndIcon(
      targetId: targetId,
      newName: newName,
      isLocation: isLocation,
      icon: icon,
    );

    // Update local state with the new properties
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

  Future<void> deleteDevices({required List<String> deviceIds}) async {
    final service = ref.read(deviceManagerServiceProvider);
    final results = await service.deleteDevices(deviceIds);

    // Remove successfully deleted devices from local state
    final completedIds =
        results.entries.where((e) => e.value).map((e) => e.key).toList();
    final newDeviceList = List<LinksysDevice>.from(state.deviceList);
    newDeviceList.removeWhere(
      (device) => completedIds.contains(device.deviceID),
    );
    state = state.copyWith(
      deviceList: newDeviceList,
    );

    // Trigger polling refresh
    await ref.read(pollingProvider.notifier).forcePolling();
  }

  Future<void> deauthClient({required String macAddress}) async {
    final service = ref.read(deviceManagerServiceProvider);
    await service.deauthClient(macAddress);

    // Trigger polling refresh
    await ref.read(pollingProvider.notifier).forcePolling();
  }
}
