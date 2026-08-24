import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservation_list.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservations_feature_state.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservations_status.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

class FixedDhcpReservationsNotifier extends UspDhcpReservationsNotifier {
  final DhcpReservationsFeatureState _fixedState;

  FixedDhcpReservationsNotifier(this._fixedState);

  @override
  DhcpReservationsFeatureState build() => _fixedState;

  @override
  Future<(DhcpReservationList?, DhcpReservationsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void addReservation(reservation) {}

  @override
  void editReservation(oldReservation, updated) {}

  @override
  void toggleReservation(reservation, enable) {}

  @override
  void deleteReservation(reservation) {}
}

class FixedLanDataNotifier extends LanDataNotifier {
  final LanData _fixedData;

  FixedLanDataNotifier(this._fixedData);

  @override
  Future<LanData> build() async => _fixedData;
}

class FixedDhcpDataNotifier extends DhcpDataNotifier {
  final DhcpData _fixedData;

  FixedDhcpDataNotifier(this._fixedData);

  @override
  Future<DhcpData> build() async => _fixedData;
}

class FixedDevicesDataNotifier extends DevicesDataNotifier {
  @override
  Future<DevicesData> build() async => DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'Test Router'),
        ),
      );
}

List<Override> dhcpDetailOverrides({
  required DhcpReservationsFeatureState reservationState,
  LanInfoUIModel? lanInfo,
  List<DhcpClientUIModel> clients = const [],
}) =>
    [
      uspDhcpReservationsProvider.overrideWith(
        () => FixedDhcpReservationsNotifier(reservationState),
      ),
      lanDataProvider.overrideWith(
        () => FixedLanDataNotifier(
          lanInfo != null ? LanData(model: lanInfo) : const LanData.empty(),
        ),
      ),
      dhcpDataProvider.overrideWith(
        () => FixedDhcpDataNotifier(
          DhcpData(clientModels: clients, reservationModels: const []),
        ),
      ),
      devicesDataProvider.overrideWith(() => FixedDevicesDataNotifier()),
    ];
