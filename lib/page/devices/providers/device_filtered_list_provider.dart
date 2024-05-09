import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/devices/providers/device_filtered_list_state.dart';
import 'package:linksys_app/page/devices/providers/device_list_provider.dart';
import 'package:linksys_app/util/extensions.dart';

final filteredDeviceListProvider = Provider((ref) {
  final config = ref.watch(deviceFilterConfigProvider);
  final deviceListState = ref.watch(deviceListProvider);
  final nodeId = config.nodeFilter;
  final band = config.bandFilter;
  final connection = config.connectionFilter;
  logger.d('XXXXXX: ${deviceListState.devices}');
  final filteredDevices = deviceListState.devices
      // .where(
      //   (device) => ssidFilter == null ? true : device.type == ssidFilter,
      // )
      .where((device) => connection == device.isOnline)
      .where((device) {
        if (!device.isOnline) {
          return true;
        }
        if (nodeId.contains(device.upstreamDeviceID)) {
          return true;
        } else {
          return false;
        }
      })
      .where((device) => device.isOnline ? band.contains(device.band) : true)
      .toList();
  return filteredDevices;
});

final deviceFilterConfigProvider =
    NotifierProvider<DeviceFilterConfigNotifier, DeviceFilterConfigState>(
        () => DeviceFilterConfigNotifier());

class DeviceFilterConfigNotifier extends Notifier<DeviceFilterConfigState> {
  @override
  DeviceFilterConfigState build() {
    return const DeviceFilterConfigState(
        connectionFilter: true, nodeFilter: [], bandFilter: []);
  }

  void initFilter() {
    final nodes = getNodes();

    final bands = getBands();
    state = state.copyWith(
        connectionFilter: true, nodeFilter: nodes, bandFilter: bands);
  }

  List<String> getNodes() {
    return ref
        .read(deviceManagerProvider)
        .nodeDevices
        .map((e) => e.deviceID)
        .toList();
  }

  List<String> getBands() => ref
      .read(dashboardManagerProvider)
      .mainRadios
      .unique((x) => x.band)
      .map((e) => e.band)
      .toList()
    ..add('Ethernet');

  void updateConnectionFilter(bool value) {
    state = state.copyWith(connectionFilter: value);
  }

  void updateNodeFilter(List<String> nodes) {
    state = state.copyWith(nodeFilter: nodes);
  }

  void updateBandFilter(List<String> bands) {
    state = state.copyWith(bandFilter: bands);
  }
}
