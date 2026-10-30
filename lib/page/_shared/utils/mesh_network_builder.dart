import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_node_identity.dart';

/// Builds [MeshNetwork] from raw data sources.
///
/// Transforms Hosts (ConnectedDevices), WiFi enrichment, and DataElements
/// into the unified MeshNetwork architecture.
///
/// **DataElements decides which nodes exist; Hosts only describes them
/// (#1688).** The node list, each node's role and its parent come from
/// [MeshTopologyInfo.nodes] (`MeshTopologyBuilder`, which tells the controller
/// from an agent by its backhaul). A `Hosts` row is attached to a node when its
/// `PhysAddress` equals that node's `Device.{i}.ID` (linksys/FWDEV#208) and
/// supplies what DataElements does not carry — the node's IP and host name —
/// and such a row is not also listed as a client. FL-WRT 2.0 has no mesh-role
/// leaf on `Hosts` (see `mesh_node_identity.dart`), so there is no other way to
/// tell a node's row from a client's.
///
/// **A node DataElements does not report is not built.** On 2.0 an agent that
/// drops off the mesh leaves `DataElements.Network.Device.` and nothing marks
/// its lingering `Hosts` row as a node, so it disappears rather than rendering
/// offline. Showing it offline needs the app to remember which MACs were nodes;
/// that is deliberately not built yet, because how long such a row lingers on
/// 2.0 has not been measured on a multi-node bench (#1688, #1443).
class MeshNetworkBuilder {
  MeshNetworkBuilder._();

