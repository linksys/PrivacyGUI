import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_service.dart';

final macFilteringDeviceListProvider = Provider((ref) {
  final deviceListState = ref.watch(deviceListProvider);
  final wifiBundleState = ref.watch(wifiBundleProvider);
  final deviceList =
      deviceListState.devices.where((device) => !device.isWired).toList();
  final macAddresses = wifiBundleState.current.privacy.denyMacAddresses;
  final bssidList = wifiBundleState.current.privacy.bssids;
  return ref.read(wifiSettingsServiceProvider).getFilteredDeviceList(
      allDevices: deviceList, macAddresses: macAddresses, bssidList: bssidList);
});
