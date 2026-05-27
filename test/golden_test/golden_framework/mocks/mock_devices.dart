import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_provider.dart';
import 'package:privacy_gui/page/devices/providers/device_filter_state.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';

class FixedDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _fixedData;

  FixedDevicesDataNotifier(this._fixedData);

  @override
  Future<DevicesData> build() async => _fixedData;
}

class FixedDhcpDataNotifier extends DhcpDataNotifier {
  final DhcpData _fixedData;

  FixedDhcpDataNotifier(this._fixedData);

  @override
  Future<DhcpData> build() async => _fixedData;
}

List<Override> devicesListOverrides({
  required List<DeviceUIModel> devices,
  DeviceFilterConfig filter = const DeviceFilterConfig(),
  DeviceFilterOptions options = const DeviceFilterOptions(),
}) =>
    [
      devicesDataProvider.overrideWith(
        () => FixedDevicesDataNotifier(
          DevicesData(deviceModels: devices),
        ),
      ),
      filteredDeviceListProvider.overrideWith((ref) => devices),
      deviceFilterConfigProvider
          .overrideWith((ref) => FixedFilterNotifier(ref, filter)),
      deviceFilterOptionsProvider.overrideWith((ref) => options),
    ];

class FixedFilterNotifier extends DeviceFilterNotifier {
  FixedFilterNotifier(Ref ref, DeviceFilterConfig initial) : super(ref) {
    state = initial;
  }
}

List<Override> deviceDetailOverrides({
  required DeviceDetailState detail,
  List<DhcpReservationUIModel> reservations = const [],
}) =>
    [
      uspDeviceDetailProvider.overrideWith(
        (ref, mac) => detail,
      ),
      devicesDataProvider.overrideWith(
        () => FixedDevicesDataNotifier(const DevicesData()),
      ),
      dhcpDataProvider.overrideWith(
        () => FixedDhcpDataNotifier(
          DhcpData(clientModels: const [], reservationModels: reservations),
        ),
      ),
    ];
