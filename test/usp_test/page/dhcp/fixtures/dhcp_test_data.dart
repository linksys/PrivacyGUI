import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservation_list.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservations_feature_state.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservations_status.dart';

const testLanInfo = LanInfoUIModel(
  hostName: 'Linksys-Router',
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.199',
  leaseTimeMinutes: 1440,
  dnsServers: '8.8.8.8, 8.8.4.4',
);

final testClients = [
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    active: true,
    hostName: 'iPhone-15-Pro',
    leaseExpiry: DateTime.now().add(const Duration(hours: 12)),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    active: true,
    hostName: 'MacBook-Air',
    leaseExpiry: DateTime.now().add(const Duration(hours: 6, minutes: 30)),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    active: true,
    hostName: 'PlayStation-5',
    leaseExpiry: DateTime.now().add(const Duration(hours: 23, minutes: 45)),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:04',
    ip: '192.168.1.103',
    active: false,
    hostName: 'iPad-Mini',
    leaseExpiry: DateTime.now().subtract(const Duration(hours: 2)),
  ),
];

const testReservations = [
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    enable: true,
  ),
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.2.',
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    enable: true,
  ),
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.3.',
    mac: 'AA:BB:CC:DD:EE:05',
    ip: '192.168.1.150',
    enable: false,
  ),
];

DhcpReservationsFeatureState dataState({
  List<DhcpReservationUIModel> reservations = testReservations,
}) {
  final settings = DhcpReservationList(reservations: reservations);
  return DhcpReservationsFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const DhcpReservationsStatus(),
  );
}

DhcpReservationsFeatureState dirtyState() {
  final original = const DhcpReservationList(reservations: testReservations);
  final current = DhcpReservationList(
    reservations: [
      ...testReservations,
      const DhcpReservationUIModel(
        mac: 'FF:EE:DD:CC:BB:AA',
        ip: '192.168.1.160',
        enable: true,
      ),
    ],
  );
  return DhcpReservationsFeatureState(
    settings: Preservable(original: original, current: current),
    status: const DhcpReservationsStatus(),
  );
}

DhcpReservationsFeatureState emptyState() {
  const settings = DhcpReservationList();
  return const DhcpReservationsFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: DhcpReservationsStatus(),
  );
}
