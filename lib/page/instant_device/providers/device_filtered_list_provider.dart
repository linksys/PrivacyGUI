import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/util/extensions.dart';

final filteredDeviceListProvider = Provider((ref) {
  final config = ref.watch(deviceFilterConfigProvider);
  final deviceListState = ref.watch(deviceListProvider);
  final nodeId = config.nodeFilter;
  final band = config.bandFilter;
  final connection = config.connectionFilter;
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

  void initFilter({List<String>? preselectedNodeId}) {
    final nodes = preselectedNodeId ?? getNodes();

    final bands = getBands(
        preselectedNodeId?.length == 1 ? preselectedNodeId?.first : null);
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

  List<String> getBands([String? deviceUUID]) {
    final deviceManagerState = ref.read(deviceManagerProvider);
    final nodes = deviceManagerState.nodeDevices;
    final target =
        nodes.firstWhereOrNull((device) => device.deviceID == deviceUUID);
    final radios = (target == null
            ? deviceManagerState.externalDevices
            : target.connectedDevices)
        .fold(<String>{}, (radios, device) {
      final radio =
          ref.read(deviceManagerProvider.notifier).getBandConnectedBy(device);
      if (radio.isNotEmpty) {
        radios.add(radio);
      }
      return radios;
    });
    logger.i(
        'Filter<$deviceUUID>:: Collect additional radios from connected devices: $radios');
    return (ref
            .read(dashboardManagerProvider)
            .mainRadios
            .unique((x) => x.band)
            .map((e) => e.band)
            .toList()
          ..addAll(radios)
          ..add('Ethernet'))
        .unique((x) => x);
  }

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
