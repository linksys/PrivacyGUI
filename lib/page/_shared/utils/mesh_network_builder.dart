import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';

/// Builds [MeshNetwork] from raw data sources.
///
/// Transforms Hosts (ConnectedDevices), WiFi enrichment, and DataElements
/// into the unified MeshNetwork architecture.
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
    // 1. Separate mesh nodes and client devices
    final meshDevices = <ConnectedDevice>[];
    final clientHostDevices = <ConnectedDevice>[];

    for (final d in connectedDevices.items) {
      if (d.deviceRole == 'master' || d.deviceRole == 'slave') {
        meshDevices.add(d);
      } else if (d.interface_.isNotEmpty || d.isActive) {
        clientHostDevices.add(d);
      }
    }

    // 2. Build node display name map (Hosts hostname → DataElements node ID)
    final nodeDisplayNameMap =
        _buildNodeDisplayNameMap(connectedDevices, meshTopology);

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

    // 4. Apply hostname grouping (merge multi-interface devices)
    final groupedClients = _groupByHostname(allBuiltClients);

    // 5. Group clients by parentNodeId
    final clientsByNodeId = <String?, List<ClientDevice>>{};
    for (final client in groupedClients) {
      final nodeId = client.parentNodeId;
      (clientsByNodeId[nodeId] ??= []).add(client);
    }

    // 6. Build MasterNode
    final masterDevice =
        meshDevices.where((d) => d.deviceRole == 'master').firstOrNull;
    final masterMeshInfo = meshTopology.nodes.master;
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
    final patchedMaster = MasterNode(
      deviceId: master.deviceId,
      dataElementsId: master.dataElementsId,
      friendlyName: master.friendlyName,
      hostName: master.hostName,
      model: master.model,
      manufacturer: master.manufacturer,
      serialNumber: master.serialNumber,
      softwareVersion: master.softwareVersion,
      ipAddress: master.ipAddress,
      ipv6Addresses: master.ipv6Addresses,
      instancePath: master.instancePath,
      connectedClients: patchedMasterClients,
      hostsDeviceId: master.hostsDeviceId,
    );

    // 7. Build SlaveNodes
    final slaves = meshDevices.where((d) => d.deviceRole == 'slave').map((d) {
      final slaveMeshInfo = _findMatchingMeshNode(d, meshTopology.nodes.slaves);
      final slaveNodeId = d.macAddress.trim().toUpperCase();

      // Clients for this slave
      final slaveClients = <ClientDevice>[];
      if (clientsByNodeId.containsKey(slaveNodeId)) {
        slaveClients.addAll(clientsByNodeId[slaveNodeId]!);
      }
      if (slaveMeshInfo != null &&
          slaveMeshInfo.deviceId != slaveNodeId &&
          clientsByNodeId.containsKey(slaveMeshInfo.deviceId)) {
        slaveClients.addAll(clientsByNodeId[slaveMeshInfo.deviceId]!);
      }

      final slave = _buildSlaveNode(
        slaveDevice: d,
        slaveMeshInfo: slaveMeshInfo,
        connectedClients: slaveClients,
        // An empty topology carries no liveness information for any node, so an
        // unmatched row must not be read as "offline" (#1430 review).
        //
        // Deliberately `isNotEmpty` and NOT the `topologyHasMesh` predicate
        // built at the top of this method, even though both read
        // `meshTopology.nodes` and the narrower one looks like the safer
        // choice. `hasMesh` is "at least one *slave* agent answered", and the
        // whole point of #1430 is the single-extender house whose extender is
        // powered off: DataElements then enumerates only the router's own agent
        // (`MeshTopologyBuilder` adds the master unconditionally) while the
        // extender's `Device.Hosts.Host` row persists for another ~20-50s.
        // `hasMesh` would be false there, this node would be handed
        // `livenessKnown: false`, and a powered-off extender would render
        // online — i.e. narrowing the predicate reverts the ticket for the
        // commonest topology. The two predicates answer different questions on
        // the same object; do not unify them.
        livenessKnown: meshTopology.isNotEmpty,
      );

      // Patch slave's connected clients with parentNodeName
      final slaveDisplayName = slave.displayName;
      final patchedSlaveClients = slaveClients
          .map((c) => c.copyWith(parentNodeName: slaveDisplayName))
          .toList();
      return SlaveNode(
        deviceId: slave.deviceId,
        dataElementsId: slave.dataElementsId,
        friendlyName: slave.friendlyName,
        hostName: slave.hostName,
        model: slave.model,
        manufacturer: slave.manufacturer,
        serialNumber: slave.serialNumber,
        softwareVersion: slave.softwareVersion,
        ipAddress: slave.ipAddress,
        ipv6Addresses: slave.ipv6Addresses,
        instancePath: slave.instancePath,
        connectedClients: patchedSlaveClients,
        backhaul: slave.backhaul,
        livenessKnown: slave.livenessKnown,
      );
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
        // Shape B — a parent ID matching no node built from Hosts. Only
        // resolvable here, once the slaves are known, so the flag is stamped at
        // this point. Setting it also clears parentNodeName, which the resolver
        // had already filled in from the unmatched node's model (or the gateway
        // name): keeping that would leave the device claiming a parent while
        // being declared unattributed.
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

  static Map<String, String> _buildNodeDisplayNameMap(
    ConnectedDevices devices,
    MeshTopologyInfo meshTopology,
  ) {
    final map = <String, String>{};
    for (final d in devices.items) {
      // Include both master and slave nodes
      if (d.deviceRole != 'master' && d.deviceRole != 'slave') continue;

      final displayName = (d.friendlyName?.isNotEmpty == true)
          ? d.friendlyName!
          : (d.hostName.isNotEmpty ? d.hostName : null);
      if (displayName == null) continue;

      // Match via embedded MAC in Hosts DeviceID
      final hostsDeviceId = d.deviceId?.toUpperCase().replaceAll('-', '') ?? '';
      if (hostsDeviceId.length >= 12) {
        final embeddedMac = hostsDeviceId.substring(hostsDeviceId.length - 12);
        for (final node in meshTopology.nodes) {
          final nodeIdNormalized =
              node.deviceId.toUpperCase().replaceAll(':', '');
          if (nodeIdNormalized == embeddedMac) {
            map[node.deviceId] = displayName;
            break;
          }
        }
      }

      // For master, also try matching via MAC address directly
      if (d.deviceRole == 'master') {
        final masterMac = d.macAddress.trim().toUpperCase();
        if (masterMac.isNotEmpty && !map.containsKey(masterMac)) {
          map[masterMac] = displayName;
        }
      }
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
      parentNodeId = meshTopology.clientToNodeMap[mac];
      if (parentNodeId == null) {
        isUnattributed = topologyHasMesh && isWifi && device.isActive;
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
      final signalStrength = hostsSignal ??
          wifiClient?.signalStrength ??
          meshTopology.clientSignalMap[mac];
      // Fallback to DataElements band/SSID for slave node clients.
      // ClientConnectionDetail.band/ssidName are non-nullable Strings that are
      // '' when AP→SSID→radio resolution fails, so treat empty as absent —
      // otherwise the empty string would mask the DataElements fallback value.
      final bandSsid = meshTopology.clientBandSsidMap[mac];
      wifi = WifiConnectionInfo(
        signalStrength: signalStrength,
        band: _nonEmpty(detail?.band) ?? bandSsid?.band,
        ssidName: _nonEmpty(detail?.ssidName) ?? bandSsid?.ssid,
        downlinkRate:
            device.lastDataDownlinkRate ?? wifiClient?.lastDataDownlinkRate,
        uplinkRate: device.lastDataUplinkRate ?? wifiClient?.lastDataUplinkRate,
      );
    }

    return ClientDevice(
      mac: mac,
      ip: device.ipAddress,
      hostName: device.hostName,
      friendlyName: device.friendlyName,
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
      manufacturer: device.manufacturer,
      modelName: device.modelName,
      operatingSystem: device.operatingSystem,
      hostsDeviceId: device.deviceId,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: Hostname grouping
  // ---------------------------------------------------------------------------

  /// Returns [s] if it is non-null and non-empty, otherwise null.
  /// Used so an empty String from a non-nullable source doesn't mask a `??`
  /// fallback to another source.
  static String? _nonEmpty(String? s) => (s != null && s.isNotEmpty) ? s : null;

  static String _normalizeHostname(String hostname) {
    var normalized = hostname.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    final mdnsSuffixIndex = normalized.indexOf('._');
    if (mdnsSuffixIndex > 0) {
      normalized = normalized.substring(0, mdnsSuffixIndex);
    }
    return normalized;
  }

  static List<ClientDevice> _groupByHostname(List<ClientDevice> clients) {
    final grouped = <String, List<ClientDevice>>{};
    final ungrouped = <ClientDevice>[];

    for (final client in clients) {
      final hostname = _normalizeHostname(client.hostName);
      if (hostname.isEmpty) {
        ungrouped.add(client);
      } else {
        grouped.putIfAbsent(hostname, () => []).add(client);
      }
    }

    final result = <ClientDevice>[];
    for (final devices in grouped.values) {
      if (devices.length == 1) {
        result.add(devices.first);
      } else {
        result.add(_mergeClientsByHostname(devices));
      }
    }
    result.addAll(ungrouped);
    return result;
  }

  static ClientDevice _mergeClientsByHostname(List<ClientDevice> devices) {
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
            ))
        .toList();

    logger.d('[MeshNetworkBuilder]: Merged ${devices.length} interfaces for '
        'hostname="${primary.hostName}" — primary=${primary.mac}');

    return primary.copyWith(additionalInterfaces: additional);
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

    return MasterNode(
      deviceId: deviceId,
      dataElementsId: masterMeshInfo?.deviceId,
      friendlyName: masterDevice?.friendlyName,
      hostName: masterDevice?.hostName ?? gatewayName,
      model: masterMeshInfo?.model ?? systemInfo?.modelName ?? '',
      manufacturer:
          masterMeshInfo?.manufacturer ?? systemInfo?.manufacturer ?? '',
      serialNumber:
          masterMeshInfo?.serialNumber ?? systemInfo?.serialNumber ?? '',
      softwareVersion:
          masterMeshInfo?.softwareVersion ?? systemInfo?.softwareVersion ?? '',
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

  static SlaveNode _buildSlaveNode({
    required ConnectedDevice slaveDevice,
    required SlaveNode? slaveMeshInfo,
    required List<ClientDevice> connectedClients,
    required bool livenessKnown,
  }) {
    final deviceId = slaveDevice.macAddress.trim().toUpperCase();

    final backhaul =
        slaveMeshInfo?.backhaul ?? const BackhaulInfo(mediaType: '');

    return SlaveNode(
      deviceId: deviceId,
      dataElementsId: slaveMeshInfo?.deviceId,
      friendlyName: slaveDevice.friendlyName,
      hostName: slaveDevice.hostName,
      model: slaveMeshInfo?.model ?? slaveDevice.modelName ?? '',
      manufacturer:
          slaveMeshInfo?.manufacturer ?? slaveDevice.manufacturer ?? '',
      serialNumber: slaveMeshInfo?.serialNumber ?? '',
      softwareVersion: slaveMeshInfo?.softwareVersion ?? '',
      ipAddress:
          slaveDevice.ipAddress.isNotEmpty ? slaveDevice.ipAddress : null,
      ipv6Addresses: slaveDevice.ipv6Addresses
          .map((e) => e.address)
          .where((a) => a.isNotEmpty)
          .toList(),
      instancePath: slaveMeshInfo?.instancePath,
      connectedClients: connectedClients,
      backhaul: backhaul,
      livenessKnown: livenessKnown,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: Mesh node matching
  // ---------------------------------------------------------------------------

  static SlaveNode? _findMatchingMeshNode(
    ConnectedDevice device,
    List<SlaveNode> meshSlaves,
  ) {
    final hostsDeviceId =
        device.deviceId?.toUpperCase().replaceAll('-', '') ?? '';
    if (hostsDeviceId.length < 12) return null;

    final embeddedMac = hostsDeviceId.substring(hostsDeviceId.length - 12);

    return meshSlaves.where((n) {
      final nodeIdNormalized = n.deviceId.toUpperCase().replaceAll(':', '');
      return nodeIdNormalized == embeddedMac;
    }).firstOrNull;
  }
}
