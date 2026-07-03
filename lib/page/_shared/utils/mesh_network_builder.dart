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
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

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
    final allBuiltClients = clientHostDevices
        .map((d) => _buildClientDevice(
              device: d,
              wifiClientMap: wifiClientMap,
              connectionDetailMap: connectionDetailMap,
              meshTopology: meshTopology,
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
    final masterMeshInfo =
        meshTopology.nodes.isNotEmpty ? meshTopology.nodes.first : null;
    final masterNodeId = masterDevice?.macAddress.trim().toUpperCase() ??
        masterMeshInfo?.deviceId ??
        'GATEWAY';

    // Clients for master: those with null parentNodeId or matching master ID
    final masterClients = <ClientDevice>[];
    final nullParentClients = clientsByNodeId[null] ?? [];
    masterClients.addAll(nullParentClients);
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

    // 7. Build SlaveNodes
    final slaves = meshDevices.where((d) => d.deviceRole == 'slave').map((d) {
      final slaveMeshInfo = _findMatchingMeshNode(d, meshTopology.nodes);
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

      return _buildSlaveNode(
        slaveDevice: d,
        slaveMeshInfo: slaveMeshInfo,
        connectedClients: slaveClients,
      );
    }).toList();

    // 8. Find unassigned clients (parentNodeId doesn't match any known node)
    final assignedNodeIds = <String>{
      masterNodeId,
      if (masterMeshInfo != null) masterMeshInfo.deviceId,
      ...slaves.map((s) => s.deviceId),
      ...slaves.map((s) => s.dataElementsId).whereType<String>(),
    };
    final unassigned = clientsByNodeId.entries
        .where((e) => e.key != null && !assignedNodeIds.contains(e.key))
        .expand((e) => e.value)
        .toList();

    return MeshNetwork(
      master: master,
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
      if (d.deviceRole != 'slave') continue;

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

    // Resolve parent node
    String? parentNodeId;
    String? parentNodeName;
    if (meshTopology.isEmpty) {
      if (device.isActive) parentNodeName = gatewayName;
    } else {
      parentNodeId = meshTopology.clientToNodeMap[mac];
      if (parentNodeId != null) {
        final isGateway = meshTopology.nodes.isNotEmpty &&
            meshTopology.nodes.first.deviceId == parentNodeId;
        if (isGateway) {
          parentNodeName = null;
        } else {
          parentNodeName = nodeDisplayNameMap[parentNodeId];
          if (parentNodeName == null) {
            final matchingNode = meshTopology.nodes
                .where((n) => n.deviceId == parentNodeId)
                .firstOrNull;
            parentNodeName = matchingNode?.model.isNotEmpty == true
                ? matchingNode!.model
                : parentNodeId;
          }
        }
      }
    }

    // Build WiFi info if applicable
    WifiConnectionInfo? wifi;
    if (isWifi) {
      final signalStrength = device.signalStrength ??
          wifiClient?.signalStrength ??
          meshTopology.clientSignalMap[mac];
      wifi = WifiConnectionInfo(
        signalStrength: signalStrength,
        band: detail?.band,
        ssidName: detail?.ssidName,
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
      manufacturer: device.manufacturer,
      modelName: device.modelName,
      operatingSystem: device.operatingSystem,
      hostsDeviceId: device.deviceId,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: Hostname grouping
  // ---------------------------------------------------------------------------

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
    required NodeUIModel? masterMeshInfo,
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
    );
  }

  // ---------------------------------------------------------------------------
  // Private: SlaveNode builder
  // ---------------------------------------------------------------------------

  static SlaveNode _buildSlaveNode({
    required ConnectedDevice slaveDevice,
    required NodeUIModel? slaveMeshInfo,
    required List<ClientDevice> connectedClients,
  }) {
    final deviceId = slaveDevice.macAddress.trim().toUpperCase();

    final backhaul = BackhaulInfo(
      mediaType: slaveMeshInfo?.backhaulMediaType ?? '',
      linkType: slaveMeshInfo?.backhaulLinkType,
      phyRate: slaveMeshInfo?.backhaulPhyRate ?? 0,
      signalStrength: slaveMeshInfo?.backhaulSignalStrength,
      uplinkRate: slaveMeshInfo?.backhaulUplinkRate,
      downlinkRate: slaveMeshInfo?.backhaulDownlinkRate,
      parentNodeId: slaveMeshInfo?.backhaulParentDeviceId,
      parentBssid: slaveMeshInfo?.backhaulParentBssid,
      lastContactTime: slaveMeshInfo?.lastContactTime,
      backhaulAlId: slaveMeshInfo?.backhaulAlId,
      backhaulMacAddress: slaveMeshInfo?.backhaulMacAddress,
    );

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
    );
  }

  // ---------------------------------------------------------------------------
  // Private: Mesh node matching
  // ---------------------------------------------------------------------------

  static NodeUIModel? _findMatchingMeshNode(
    ConnectedDevice device,
    List<NodeUIModel> meshNodes,
  ) {
    final hostsDeviceId =
        device.deviceId?.toUpperCase().replaceAll('-', '') ?? '';
    if (hostsDeviceId.length < 12) return null;

    final embeddedMac = hostsDeviceId.substring(hostsDeviceId.length - 12);

    return meshNodes.where((n) {
      final nodeIdNormalized = n.deviceId.toUpperCase().replaceAll(':', '');
      return nodeIdNormalized == embeddedMac;
    }).firstOrNull;
  }
}
