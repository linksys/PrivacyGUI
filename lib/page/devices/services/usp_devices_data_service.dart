import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspDevicesDataServiceProvider = Provider<UspDevicesDataService>(
  (ref) {
    final usp = ref.read(uspServiceProvider);
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
  final UspService _usp;

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
            '[USP][Dashboard]DataElements empty — not a mesh or unsupported');
        return MeshTopologyInfo.empty;
      }
      return _buildTopologyInfo(network);
    } catch (e) {
      logger
          .d('[USP][Dashboard]DataElements not supported or fetch failed: $e');
      return MeshTopologyInfo.empty;
    }
  }

  MeshTopologyInfo _buildTopologyInfo(DataElementsNetwork network) {
    final nodes = <MeshNodeInfo>[];
    final clientToNodeMap = <String, String>{};

    for (final node in network.items) {
      final rawId = node.id.trim().toUpperCase();
      final nodeDeviceId = rawId.isNotEmpty ? rawId : node.instancePath;

      for (final radio in node.radios) {
        for (final bss in radio.bssList) {
          for (final sta in bss.stations) {
            final mac = sta.macAddress.trim();
            if (mac.isNotEmpty && nodeDeviceId.isNotEmpty) {
              clientToNodeMap[mac.toUpperCase()] = nodeDeviceId;
            }
          }
        }
      }

      nodes.add(MeshNodeInfo(
        instancePath: node.instancePath,
        deviceId: nodeDeviceId,
        model: node.manufacturerModel.trim(),
        manufacturer: node.manufacturer.trim(),
        serialNumber: node.serialNumber.trim(),
        softwareVersion: node.softwareVersion.trim(),
      ));
    }

    logger.d('[USP][Dashboard]Mesh nodes: ${nodes.length}, '
        'client→node mappings: ${clientToNodeMap.length}');
    return MeshTopologyInfo(nodes: nodes, clientToNodeMap: clientToNodeMap);
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

  List<DeviceUIModel> _buildDeviceUIModels({
    required ConnectedDevices connectedDevices,
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required String gatewayName,
  }) {
    return connectedDevices.items
        .where((d) => d.interface_.isNotEmpty)
        .map((d) => _toDeviceUIModel(
            d, wifiClientMap, connectionDetailMap, meshTopology, gatewayName))
        .toList();
  }

  List<NodeUIModel> _buildNodeUIModels({
    required MeshTopologyInfo meshTopology,
    required List<DeviceUIModel> deviceModels,
    required SystemInfoUIModel systemInfo,
  }) {
    if (meshTopology.isEmpty) {
      return [
        NodeUIModel(
          deviceId: 'gateway',
          model: systemInfo.modelName,
          manufacturer: systemInfo.manufacturer,
          serialNumber: systemInfo.serialNumber,
          softwareVersion: systemInfo.softwareVersion,
          isMaster: true,
          connectedDeviceCount: deviceModels.where((d) => d.isActive).length,
        ),
      ];
    }

    return meshTopology.nodes.asMap().entries.map((entry) {
      final index = entry.key;
      final node = entry.value;
      final isMaster = index == 0;

      final connectedCount = deviceModels
          .where((d) =>
              d.isActive &&
              d.parentNodeId != null &&
              d.parentNodeId!.toUpperCase() == node.deviceId.toUpperCase())
          .length;

      return NodeUIModel(
        deviceId: node.deviceId,
        model: node.model,
        manufacturer: node.manufacturer,
        serialNumber: node.serialNumber,
        softwareVersion: node.softwareVersion,
        isMaster: isMaster,
        connectedDeviceCount: connectedCount,
      );
    }).toList();
  }

  DeviceUIModel _toDeviceUIModel(
    ConnectedDevice device,
    Map<String, WifiClientUIModel> wifiClientMap,
    Map<String, ClientConnectionDetail> connectionDetailMap,
    MeshTopologyInfo meshTopology,
    String gatewayName,
  ) {
    final mac = device.macAddress.trim().toUpperCase();
    final isWifi = device.interface_.toLowerCase().contains('wifi');
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
      signalStrength: isWifi ? wifiClient?.signalStrength : null,
      downlinkRate: isWifi ? wifiClient?.lastDataDownlinkRate : null,
      uplinkRate: isWifi ? wifiClient?.lastDataUplinkRate : null,
      band: detail?.band,
      ssidName: detail?.ssidName,
      parentNodeId: parentNodeId,
      parentNodeName: parentNodeName,
    );
  }
}
