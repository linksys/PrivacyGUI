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

import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';

// ---------------------------------------------------------------------------
// System Info
// ---------------------------------------------------------------------------

const _testSystemInfo = SystemInfoUIModel(
  manufacturer: 'Linksys',
  modelName: 'MR7500',
  serialNumber: 'ABC123456',
  hardwareVersion: '1.0',
  softwareVersion: '1.0.16.215118',
  uptime: 86400,
  totalMemory: 524288,
  freeMemory: 262144,
  cpuUsage: 25,
);

final testSystemInfoData = SystemInfoData(model: _testSystemInfo);

// ---------------------------------------------------------------------------
// Devices
// ---------------------------------------------------------------------------

final _testClients = [
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(signalStrength: -45, band: '5GHz'),
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'MacBook Pro',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(signalStrength: -55, band: '5GHz'),
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    hostName: 'Desktop PC',
    isActive: true,
    connectionType: ConnectionType.wired,
  ),
];

final _meshMasterClients = [
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(signalStrength: -45, band: '5GHz'),
    parentNodeId: '11:22:33:44:55:66',
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'MacBook Pro',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(signalStrength: -55, band: '5GHz'),
    parentNodeId: '11:22:33:44:55:66',
  ),
];

final _meshSlaveClients = [
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    hostName: 'Desktop PC',
    isActive: true,
    connectionType: ConnectionType.wired,
    parentNodeId: 'AA:BB:CC:DD:FF:01',
  ),
];

// ---------------------------------------------------------------------------
// Topology View States
// ---------------------------------------------------------------------------

final singleNodeDevicesData = DevicesData(
  meshNetwork: MeshNetwork(
    master: MasterNode(
      deviceId: 'gateway',
      model: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'ABC123456',
      softwareVersion: '1.0.16.215118',
      connectedClients: _testClients,
    ),
  ),
);

final meshNetworkDevicesData = DevicesData(
  meshNetwork: MeshNetwork(
    master: MasterNode(
      deviceId: '11:22:33:44:55:66',
      model: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'ABC123456',
      softwareVersion: '1.0.16.215118',
      connectedClients: _meshMasterClients,
    ),
    slaves: [
      SlaveNode(
        deviceId: 'AA:BB:CC:DD:FF:01',
        model: 'MX2000',
        manufacturer: 'Linksys',
        serialNumber: 'DEF789012',
        softwareVersion: '1.0.10.200000',
        connectedClients: _meshSlaveClients,
        backhaul: BackhaulInfo(mediaType: 'Wi-Fi', signalStrength: -50),
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Node Detail States
// ---------------------------------------------------------------------------

final masterNodeWithDevices = UspNodeDetailState(
  node: MasterNode(
    deviceId: '11:22:33:44:55:66',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'ABC123456',
    softwareVersion: '1.0.16.215118',
    connectedClients: _meshMasterClients,
  ),
  connectedClients: _meshMasterClients,
);

final slaveNodeWithDevices = UspNodeDetailState(
  node: SlaveNode(
    deviceId: 'AA:BB:CC:DD:FF:01',
    model: 'MX2000',
    manufacturer: 'Linksys',
    serialNumber: 'DEF789012',
    softwareVersion: '1.0.10.200000',
    connectedClients: _meshSlaveClients,
    backhaul: BackhaulInfo(mediaType: 'Wi-Fi', signalStrength: -50),
  ),
  connectedClients: _meshSlaveClients,
);

/// Slave node whose backhaul reports both a PHY rate and a last-contact time, so
/// the card's bottom row renders (`usp_node_detail_view.dart:429`). Both fields
/// matter: with `phyRate` at 0 the last-contact tile becomes the row's only
/// child and takes the full width, which is not the half-width geometry the
/// #1302 fix was measured against.
///
/// A getter rather than a `final`, and deliberately not a fixed date. The tile
/// renders the timestamp through `DateFormatUtils.formatRelativeTime`, which
/// reads `DateTime.now()` and cannot be faked from the golden harness (nothing
/// there installs a clock). Any fixed past date therefore renders a day counter
/// that increments daily, so a golden taken from this state would diff against
/// its own baseline the next day. `Just now` (`diff.inSeconds < 60`) is the one
/// branch of that formatter that does not move, and recomputing per access keeps
/// every read inside that window however long a suite runs.
UspNodeDetailState get slaveNodeWithBackhaulTiming => UspNodeDetailState(
      node: SlaveNode(
        deviceId: 'AA:BB:CC:DD:FF:03',
        model: 'MX2000',
        manufacturer: 'Linksys',
        serialNumber: 'DEF789014',
        softwareVersion: '1.0.10.200000',
        connectedClients: _meshSlaveClients,
        backhaul: BackhaulInfo(
          mediaType: 'Wi-Fi',
          signalStrength: -50,
          phyRate: 1200,
          lastContactTime: DateTime.now().toUtc().toIso8601String(),
        ),
      ),
      connectedClients: _meshSlaveClients,
    );

final masterNodeEmptyDevices = UspNodeDetailState(
  node: MasterNode(
    deviceId: '11:22:33:44:55:66',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'ABC123456',
    softwareVersion: '1.0.16.215118',
    connectedClients: [],
  ),
  connectedClients: [],
);

// Slave node with a global (routable) LAN IPv6 — shown without a scope badge.
final slaveNodeGlobalIpv6 = UspNodeDetailState(
  node: SlaveNode(
    deviceId: 'AA:BB:CC:DD:FF:02',
    model: 'MX2000',
    manufacturer: 'Linksys',
    serialNumber: 'DEF789013',
    softwareVersion: '1.0.10.200000',
    ipv6Addresses: const ['2401:e180:8801:d79d::5'],
    connectedClients: _meshSlaveClients,
    backhaul: BackhaulInfo(mediaType: 'Wi-Fi', signalStrength: -50),
  ),
  connectedClients: _meshSlaveClients,
);

// Slave node whose only LAN IPv6 is link-local (fe80::/10) — shown with a
// scope badge in place of the leading icon.
final slaveNodeLinkLocalIpv6 = UspNodeDetailState(
  node: SlaveNode(
    deviceId: 'AA:BB:CC:DD:FF:03',
    model: 'MX2000',
    manufacturer: 'Linksys',
    serialNumber: 'DEF789014',
    softwareVersion: '1.0.10.200000',
    ipv6Addresses: const ['fe80::7612:13ff:fe21:5503'],
    connectedClients: _meshSlaveClients,
    backhaul: BackhaulInfo(mediaType: 'Wi-Fi', signalStrength: -50),
  ),
  connectedClients: _meshSlaveClients,
);

const nodeNotFoundState = UspNodeDetailState();
