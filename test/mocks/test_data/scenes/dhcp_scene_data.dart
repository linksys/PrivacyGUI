// Composed scenes, not builders — see `test/mocks/test_data/` one directory up.
//
// The two are different kinds of fixture and used to be different kinds of file
// with the same name: `wifi_settings_test_data.dart` existed here and there with
// different contents, and `devices_test_data.dart` did too. CLAUDE.md documents
// exactly one location for test data, so an author autocompleting the wrong import
// got a fixture that did not match the provider overrides it was paired with —
// which for a page- or card-family cell renders `AppLoader` instead of the page,
// the failure `PageSurfaceCase.requires` exists to catch and which reads as green
// in any suite that does not use it.
//
// The split, as the names now say it:
//
// * `test_data/<feature>_test_data.dart` — a class of static factory methods over
//   USP codegen models, parameterised with defaults (constitution Article I
//   §1.6.2). What a unit test calls to build the one object it is about.
// * `test_data/scenes/<feature>_scene_data.dart` — top-level finals holding whole
//   composed states, ready to hand to a provider override. What a golden, a
//   density test or a layout-gate cell pumps a real page with.

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
    leaseActive: true,
    isOnline: true,
    hostName: 'iPhone-15-Pro',
    leaseExpiry: DateTime.now().add(const Duration(hours: 12)),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    leaseActive: true,
    isOnline: true,
    hostName: 'MacBook-Air',
    leaseExpiry: DateTime.now().add(const Duration(hours: 6, minutes: 30)),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    leaseActive: true,
    isOnline: true,
    hostName: 'PlayStation-5',
    leaseExpiry: DateTime.now().add(const Duration(hours: 23, minutes: 45)),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:04',
    ip: '192.168.1.103',
    leaseActive: false,
    isOnline: false,
    hostName: 'iPad-Mini',
    leaseExpiry: DateTime.now().subtract(const Duration(hours: 2)),
  ),
];

final testReservations = [
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
  List<DhcpReservationUIModel>? reservations,
}) {
  final res = reservations ?? testReservations;
  final settings = DhcpReservationList(reservations: res);
  return DhcpReservationsFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const DhcpReservationsStatus(),
  );
}

DhcpReservationsFeatureState dirtyState() {
  final original = DhcpReservationList(reservations: testReservations);
  final current = DhcpReservationList(
    reservations: [
      ...testReservations,
      DhcpReservationUIModel(
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
