import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_topology_builder.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspDevicesDataServiceProvider = Provider<UspDevicesDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }
    return UspDevicesDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Opaque codegen context
// ---------------------------------------------------------------------------

/// Opaque wrapper around raw ConnectedDevices codegen data.
///
/// Held by [DevicesDataNotifier] and passed back to [UspDevicesDataService]
/// for incremental rebuilds (WiFi listener, mesh update) without the provider
/// needing to import codegen types.
class DevicesCodegenContext extends Equatable {
  final ConnectedDevices _connectedDevices;

  const DevicesCodegenContext(this._connectedDevices);

  static const empty = DevicesCodegenContext(ConnectedDevices(items: []));

  @override
  List<Object?> get props => [_connectedDevices.items.length];
}

// ---------------------------------------------------------------------------
// Fetch result
// ---------------------------------------------------------------------------

/// Result of a devices data fetch, returned by [UspDevicesDataService.fetch].
class DevicesDataFetchResult {
  final DevicesCodegenContext codegenContext;
  final List<DeviceUIModel> deviceModels;
  final List<NodeUIModel> nodeModels;
  final Map<String, String> hostNameByMac;

  const DevicesDataFetchResult({
    required this.codegenContext,
    required this.deviceModels,
    required this.nodeModels,
    required this.hostNameByMac,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching and transforming connected devices data.
///
/// Owns the codegen call, error mapping, and all device/node UI model building
/// for [devicesDataProvider].
class UspDevicesDataService {
  final UspClient _usp;

  UspDevicesDataService(this._usp);

  /// Fetches connected devices and returns a [DevicesDataFetchResult].
  ///
  /// Builds device and node UI models with empty mesh topology.
  /// Mesh topology is fetched separately via [fetchMeshTopology].
  Future<DevicesDataFetchResult> fetch({
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required String gatewayName,
    SystemInfoUIModel? systemInfo,
  }) async {
    final ConnectedDevices connectedDevices;
    try {
      connectedDevices = await ConnectedDevices.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final context = DevicesCodegenContext(connectedDevices);

    final hostNameByMac = _buildHostNameMap(connectedDevices);

    final deviceModels = _buildDeviceUIModels(
      connectedDevices: connectedDevices,
      wifiClientMap: wifiClientMap,
      connectionDetailMap: connectionDetailMap,
      meshTopology: MeshTopologyInfo.empty,
      gatewayName: gatewayName,
    );

    final nodeModels = systemInfo != null
        ? _buildNodeUIModels(
            meshTopology: MeshTopologyInfo.empty,
            deviceModels: deviceModels,
            systemInfo: systemInfo,
          )
        : <NodeUIModel>[];

    return DevicesDataFetchResult(
      codegenContext: context,
      deviceModels: deviceModels,
      nodeModels: nodeModels,
      hostNameByMac: hostNameByMac,
    );
  }

  /// Fetches mesh topology via DataElements (fire-and-forget from provider).
  ///
  /// Delegates nested multi-instance parsing
  /// (Device.{i} → Radio.{j} → BSS.{k} → STA.{l})
  /// to codegen [DataElementsNetwork.fetch], then transforms the tree
  /// into a flat [MeshTopologyInfo] with client→node mapping.
  ///
  /// Returns [MeshTopologyInfo.empty] if the router doesn't support
  /// DataElements or the subtree is empty (non-mesh / single router).
  Future<MeshTopologyInfo> fetchMeshTopology() async {
    try {
      final network = await DataElementsNetwork.fetch(_usp);
      if (network.items.isEmpty) {
        logger.d(
            '[USP][Dashboard]: DataElements empty — not a mesh or unsupported');
        return MeshTopologyInfo.empty;
      }
      return _buildTopologyInfo(network);
    } catch (e) {
      logger.d(
          '[USP][Dashboard]: DataElements not supported or fetch failed: $e');
      return MeshTopologyInfo.empty;
    }
  }

  MeshTopologyInfo _buildTopologyInfo(DataElementsNetwork network) {
    final result = MeshTopologyBuilder.build(network);
    logger.d('[USP][Dashboard]: Mesh nodes: ${result.nodes.length}, '
        'client→node mappings: ${result.clientToNodeMap.length}');
    return result;
  }

  /// Rebuilds device + node UI models with updated WiFi enrichment data.
  ///
  /// Called by the provider's WiFi listener for incremental rebuild
  /// without re-fetching ConnectedDevices.
  ({List<DeviceUIModel> deviceModels, List<NodeUIModel> nodeModels})
      rebuildWithWifiData({
    required DevicesCodegenContext context,
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required String gatewayName,
    SystemInfoUIModel? systemInfo,
  }) {
    final deviceModels = _buildDeviceUIModels(
      connectedDevices: context._connectedDevices,
      wifiClientMap: wifiClientMap,
      connectionDetailMap: connectionDetailMap,
      meshTopology: meshTopology,
      gatewayName: gatewayName,
    );

    final nodeModels = systemInfo != null
        ? _buildNodeUIModels(
            meshTopology: meshTopology,
            deviceModels: deviceModels,
            systemInfo: systemInfo,
          )
        : <NodeUIModel>[];

    return (deviceModels: deviceModels, nodeModels: nodeModels);
  }

  /// Rebuilds device + node UI models after mesh topology arrives.
  ({List<DeviceUIModel> deviceModels, List<NodeUIModel> nodeModels})
      rebuildWithMesh({
    required DevicesCodegenContext context,
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required String gatewayName,
    SystemInfoUIModel? systemInfo,
  }) {
    // Same logic as rebuildWithWifiData — both rebuild from context + enrichment.
    return rebuildWithWifiData(
      context: context,
      wifiClientMap: wifiClientMap,
      connectionDetailMap: connectionDetailMap,
      meshTopology: meshTopology,
      gatewayName: gatewayName,
      systemInfo: systemInfo,
    );
  }

  // ---------------------------------------------------------------------------
  // Private — UI model builders
  // ---------------------------------------------------------------------------

  Map<String, String> _buildHostNameMap(ConnectedDevices devices) {
    final map = <String, String>{};
    for (final d in devices.items) {
      if (d.hostName.isNotEmpty) {
        map[d.macAddress.trim().toUpperCase()] = d.hostName;
      }
    }
    return map;
  }

  /// Normalizes hostname for grouping: lowercase + strip mDNS suffix.
  ///
  /// mDNS suffixes (e.g., "._tcp.local", "._device-info._tcp.local") are
  /// stripped to ensure devices advertising via mDNS group correctly with
  /// those using plain hostnames.
  ///
  /// Examples:
  /// - "MacBook-Pro" → "macbook-pro"
  /// - "MacBook._tcp.local" → "macbook"
  /// - "iPhone._device-info._tcp.local" → "iphone"
  String _normalizeHostname(String hostname) {
    var normalized = hostname.trim().toLowerCase();
    if (normalized.isEmpty) return '';

    // Strip mDNS suffix (matches device_classifier.dart behavior)
    final mdnsSuffixIndex = normalized.indexOf('._');
    if (mdnsSuffixIndex > 0) {
      normalized = normalized.substring(0, mdnsSuffixIndex);
    }
    return normalized;
  }

  List<DeviceUIModel> _buildDeviceUIModels({
    required ConnectedDevices connectedDevices,
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required String gatewayName,
  }) {
    // Step 1: Build all DeviceUIModels (ungrouped)
    final allDevices = connectedDevices.items
        .where((d) => d.interface_.isNotEmpty || d.isActive)
        .map((d) => _toDeviceUIModel(
            d, wifiClientMap, connectionDetailMap, meshTopology, gatewayName))
        .toList();

    // Step 2: Group by hostname (empty hostname devices stay ungrouped)
    // Also exclude mesh nodes (master/slave) from grouping
    final grouped = <String, List<DeviceUIModel>>{};
    final ungrouped = <DeviceUIModel>[];

    for (final device in allDevices) {
      // Mesh nodes should not be grouped
      if (device.isMeshNode) {
        ungrouped.add(device);
        continue;
      }

      final hostname = _normalizeHostname(device.hostName);
      if (hostname.isEmpty) {
        ungrouped.add(device);
      } else {
        grouped.putIfAbsent(hostname, () => []).add(device);
      }
    }

    // Step 3: Merge devices with same hostname
    final result = <DeviceUIModel>[];

    for (final devices in grouped.values) {
      if (devices.length == 1) {
        result.add(devices.first);
      } else {
        result.add(_mergeDevicesByHostname(devices));
      }
    }

    result.addAll(ungrouped);
    return result;
  }

  /// Merges multiple DeviceUIModels with the same hostname into one.
  ///
  /// Primary interface selection priority: active > WiFi > Ethernet.
  /// Additional interfaces are stored in [DeviceUIModel.additionalInterfaces].
  DeviceUIModel _mergeDevicesByHostname(List<DeviceUIModel> devices) {
    // Sort to select primary interface: active first, then WiFi over Ethernet
    final sorted = List<DeviceUIModel>.from(devices)
      ..sort((a, b) {
        // Active interfaces first
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        // WiFi preferred (typically has more enrichment data like signal)
        if (a.isWifi != b.isWifi) return a.isWifi ? -1 : 1;
        return 0;
      });

    final primary = sorted.first;
    final additional = sorted
        .skip(1)
        .map((d) => DeviceInterfaceInfo(
              mac: d.mac,
              ip: d.ip,
              isWifi: d.isWifi,
              isActive: d.isActive,
              layer1Interface: d.layer1Interface,
              band: d.band,
              ssidName: d.ssidName,
              signalStrength: d.signalStrength,
            ))
        .toList();

    logger.d('[USP][Devices]: Merged ${devices.length} interfaces for '
        'hostname="${primary.hostName}" — primary=${primary.mac} (${primary.isWifi ? "WiFi" : "Ethernet"}), '
        'additional=${additional.map((i) => "${i.mac} (${i.isWifi ? "WiFi" : "Ethernet"})").join(", ")}');

    return primary.copyWith(additionalInterfaces: additional);
  }

  List<NodeUIModel> _buildNodeUIModels({
    required MeshTopologyInfo meshTopology,
    required List<DeviceUIModel> deviceModels,
    required SystemInfoUIModel systemInfo,
  }) {
    // Extract mesh nodes from Hosts (deviceRole = master/slave).
    // This is available immediately without waiting for DataElements fetch.
    final meshDevices = deviceModels.meshNodes;

    // Client devices only (excluding mesh nodes).
    final clientDevices = deviceModels.clientDevices;

    // If no mesh devices found in Hosts, create gateway-only node.
    if (meshDevices.isEmpty) {
      return [
        NodeUIModel(
          deviceId: 'gateway',
          model: systemInfo.modelName,
          manufacturer: systemInfo.manufacturer,
          serialNumber: systemInfo.serialNumber,
          softwareVersion: systemInfo.softwareVersion,
          isMaster: true,
          connectedDeviceCount: clientDevices.where((d) => d.isActive).length,
        ),
      ];
    }

    // Build nodes from Hosts deviceRole, enrich with DataElements if available.
    final nodes = <NodeUIModel>[];

    // Find master first.
    final master = meshDevices.masterNode ?? meshDevices.first;

    // Master node — use systemInfo for details (Hosts doesn't have model/firmware).
    final masterMeshInfo =
        meshTopology.nodes.isNotEmpty ? meshTopology.nodes.first : null;
    final masterConnectedCount = clientDevices
        .where((d) =>
            d.isActive &&
            (d.parentNodeId == null ||
                d.parentNodeId!.toUpperCase() == master.mac.toUpperCase() ||
                (masterMeshInfo != null &&
                    d.parentNodeId!.toUpperCase() ==
                        masterMeshInfo.deviceId.toUpperCase())))
        .length;

    nodes.add(NodeUIModel(
      deviceId: master.mac,
      friendlyName: master.friendlyName,
      hostName: master.hostName,
      model: masterMeshInfo?.model ?? systemInfo.modelName,
      manufacturer: masterMeshInfo?.manufacturer ?? systemInfo.manufacturer,
      serialNumber: masterMeshInfo?.serialNumber ?? systemInfo.serialNumber,
      softwareVersion:
          masterMeshInfo?.softwareVersion ?? systemInfo.softwareVersion,
      isMaster: true,
      connectedDeviceCount: masterConnectedCount,
    ));

    // Slave nodes.
    for (final slave in meshDevices.slaveNodes) {
      final slaveMeshInfo = _findMatchingMeshNode(slave, meshTopology.nodes);
      logger.d('[USP][Topology]: Slave ${slave.mac} matched to meshInfo: '
          '${slaveMeshInfo != null ? "yes (signalStrength=${slaveMeshInfo.backhaulSignalStrength})" : "no"}, '
          'meshTopology.nodes.length=${meshTopology.nodes.length}');

      final slaveConnectedCount = clientDevices
          .where((d) =>
              d.isActive &&
              d.parentNodeId != null &&
              (d.parentNodeId!.toUpperCase() == slave.mac.toUpperCase() ||
                  (slaveMeshInfo != null &&
                      d.parentNodeId!.toUpperCase() ==
                          slaveMeshInfo.deviceId.toUpperCase())))
          .length;

      nodes.add(NodeUIModel(
        deviceId: slave.mac,
        dataElementsId: slaveMeshInfo?.deviceId,
        friendlyName: slave.friendlyName,
        hostName: slave.hostName,
        model: slaveMeshInfo?.model ?? slave.modelName ?? '',
        manufacturer: slaveMeshInfo?.manufacturer ?? slave.manufacturer ?? '',
        serialNumber: slaveMeshInfo?.serialNumber ?? '',
        softwareVersion: slaveMeshInfo?.softwareVersion ?? '',
        isMaster: false,
        connectedDeviceCount: slaveConnectedCount,
        backhaulMediaType: slaveMeshInfo?.backhaulMediaType ?? '',
        backhaulPhyRate: slaveMeshInfo?.backhaulPhyRate ?? 0,
        backhaulSignalStrength: slaveMeshInfo?.backhaulSignalStrength,
        backhaulUplinkRate: slaveMeshInfo?.backhaulUplinkRate,
      ));
    }

    return nodes;
  }

  DeviceUIModel _toDeviceUIModel(
    ConnectedDevice device,
    Map<String, WifiClientUIModel> wifiClientMap,
    Map<String, ClientConnectionDetail> connectionDetailMap,
    MeshTopologyInfo meshTopology,
    String gatewayName,
  ) {
    final mac = device.macAddress.trim().toUpperCase();
    // Determine WiFi via Layer1Interface or InterfaceType (fallback for empty Layer1Interface).
    final interfaceType = device.interfaceType?.toLowerCase() ?? '';
    final isWifi = device.interface_.toLowerCase().contains('wifi') ||
        interfaceType.contains('wi-fi') ||
        interfaceType.contains('wifi');
    final wifiClient = wifiClientMap[mac];
    final detail = connectionDetailMap[mac];

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
          parentNodeName = gatewayName;
        } else {
          final matchingNode = meshTopology.nodes
              .where((n) => n.deviceId == parentNodeId)
              .firstOrNull;
          parentNodeName = matchingNode?.model.isNotEmpty == true
              ? matchingNode!.model
              : parentNodeId;
        }
      } else {
        parentNodeName = gatewayName;
      }
    }

    return DeviceUIModel(
      mac: mac,
      ip: device.ipAddress,
      hostName: device.hostName,
      isActive: device.isActive,
      isWifi: isWifi,
      layer1Interface: device.interface_,
      ipv6Addresses: device.ipv6Addresses
          .map((e) => e.address)
          .where((a) => a.isNotEmpty)
          .toList(),
      // Prefer Hosts data, fallback to WiFi STA table data.
      signalStrength:
          isWifi ? (device.signalStrength ?? wifiClient?.signalStrength) : null,
      downlinkRate: isWifi
          ? (device.lastDataDownlinkRate ?? wifiClient?.lastDataDownlinkRate)
          : null,
      uplinkRate: isWifi
          ? (device.lastDataUplinkRate ?? wifiClient?.lastDataUplinkRate)
          : null,
      band: detail?.band,
      ssidName: detail?.ssidName,
      parentNodeId: parentNodeId,
      parentNodeName: parentNodeName,
      deviceRole: device.deviceRole,
      interfaceType: device.interfaceType,
      friendlyName: device.friendlyName,
      manufacturer: device.manufacturer,
      hostsDeviceId: device.deviceId,
      modelName: device.modelName,
      operatingSystem: device.operatingSystem,
    );
  }

  // ---------------------------------------------------------------------------
  // Mesh Node Matching
  // ---------------------------------------------------------------------------

  /// Finds a matching [NodeUIModel] for a slave device from Hosts.
  ///
  /// Strategy: Extract embedded MAC from Hosts DeviceID (UUID format) and match
  /// against DataElements node ID.
  ///
  /// Hosts DeviceID format: "0217B8A4-1082-4532-8345-80691ABB4694"
  /// Last 12 chars (no hyphens) = MAC: "80691ABB4694" → matches "80:69:1A:BB:46:94"
  ///
  /// Future alternatives if this approach proves unreliable:
  /// - Match via BSSID: DataElements Radio.*.BSS.*.BSSID = Hosts PhysAddress
  /// - Match via hostName suffix: "Linksys03027" → SerialNumber ending "03027"
  NodeUIModel? _findMatchingMeshNode(
    DeviceUIModel slave,
    List<NodeUIModel> meshNodes,
  ) {
    final hostsDeviceId =
        slave.hostsDeviceId?.toUpperCase().replaceAll('-', '') ?? '';
    if (hostsDeviceId.length < 12) return null;

    final embeddedMac = hostsDeviceId.substring(hostsDeviceId.length - 12);

    return meshNodes.where((n) {
      final nodeIdNormalized = n.deviceId.toUpperCase().replaceAll(':', '');
      return nodeIdNormalized == embeddedMac;
    }).firstOrNull;
  }
}
