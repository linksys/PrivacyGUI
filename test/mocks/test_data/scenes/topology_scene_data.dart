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

/// A **healthy** two-level mesh: gateway, one extender, clients on both. The
/// widest tree the golden suite draws, which is why the layout gate picks this
/// state over [singleNodeDevicesData] (`kTopologyPageCase`,
/// `test/layout_gate/families/page_surface_cases.dart`). Neither consumer is
/// about liveness — both want the tree at its full width and depth.
///
/// `dataElementsId` is what says "healthy" out loud, and it has to be said here
/// because a slave's liveness is now data: `isOnline => !livenessKnown ||
/// dataElementsId != null` (#1430). Before that the renderer hardcoded
/// `status: MeshNodeStatus.online` for every node, so the green dot on this
/// extender was a constant and this fixture could not have expressed liveness
/// even deliberately. It now has to.
///
/// Deliberately not the `deviceId`: a node answers on three MACs and
/// DataElements keys the backhaul one, so the two ids differing is the normal
/// live shape (`NodeEntity.dataElementsId`, #1440).
///
/// Dropping the field again reads as a **powered-off** extender: no status dot,
/// a desaturated image, a dashed grey backhaul, and — because
/// `_nodeComparator` sorts offline last (`usp_topology_view.dart`, since #882) —
/// the extender falls below the gateway's clients, which is a different tree
/// from the one this scene exists to draw. Only one width notices: measured
/// against the pre-#1430 render, that omission moves 4.2% of the pixels at
/// `phone480` but 1.4% at `screen1080` and 0.9% at `desktop1280`, both under the
/// suite's `diffThreshold: 0.025` (#1472) — the footprint is laid out at a fixed
/// size while the allowance grows with canvas area, which is #1475. So the guard
/// for this is not a golden: `topology_scene_reachability_test.dart` asserts
/// every node here reads online and fails on exactly this omission. #1466 fixes
/// the same "liveness dropped by construction" shape one layer down, at the two
/// builder sites.
///
/// And that tree is not merely a different one — it is one the builder cannot
/// produce, so omitting the field puts this scene outside the states the page can
/// ever be in. Measured on the M60TB-EU bench (FW `1.2.3.26072920`, two wireless
/// slaves): `_findMatchingMeshNode` matches the last 12 hex of the Hosts
/// `DeviceID` UUID against the DataElements node id, and that single result feeds
/// both `dataElementsId` *and* the only key that can attach clients —
/// `clientToNodeMap` is keyed by the DataElements id (`mesh_topology_builder.dart`),
/// while `Hosts.PhysAddress` is the node's Radio.1 BSSID, one above the AL-MAC
/// (`80:69:1A:BB:46:95` vs `…:94`), so the `PhysAddress` lookup in
/// `MeshNetworkBuilder` never hits on real hardware. No match therefore means
/// offline **and** childless. An offline extender with a live wired client
/// hanging off it, on a solid green link, is reachable from a fixture and nowhere
/// else.
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
        dataElementsId: 'AA:BB:CC:DD:FF:11',
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

/// A slave carrying **no** DataElements match, which since #1430 makes it
/// `isOnline` false — see [slaveNodeOnlineWithDevices] for the same node with the
/// match, and `SlaveNode.isOnline` for why one field decides it.
///
/// Left offline rather than "fixed" to online, for two reasons. It is a real
/// reachable state, not fixture rot: the powered-off extender #1430 exists to
/// catch looks exactly like this. And every width sweep that pumps this state —
/// the golden suite's `slave_with_devices`, `usp_node_detail_backhaul_overflow_test`
/// — renders the *wider* of the two liveness labels: `offline` is longer than
/// `online` in every one of the 26 locales where the two differ, and equal in the
/// rest (measured across `lib/l10n/app_*.arb`, #1465). An online fixture would
/// quietly narrow all of them.
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

/// [slaveNodeWithDevices] plus the single field that decides a slave's liveness —
/// a DataElements match (`SlaveNode.isOnline`). Nothing else differs, so the two
/// are a pair: same role, opposite liveness.
///
/// The pair is what makes the node-detail header's two facts *independently*
/// testable (#1465). A header that derived liveness from the role instead —
/// `isMaster ? online : offline`, which is the shape the old hardcoded
/// `isActive: true` badge invited — passes any suite that only ever pumps an
/// online master and an offline slave. This is the slave that is online.
///
/// `dataElementsId` is deliberately not the `deviceId`: a node answers on three
/// MACs and DataElements keys on the backhaul one, so the two ids differing is the
/// normal live shape rather than an edge case (`NodeEntity.dataElementsId`).
final slaveNodeOnlineWithDevices = UspNodeDetailState(
  node: SlaveNode(
    deviceId: 'AA:BB:CC:DD:FF:01',
    dataElementsId: 'AA:BB:CC:DD:FF:11',
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

/// Slave node with **no backhaul at all** — `BackhaulInfo.hasInfo` is false, so
/// it is neither Wi-Fi nor Ethernet.
///
/// The fixture for `_buildBackhaulCard`'s third arm
/// (`usp_node_detail_view.dart:403`). Every other block in that card is gated on
/// data this state does not have — no parent node, no rates, `phyRate` 0, no
/// `lastContactTime` — so before the arm existed the card rendered as a bare
/// header. `parentNode` is left unset on purpose: the connected-to row comes from
/// the topology, which is the thing that is missing here.
///
/// `livenessKnown: false` is what makes the state reachable rather than
/// hypothetical: it is the DataElements-unavailable node that #1430's review kept
/// online (see `SlaveNode.livenessKnown`), so the page is navigable in exactly
/// the state that carries no backhaul.
final slaveNodeNoBackhaul = UspNodeDetailState(
  node: SlaveNode(
    deviceId: 'AA:BB:CC:DD:FF:04',
    model: 'MX2000',
    manufacturer: 'Linksys',
    serialNumber: 'DEF789015',
    softwareVersion: '1.0.10.200000',
    connectedClients: _meshSlaveClients,
    backhaul: const BackhaulInfo(mediaType: ''),
    livenessKnown: false,
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
