import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    ];

List<Override> nodeDetailOverrides(UspNodeDetailState state) => [
      uspNodeDetailProvider.overrideWith((ref, deviceId) => state),
      devicesDataProvider.overrideWith(
        () => FixedDevicesDataNotifierForTopology(const DevicesData()),
      ),
    ];
