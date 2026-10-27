import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';

class FixedDevicesDataNotifierForTopology extends DevicesDataNotifier {
  final DevicesData _fixedData;

  FixedDevicesDataNotifierForTopology(this._fixedData);

  @override
  Future<DevicesData> build() async => _fixedData;
}

class FixedSystemInfoDataNotifierForTopology extends SystemInfoDataNotifier {
  final SystemInfoData _fixedData;

  FixedSystemInfoDataNotifierForTopology(this._fixedData);

  @override
  Future<SystemInfoData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

List<Override> topologyViewOverrides({
  required DevicesData devicesData,
  required SystemInfoData systemInfoData,
}) =>
    [
      devicesDataProvider.overrideWith(
        () => FixedDevicesDataNotifierForTopology(devicesData),
      ),
      systemInfoDataProvider.overrideWith(
        () => FixedSystemInfoDataNotifierForTopology(systemInfoData),
      ),
      // Firmware with the BLE onboarding API (#879), which every 2.0.3 build has:
      // the controller node then carries its "Add nodes" menu button, and the page
      // is measured as a router shows it. The local surface is the default, so
      // the menu is offered.
      deviceCapabilitiesProvider.overrideWithValue(
          DeviceCapabilities(const {DeviceCapability.bleOnboarding})),
    ];

List<Override> nodeDetailOverrides(UspNodeDetailState state) => [
      uspNodeDetailProvider.overrideWith((ref, deviceId) => state),
      devicesDataProvider.overrideWith(
        () => FixedDevicesDataNotifierForTopology(
          DevicesData(
            meshNetwork: MeshNetwork(
              master: MasterNode(deviceId: 'GATEWAY', model: 'Test Router'),
            ),
          ),
        ),
      ),
    ];