  /// Builds a [MeshNetwork] from the various data sources.
  ///
  /// Data sources:
  /// - [connectedDevices]: Hosts.Host table (all devices + mesh nodes)
  /// - [wifiClientMap]: WiFi STA enrichment (signal, rate for master clients)
  /// - [connectionDetailMap]: band/SSID info
  /// - [meshTopology]: DataElements (clientToNodeMap, clientSignalMap, nodes)
  /// - [gatewayName]: Fallback name for master node
  /// - [systemInfo]: Gateway device info (model, firmware, etc.)
  static MeshNetwork build({
    required ConnectedDevices connectedDevices,
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required String gatewayName,
    SystemInfoUIModel? systemInfo,
  }) {
    // 1. Separate the nodes' own Hosts rows from the clients. A row is a node's
    //    when its PhysAddress is a DataElements node ID; it is keyed by that
    //    normalized MAC so each node can find its row below.
    final nodeMacSet =
        meshNodeMacSet(meshTopology.nodes.map((n) => n.deviceId));
    final nodeHostRows = <String, ConnectedDevice>{};
    final clientHostDevices = <ConnectedDevice>[];

    for (final d in connectedDevices.items) {
      if (isMeshNodeHost(d.macAddress, nodeMacSet)) {
        nodeHostRows[meshNodeMacKey(d.macAddress)] ??= d;
      } else if (d.interface_.isNotEmpty || d.isActive) {
        clientHostDevices.add(d);
      }
    }

    // 2. Build node display name map (DataElements node ID → Hosts name)
    final nodeDisplayNameMap =
        _buildNodeDisplayNameMap(meshTopology, nodeHostRows);

    // 3. Build all ClientDevice models
    //
    // "Mesh" means the topology actually has an extender, not merely that
    // DataElements answered. A standalone router that supports DataElements
    // still reports a single (master) node, so `nodes.isNotEmpty` would be true
    // even though there is no other node a client could belong to — and then
    // every unresolved client would be called an orphan on a one-node network.
    // Use the topology's own `hasMesh` (any SlaveNode present), which matches
    // MeshNetwork.hasMesh.
    final topologyHasMesh = meshTopology.nodes.hasMesh;

    final allBuiltClients = clientHostDevices
        .map((d) => _buildClientDevice(
              device: d,
              wifiClientMap: wifiClientMap,
              connectionDetailMap: connectionDetailMap,
              meshTopology: meshTopology,
              topologyHasMesh: topologyHasMesh,
              gatewayName: gatewayName,
              nodeDisplayNameMap: nodeDisplayNameMap,
            ))
        .toList();

    // 4. Merge each multi-interface device's rows into one client
    final groupedClients = _groupByDetectedName(allBuiltClients);

    // 5. Group clients by parentNodeId
    final clientsByNodeId = <String?, List<ClientDevice>>{};
    for (final client in groupedClients) {
      final nodeId = client.parentNodeId;
      (clientsByNodeId[nodeId] ??= []).add(client);
    }

    // 6. Build MasterNode. Its identity is the DataElements controller; its
    //    Hosts row, if any, is looked up by MAC. On 2.0.3.26101482 the
    //    controller has no Hosts row of its own (none of the five rows carries
    //    a 74:12:13:21:56:xx address), so `masterDevice` is normally null and
    //    the name and model come from system_info.
    final masterMeshInfo = meshTopology.nodes.master;
    final masterDevice = masterMeshInfo == null
        ? null
        : nodeHostRows[meshNodeMacKey(masterMeshInfo.deviceId)];
    final masterNodeId = masterDevice?.macAddress.trim().toUpperCase() ??
        masterMeshInfo?.deviceId ??
        'GATEWAY';

    // Clients for master: those with a matching master ID, plus those with no
    // parent ID that are not orphans.
    //
    // A null parentNodeId means different things by client and network shape,
    // and _buildClientDevice has already made that call — it is the only place
    // where the client's own interface and liveness are in scope. A client it
    // flagged isUnattributed is an *orphan*: it belongs to the network but to no
    // known node, and asserting it onto the master would be a wrong attribution,
    // not a missing one (issue #1439). It goes to the unassigned bucket below.
    // Every other null-parent client legitimately hangs off the gateway — a
    // wired device, an offline device, or any client on a network with no
    // extender — and stays on the master, as before.
    final masterClients = <ClientDevice>[];
    final nullParentClients = clientsByNodeId[null] ?? [];
    masterClients.addAll(nullParentClients.where((c) => !c.isUnattributed));
    if (clientsByNodeId.containsKey(masterNodeId)) {
      masterClients.addAll(clientsByNodeId[masterNodeId]!);
    }
    // Also match by DataElements master ID
    if (masterMeshInfo != null &&
        masterMeshInfo.deviceId != masterNodeId &&
        clientsByNodeId.containsKey(masterMeshInfo.deviceId)) {
      masterClients.addAll(clientsByNodeId[masterMeshInfo.deviceId]!);
    }

    final master = _buildMasterNode(
      masterDevice: masterDevice,
      masterMeshInfo: masterMeshInfo,
      systemInfo: systemInfo,
      gatewayName: gatewayName,
      connectedClients: masterClients,
    );

    // Compute master displayName for patching clients
    final masterDisplayName = master.displayName;

    // Patch master's connected clients with parentNodeName
    final patchedMasterClients = masterClients
        .map((c) => c.copyWith(parentNodeName: masterDisplayName))
        .toList();
    final patchedMaster =
        master.copyWith(connectedClients: patchedMasterClients);

    // 7. Build SlaveNodes — one per DataElements agent, each with the Hosts row
    //    whose PhysAddress is its ID (null when none matches).
    final slaves = meshTopology.nodes.slaves.map((slaveMeshInfo) {
      final slaveDevice = nodeHostRows[meshNodeMacKey(slaveMeshInfo.deviceId)];
      final slaveNodeId = slaveMeshInfo.deviceId;

      final slaveClients = clientsByNodeId[slaveNodeId] ?? <ClientDevice>[];

      final slave = _buildSlaveNode(
        slaveDevice: slaveDevice,
        slaveMeshInfo: slaveMeshInfo,
        connectedClients: slaveClients,
        // Every slave built here is one DataElements reported, so it is online
        // and its liveness is known by construction. Before #1688 the slaves
        // came from Hosts rows tagged `DeviceRole=slave`, and a powered-off
        // extender showed as an *offline* row: its Hosts row lingered while it
        // had left DataElements (#1430). On 2.0 nothing tags that lingering row
        // as a node, so the offline shape cannot be built from this input — see
        // the class doc. `livenessKnown` stays a parameter so that rebuilding an
        // offline node later does not change the model.
        livenessKnown: true,
      );

      // Patch slave's connected clients with parentNodeName
      final slaveDisplayName = slave.displayName;
      final patchedSlaveClients = slaveClients
          .map((c) => c.copyWith(parentNodeName: slaveDisplayName))
          .toList();
      return slave.copyWith(connectedClients: patchedSlaveClients);
    }).toList();

    // 8. Collect the unassigned (orphan) clients — those whose parent cannot be
    // resolved to a known node. Two shapes, both flagged isUnattributed so the
    // UI can mark them explicitly instead of drawing them as master clients
    // (issue #1439).
    final assignedNodeIds = <String>{
      masterNodeId,
      if (masterMeshInfo != null) masterMeshInfo.deviceId,
      ...slaves.map((s) => s.deviceId),
      ...slaves.map((s) => s.dataElementsId).whereType<String>(),
    };
    final unassigned = <ClientDevice>[];
    for (final e in clientsByNodeId.entries) {
      if (e.key == null) {
        // Shape A — no parent ID at all. _buildClientDevice already decided
        // which of these are orphans, because only it can see whether the
        // client is an online Wi-Fi device (a missing station row is then real
        // evidence) or a wired/offline one (never in the station map, so a null
        // parent ID is no evidence at all). The rest stayed on the master above.
        unassigned.addAll(e.value.where((c) => c.isUnattributed));
      } else if (!assignedNodeIds.contains(e.key)) {
        // Shape B — a parent ID matching no node that was built. Since #1688
        // every DataElements node is built, and `clientToNodeMap` is written
        // from the same node loop, so this needs the two to disagree; it stays
        // as the guard for that case rather than as an expected path. Setting
        // the flag also clears parentNodeName, which the resolver had already
        // filled in from the unmatched node's model (or the gateway name):
        // keeping that would leave the device claiming a parent while being
        // declared unattributed.
        unassigned.addAll(e.value.map((c) => c.copyWith(isUnattributed: true)));
      }
    }

    return MeshNetwork(
      master: patchedMaster,
      slaves: slaves,
      unassignedClients: unassigned,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: Node display name map
  // ---------------------------------------------------------------------------

  /// DataElements node ID → the name its Hosts row carries, for labelling a
  /// client's "connected to".
  ///
  /// Keyed by the DataElements ID because that is what `clientToNodeMap` maps a
  /// client to. The name is the row's `X_LINKSYS_FriendlyName` (the 2.0 leaf,
  /// as for clients since #1693), else its host name; a node with neither, or
  /// with no Hosts row, is left out so the caller falls back to the model.
  static Map<String, String> _buildNodeDisplayNameMap(
    MeshTopologyInfo meshTopology,
    Map<String, ConnectedDevice> nodeHostRows,
  ) {
    final map = <String, String>{};
    for (final node in meshTopology.nodes) {
      final row = nodeHostRows[meshNodeMacKey(node.deviceId)];
      if (row == null) continue;
      final displayName =
          nonEmpty(row.linksysFriendlyName) ?? nonEmpty(row.hostName);
      if (displayName != null) map[node.deviceId] = displayName;
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // Private: ClientDevice builder
  // ---------------------------------------------------------------------------

  static ClientDevice _buildClientDevice({
    required ConnectedDevice device,
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required bool topologyHasMesh,
    required String gatewayName,
    required Map<String, String> nodeDisplayNameMap,
  }) {
    final mac = device.macAddress.trim().toUpperCase();

    // Determine WiFi via Layer1Interface or InterfaceType
    final interfaceType = device.interfaceType?.toLowerCase() ?? '';
    final isWifi = device.interface_.toLowerCase().contains('wifi') ||
        interfaceType.contains('wi-fi') ||
        interfaceType.contains('wifi');

    final wifiClient = wifiClientMap[mac];
    final detail = connectionDetailMap[mac];

    // Resolve parent node.
    //
    // A client with no entry in clientToNodeMap is an orphan only if its absence
    // is evidence of anything. The map has a single write site, inside the
    // DataElements Wi-Fi station loop, so it holds *associated Wi-Fi stations
    // and nothing else*: a wired client and an offline client are missing from
    // it by construction, whatever node they are really on. Requiring an online
    // Wi-Fi client is what keeps this the orphan population issue #1439
    // describes, rather than "every wired device in the house" — the reason the
    // decision lives here and not in build(), which cannot see either property.
    bool isUnattributed = false;
    String? parentNodeId;
    String? parentNodeName;
    if (meshTopology.isEmpty) {
      // Non-mesh: all active devices are on the gateway
      if (device.isActive) parentNodeName = gatewayName;
    } else {
      // A Wi-Fi station entry first, then the wired neighbor table (#1688 item
      // 2). The station entry wins for a MAC in both: a Wi-Fi STA is a
      // bridge-FDB entry too (MeshTopologyBuilder.wiredClientAttribution).
      parentNodeId = meshTopology.clientToNodeMap[mac] ??
          meshTopology.wiredClientToNodeMap[mac];
      if (parentNodeId == null) {
        // An online wired client that two or more nodes list is evidence of a
        // node the app cannot pick, so it is unattributed (FWDEV#208 rule 2).
        // A wired client that no node lists is still no evidence, and stays on
        // the master as above. Liveness comes from Hosts, not from the
        // listing: the forwarding table keeps an unplugged client ~300 s.
        final ambiguousWired = !isWifi &&
            device.isActive &&
            meshTopology.ambiguousWiredClients.contains(mac);
        isUnattributed =
            (topologyHasMesh && isWifi && device.isActive) || ambiguousWired;
      } else {
        // Try display name map first (friendlyName or hostName from Hosts)
        parentNodeName = nodeDisplayNameMap[parentNodeId];
        if (parentNodeName == null) {
          // Fallback: use model name from DataElements
          final matchingNode = meshTopology.nodes
              .where((n) => n.deviceId == parentNodeId)
              .firstOrNull;
          parentNodeName = matchingNode?.model.isNotEmpty == true
              ? matchingNode!.model
              : gatewayName;
        }
      }
    }

    // Build WiFi info if applicable
    WifiConnectionInfo? wifi;
    if (isWifi) {
      // `Hosts.Host.{i}.SignalStrength` uses `0` to mean "no reading" (the key
      // is present with value 0 rather than being omitted), so the generated
      // parser yields `0`, not `null`. A non-null `0` would short-circuit the
      // `??` chain and hide the `WifiClient` / DataElements readings that may
      // carry a real value for this MAC. Treat a Hosts `0` as absent so the
      // chain can fall through. See linksys/PrivacyGUI#1438.
      final hostsSignal =
          (device.signalStrength == 0) ? null : device.signalStrength;
      // An MLO client takes its signal and rates from its links only
      // (#1686 item 2). Its own BSS.STA row names one band but carries the
      // active link's values, so while a link carries values the row adds
      // nothing; while none does (the first ~50 s after association) what
      // the row reads is unmeasured, and a value of unknown origin next to
      // "MLO (bands)" would read as the MLO link's. So no link with values
      // leaves them empty rather than falling back (decided 2026-10-21).
      final mlo = meshTopology.mloClients?[mac];
      final signalStrength = mlo != null
          ? mlo.signalStrength
          : hostsSignal ??
              wifiClient?.signalStrength ??
              meshTopology.clientSignalMap[mac];
      // Fallback to DataElements band/SSID for slave node clients.
      // ClientConnectionDetail.band/ssidName are non-nullable Strings that are
      // '' when AP→SSID→radio resolution fails, so treat empty as absent —
      // otherwise the empty string would mask the DataElements fallback value.
      final bandSsid = meshTopology.clientBandSsidMap[mac];
      // DataElements last, as for signal and band: Hosts (1.x only) and the
      // controller's own AssociatedDevice describe a controller client, and
      // only DataElements BSS.STA describes a client on an agent (#1686).
      final rates = meshTopology.clientRateMap[mac];
      // Each source's 0 is "no reading", as for the Hosts signal above:
      // WifiClientUIModel defaults an absent rate to 0, and a 0 there would
      // otherwise hide the DataElements rate. The controller's AssociatedDevice
      // row counts only while it is active: a row left behind after the client
      // roamed to an agent carries the old link's rate.
      final associated = (wifiClient?.active ?? false) ? wifiClient : null;
      wifi = WifiConnectionInfo(
        signalStrength: signalStrength,
        band: _nonEmptyRaw(detail?.band) ?? _nonEmptyRaw(bandSsid?.band),
        ssidName: _nonEmptyRaw(detail?.ssidName) ?? bandSsid?.ssid,
        downlinkRate: mlo != null
            ? mlo.downlinkRate
            : _rate(device.lastDataDownlinkRate) ??
                _rate(associated?.lastDataDownlinkRate) ??
                rates?.downlink,
        uplinkRate: mlo != null
            ? mlo.uplinkRate
            : _rate(device.lastDataUplinkRate) ??
                _rate(associated?.lastDataUplinkRate) ??
                rates?.uplink,
        mloBands: mlo?.bands,
        // Only a mesh read can say whether MLO is known. A topology that is
        // empty (not loaded yet, or not a mesh) has nothing to be unknown
        // about, and mloClients is null there too. An offline client is on
        // no link at all, so whether it would be on MLO is no question.
        mloUnknown: device.isActive &&
            meshTopology.isNotEmpty &&
            meshTopology.mloClients == null,
      );
    }

    // Identity comes from devidentd's X_LINKSYS_ leaves (FWDEV#207). A leaf it
    // has not identified reads "", never absent, so `nonEmpty` turns that into
    // the null every consumer falls back on. The unprefixed 1.0 leaves are
    // absent on FL-WRT 2.0 and take no part in the order (#1693).
    return ClientDevice(
      mac: mac,
      ip: device.ipAddress,
      hostName: device.hostName,
      friendlyName: nonEmpty(device.linksysFriendlyName),
      detectedName: nonEmpty(device.linksysDetectedName),
      isActive: device.isActive,
      ipv6Addresses: device.ipv6Addresses
          .map((e) => e.address)
          .where((a) => a.isNotEmpty)
          .toList(),
      layer1Interface: device.interface_,
      connectionType: isWifi ? ConnectionType.wifi : ConnectionType.wired,
      wifi: wifi,
      parentNodeId: parentNodeId,
      parentNodeName: parentNodeName,
      isUnattributed: isUnattributed,
      manufacturer: nonEmpty(device.linksysManufacturer),
      modelName: nonEmpty(device.linksysModelName),
      operatingSystem: nonEmpty(device.linksysOperatingSystem),
      deviceType: nonEmpty(device.linksysDeviceType),
      userDeviceType: nonEmpty(device.linksysUserDeviceType),
      userDeviceName: nonEmpty(device.linksysUserDeviceLocation),
      hostsDeviceId: device.deviceId,
      hostInstancePath: device.instancePath,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: Multi-interface grouping
  // ---------------------------------------------------------------------------

  /// Returns [s] if it is non-null and non-empty **without trimming**, otherwise
  /// null.
  ///
  /// The SSID chain only. An SSID may legitimately begin or end with a space, so
  /// trimming would both alter what is displayed and let a real single-space SSID
  /// fall through to another source. Every other chain in this file uses the
  /// shared [nonEmpty], which trims — see its doc for why that is what a `??`
  /// chain wants: an untrimmed `' '` is non-empty and therefore *wins* the
  /// chain, which is the opposite of the fallback this helper was written for.
  static String? _nonEmptyRaw(String? s) =>
      (s != null && s.isNotEmpty) ? s : null;

  /// A rate reading in kbps, or null when it is absent or `0` (not filled).
  static int? _rate(int? kbps) => (kbps != null && kbps > 0) ? kbps : null;

  static String _normalizeGroupingName(String name) {
    var normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    final mdnsSuffixIndex = normalized.indexOf('._');
    if (mdnsSuffixIndex > 0) {
      normalized = normalized.substring(0, mdnsSuffixIndex);
    }
    return normalized;
  }

  /// Merges the Hosts rows of one device, keyed by the name devidentd
  /// detected for them (#1719).
  ///
  /// FL-WRT 2.0 serves one row per MAC and no leaf links a device's rows, so
  /// a name is the only key. `HostName` is not it: a Mac on a randomized MAC
  /// sends only "Mac" in DHCP, while devidentd names both of its rows from
  /// mDNS. `X_LINKSYS_FriendlyName` is not it either: it puts the user's
  /// name first, which is kept per MAC. `X_LINKSYS_DetectedName` never holds
  /// the user's name (FWDEV#224); until it is known, the row groups by
  /// `HostName`. Rows are regrouped on every build, so a name devidentd
  /// improves later regroups them; nothing stores the key.
  static List<ClientDevice> _groupByDetectedName(List<ClientDevice> clients) {
    final grouped = <String, List<ClientDevice>>{};
    final ungrouped = <ClientDevice>[];

    for (final client in clients) {
      final name =
          _normalizeGroupingName(client.detectedName ?? client.hostName);
      if (name.isEmpty) {
        ungrouped.add(client);
      } else {
        grouped.putIfAbsent(name, () => []).add(client);
      }
    }

    final result = <ClientDevice>[];
    for (final devices in grouped.values) {
      if (devices.length == 1) {
        result.add(devices.first);
      } else {
        result.add(_mergeClients(devices));
      }
    }
    result.addAll(ungrouped);
    return result;
  }

  static ClientDevice _mergeClients(List<ClientDevice> devices) {
    final sorted = List<ClientDevice>.from(devices)
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        if (a.isWifi != b.isWifi) return a.isWifi ? -1 : 1;
        return 0;
      });

    final primary = sorted.first;
    final additional = sorted
        .skip(1)
        .map((d) => ClientInterfaceInfo(
              mac: d.mac,
              ip: d.ip,
              connectionType: d.connectionType,
              isActive: d.isActive,
              layer1Interface: d.layer1Interface,
              wifi: d.wifi,
              hostInstancePath: d.hostInstancePath,
            ))
        .toList();

    logger.d('[MeshNetworkBuilder]: Merged ${devices.length} interfaces for '
        '"${primary.displayName}" — primary=${primary.mac}');

    // The name and icon the user gave are kept per MAC, so they may sit on a
    // row that is not the primary: a laptop named on its cable, now on Wi-Fi.
    // Take them from the first row that has either, so the name does not
    // vanish when the primary changes (#1691). An edit writes every row
    // (#1719), so it needs no row of its own.
    final named = sorted.firstWhere(
      (d) => d.userDeviceName != null || d.userDeviceType != null,
      orElse: () => primary,
    );

    return primary.copyWith(
      additionalInterfaces: additional,
      friendlyName: named.friendlyName,
      userDeviceName: named.userDeviceName,
      userDeviceType: named.userDeviceType,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: MasterNode builder
  // ---------------------------------------------------------------------------

  static MasterNode _buildMasterNode({
    required ConnectedDevice? masterDevice,
    required MasterNode? masterMeshInfo,
    required SystemInfoUIModel? systemInfo,
    required String gatewayName,
    required List<ClientDevice> connectedClients,
  }) {
    final deviceId = masterDevice?.macAddress.trim().toUpperCase() ??
        masterMeshInfo?.deviceId ??
        'GATEWAY';

    // The router names itself on DeviceInfo, not on a Hosts row (#1691). The
    // location the user gave comes first, then FriendlyName, which the app does
    // not write: unlike a client's, the firmware does not fill it from the
    // location (measured on 2.0.3.26101472). Neither set, `displayName` falls
    // to the host name, then the model.
    //
    // The host name is DeviceInfo's (#1751): the controller has no Hosts row of
    // its own (measured on 2.0.4.26102918), so `masterDevice` is normally null
    // and, before, the name fell straight to the model. An agent with no user
    // name shows its host name, so the controller now does too; the model is
    // the same on every unit of it and does not tell two apart.
    final userDeviceLocation = nonEmpty(systemInfo?.userDeviceLocation);

    return MasterNode(
      deviceId: deviceId,
      dataElementsId: masterMeshInfo?.deviceId,
      friendlyName: userDeviceLocation ??
          nonEmpty(systemInfo?.friendlyName) ??
          masterDevice?.friendlyName,
      userDeviceLocation: userDeviceLocation,
      hostName: nonEmpty(masterDevice?.hostName) ??
          nonEmpty(systemInfo?.hostName) ??
          gatewayName,
      // `system_info` first, DataElements second — and the order is the fix,
      // not a preference. The controller row's identity fields are prplMesh
      // describing *itself*, not the product: measured on the bench they read
      // `Manufacturer=qcom`, `ManufacturerModel=Qualcomm Technologies, Inc. IP`,
      // `SerialNumber=prplmesh12345`, `SoftwareVersion=2026.6.4` (the prplMesh
      // version, not the firmware build). With DataElements first, node detail
      // showed all four of those to the user. `system_info` is the router
      // talking about itself over the same session, so it always wins here.
      //
      // Latent until #1555: `DataElementsNetwork.fetch()` threw on this
      // firmware, so `masterMeshInfo` was always null and the fallback was all
      // anyone ever saw. Regenerating the definition is what would have made
      // this visible — which is why it is fixed in the same change.
      model: nonEmpty(systemInfo?.modelName) ??
          nonEmpty(masterMeshInfo?.model) ??
          '',
      manufacturer: nonEmpty(systemInfo?.manufacturer) ??
          nonEmpty(masterMeshInfo?.manufacturer) ??
          '',
      serialNumber: nonEmpty(systemInfo?.serialNumber) ??
          nonEmpty(masterMeshInfo?.serialNumber) ??
          '',
      softwareVersion: nonEmpty(systemInfo?.softwareVersion) ??
          nonEmpty(masterMeshInfo?.softwareVersion) ??
          '',
      ipAddress: masterDevice?.ipAddress,
      ipv6Addresses: masterDevice?.ipv6Addresses
              .map((e) => e.address)
              .where((a) => a.isNotEmpty)
              .toList() ??
          [],
      instancePath: masterMeshInfo?.instancePath,
      connectedClients: connectedClients,
      hostsDeviceId: masterDevice?.deviceId,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: SlaveNode builder
  // ---------------------------------------------------------------------------

  /// One agent, from its DataElements record and — when one matched — the
  /// `Hosts` row whose `PhysAddress` is its ID.
  ///
  /// [slaveDevice] is null when no row matched. FWDEV#208 measured every agent
  /// with a matching row on a three-node bench. Ours, on 2.0.4.26102918 with one
  /// agent (2026-10-30, #1751), has exactly one: the agent's base MAC, equal to
  /// its DataElements ID, on a Wi-Fi backhaul and on an Ethernet one. Its
  /// backhaul STA is associated to the controller but has no row
  /// (linksys/feed_usp#49 took bSTA MACs out of Hosts), and switching the
  /// backhaul changes `Backhaul.MACAddress`, not the ID this matches on. A
  /// missing row must still build a node all the same: it just has no IP, no
  /// host name, and no rename target.
  ///
  /// [SlaveNode.deviceId] is the DataElements ID whether or not a row matched,
  /// so a node keeps one identity when its row comes and goes. Before #1688 it
  /// was the Hosts MAC; the two are the same value whenever a row matches.
  static SlaveNode _buildSlaveNode({
    required ConnectedDevice? slaveDevice,
    required SlaveNode slaveMeshInfo,
    required List<ClientDevice> connectedClients,
    required bool livenessKnown,
  }) {
    return SlaveNode(
      deviceId: slaveMeshInfo.deviceId,
      dataElementsId: slaveMeshInfo.deviceId,
      friendlyName: nonEmpty(slaveDevice?.linksysFriendlyName),
      hostName: nonEmpty(slaveDevice?.hostName),
      // DataElements first here, unlike the master: for a slave these fields are
      // prplMesh reporting the *agent*, and there is no `system_info` for a
      // remote node to check them against. `nonEmpty` rather than a bare `??`
      // because `MeshTopologyBuilder` reports an absent field as `''`, which
      // `??` would accept as an answer — and because it trims, so a
      // whitespace-only field cannot win the chain either (#1555). The Hosts
      // fallbacks are the 2.0 `X_LINKSYS_` leaves, as for clients (#1693).
      model: nonEmpty(slaveMeshInfo.model) ??
          nonEmpty(slaveDevice?.linksysModelName) ??
          '',
      manufacturer: nonEmpty(slaveMeshInfo.manufacturer) ??
          nonEmpty(slaveDevice?.linksysManufacturer) ??
          '',
      serialNumber: nonEmpty(slaveMeshInfo.serialNumber) ?? '',
      softwareVersion: nonEmpty(slaveMeshInfo.softwareVersion) ?? '',
      ipAddress: nonEmpty(slaveDevice?.ipAddress),
      ipv6Addresses: slaveDevice?.ipv6Addresses
              .map((e) => e.address)
              .where((a) => a.isNotEmpty)
              .toList() ??
          const [],
      instancePath: slaveMeshInfo.instancePath,
      connectedClients: connectedClients,
      backhaul: slaveMeshInfo.backhaul,
      livenessKnown: livenessKnown,
      // The row a rename writes to, and the name it wrote (#1688 item 4). The
      // same leaf a client's name is, since an agent is a Hosts row too.
      hostInstancePath: slaveDevice?.instancePath,
      userDeviceName: nonEmpty(slaveDevice?.linksysUserDeviceLocation),
      // What the node detail page offers (#876); DataElements is its only source.
      actions: slaveMeshInfo.actions,
    );
  }
}
