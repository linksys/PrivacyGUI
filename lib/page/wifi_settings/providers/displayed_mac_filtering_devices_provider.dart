import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/models/device_list_item.dart';
import 'package:privacy_gui/core/utils/devices.dart'; // for getDeviceLocation extension
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_service.dart';

final macFilteringDeviceListProvider = Provider((ref) {
  final deviceManagerState = ref.watch(deviceManagerProvider);
  final wifiBundleState = ref.watch(wifiBundleProvider);

  // Filter for wireless devices only, as MAC filtering typically applies to wireless
  // Using externalDevices to include both online and offline devices if standard
  // or use logic similar to device manager.
  // Original code used deviceListState.devices.where((!isWired))
  // deviceListState comes from externalDevices.

  final deviceList = deviceManagerState.externalDevices
      .where((device) =>
          device.connectionType == 'wireless') // Simplified check or use helper
      .map((device) => DeviceListItem(
            name: device.getDeviceLocation(),
            macAddress: device.getMacAddress(),
            // Other fields are not strictly used by MacFilteringView/InputView for filtering display
            // but populating basic ones is good practice.
            isOnline: device.isOnline(),
            isWired: false,
          ))
      .toList();

  final macAddresses = wifiBundleState.current.privacy.denyMacAddresses;
  final bssidList = wifiBundleState.current.privacy.bssids;
  return ref.read(wifiSettingsServiceProvider).getFilteredDeviceList(
      allDevices: deviceList, macAddresses: macAddresses, bssidList: bssidList);
});
