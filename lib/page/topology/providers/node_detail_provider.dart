import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart'
    hide ConnectionType;
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

/// Computed provider — looks up a single node + its connected devices by deviceId.
///
/// Uses [MeshNetwork] for direct node lookup and pre-organized connected clients.
final uspNodeDetailProvider =
    Provider.family<UspNodeDetailState, String>((ref, deviceId) {
  final data = ref.watch(devicesDataProvider).valueOrNull;
  final meshNetwork = data?.meshNetwork;

  // Use new MeshNetwork if available
  if (meshNetwork != null) {
    final nodeEntity = meshNetwork.findNode(deviceId);
    if (nodeEntity == null) return UspNodeDetailState.empty();

    // Look up parent node for slaves
    NodeEntity? parentNodeEntity;
    if (nodeEntity is SlaveNode && nodeEntity.backhaul.parentNodeId != null) {
      parentNodeEntity = meshNetwork.findNode(nodeEntity.backhaul.parentNodeId!);
    }

    // Build legacy NodeUIModel for backward compatibility with views
    final legacyNode = _toNodeUIModel(nodeEntity);
    final legacyParent =
        parentNodeEntity != null ? _toNodeUIModel(parentNodeEntity) : null;
    final legacyDevices = nodeEntity.connectedClients
        .map((c) => _toDeviceUIModel(c))
        .toList();

    return UspNodeDetailState(
      nodeEntity: nodeEntity,
      parentNodeEntity: parentNodeEntity,
      clientDevices: nodeEntity.connectedClients,
      node: legacyNode,
      parentNode: legacyParent,
      connectedDevices: legacyDevices,
    );
  }

  // Fallback: legacy path using nodeModels/deviceModels
  if (data == null) return UspNodeDetailState.empty();

  final node = data.nodeModels
      .where((n) => n.deviceId.toUpperCase() == deviceId.toUpperCase())
      .firstOrNull;

  if (node == null) return UspNodeDetailState.empty();

  // Look up parent node using backhaulParentDeviceId (parent's Device ID)
  NodeUIModel? parentNode;
  if (node.backhaulParentDeviceId != null &&
      node.backhaulParentDeviceId!.isNotEmpty) {
    final parentId =
        node.backhaulParentDeviceId!.toUpperCase().replaceAll(':', '');
    parentNode = data.nodeModels.where((n) {
      final nodeId = n.deviceId.toUpperCase().replaceAll(':', '');
      final nodeDeId = n.dataElementsId?.toUpperCase().replaceAll(':', '');
      return nodeId == parentId || nodeDeId == parentId;
    }).firstOrNull;
  }

  // For non-mesh routers the synthetic gateway uses deviceId 'gateway',
  // and devices have parentNodeId == null (no DataElements mapping).
  // Treat null parentNodeId as "connected to gateway".
  final isGatewayLookup = deviceId.toUpperCase() == 'GATEWAY';
  final connectedDevices = data.deviceModels
      .where((d) =>
          (d.parentNodeId != null &&
              d.parentNodeId!.toUpperCase() == deviceId.toUpperCase()) ||
          (isGatewayLookup && d.parentNodeId == null))
      .toList();

  return UspNodeDetailState(
    node: node,
    parentNode: parentNode,
    connectedDevices: connectedDevices,
  );
});

// ---------------------------------------------------------------------------
// Conversion helpers (NodeEntity/ClientDevice → legacy models)
// ---------------------------------------------------------------------------

NodeUIModel _toNodeUIModel(NodeEntity entity) {
  return switch (entity) {
    MasterNode m => NodeUIModel(
        deviceId: m.deviceId,
        dataElementsId: m.dataElementsId,
        friendlyName: m.friendlyName,
        hostName: m.hostName,
        model: m.model,
        manufacturer: m.manufacturer,
        serialNumber: m.serialNumber,
        softwareVersion: m.softwareVersion,
        isMaster: true,
        connectedDeviceCount: m.connectedClients.length,
        ipAddress: m.ipAddress,
        ipv6Addresses: m.ipv6Addresses,
        wanIpAddress: m.wanIpAddress,
      ),
    SlaveNode s => NodeUIModel(
        deviceId: s.deviceId,
        dataElementsId: s.dataElementsId,
        friendlyName: s.friendlyName,
        hostName: s.hostName,
        model: s.model,
        manufacturer: s.manufacturer,
        serialNumber: s.serialNumber,
        softwareVersion: s.softwareVersion,
        isMaster: false,
        connectedDeviceCount: s.connectedClients.length,
        ipAddress: s.ipAddress,
        ipv6Addresses: s.ipv6Addresses,
        backhaulMediaType: s.backhaul.mediaType,
        backhaulPhyRate: s.backhaul.phyRate,
        backhaulSignalStrength: s.backhaul.signalStrength,
        backhaulUplinkRate: s.backhaul.uplinkRate,
        backhaulLinkType: s.backhaul.linkType,
        backhaulDownlinkRate: s.backhaul.downlinkRate,
        backhaulParentDeviceId: s.backhaul.parentNodeId,
        backhaulParentBssid: s.backhaul.parentBssid,
        lastContactTime: s.backhaul.lastContactTime,
        backhaulAlId: s.backhaul.backhaulAlId,
        backhaulMacAddress: s.backhaul.backhaulMacAddress,
      ),
  };
}

DeviceUIModel _toDeviceUIModel(ClientDevice client) {
  return DeviceUIModel(
    mac: client.mac,
    ip: client.ip,
    hostName: client.hostName,
    isActive: client.isActive,
    isWifi: client.isWifi,
    layer1Interface: client.layer1Interface,
    ipv6Addresses: client.ipv6Addresses,
    signalStrength: client.signalStrength,
    downlinkRate: client.downlinkRate,
    uplinkRate: client.uplinkRate,
    band: client.band,
    ssidName: client.ssidName,
    parentNodeId: client.parentNodeId,
    parentNodeName: client.parentNodeName,
    friendlyName: client.friendlyName,
    manufacturer: client.manufacturer,
    modelName: client.modelName,
    operatingSystem: client.operatingSystem,
    hostsDeviceId: client.hostsDeviceId,
  );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UspNodeDetailState extends Equatable {
  // New architecture
  final NodeEntity? nodeEntity;
  final NodeEntity? parentNodeEntity;
  final List<ClientDevice> clientDevices;

  // Legacy (deprecated)
  final NodeUIModel? node;
  final NodeUIModel? parentNode;
  final List<DeviceUIModel> connectedDevices;

  const UspNodeDetailState({
    this.nodeEntity,
    this.parentNodeEntity,
    this.clientDevices = const [],
    this.node,
    this.parentNode,
    this.connectedDevices = const [],
  });

  factory UspNodeDetailState.empty() => const UspNodeDetailState();

  /// Whether data is available (from either new or legacy source).
  bool get hasData => nodeEntity != null || node != null;

  /// Active device count (prefers new architecture).
  int get activeDeviceCount => clientDevices.isNotEmpty
      ? clientDevices.where((d) => d.isOnline).length
      : connectedDevices.where((d) => d.isActive).length;

  /// Total connected device count.
  int get totalDeviceCount => clientDevices.isNotEmpty
      ? clientDevices.length
      : connectedDevices.length;

  /// Node display name (prefers new architecture).
  String get displayName => nodeEntity?.displayName ?? node?.displayName ?? '';

  /// Whether this is the master node.
  bool get isMaster => nodeEntity?.isMaster ?? node?.isMaster ?? false;

  @override
  List<Object?> get props => [
        nodeEntity,
        parentNodeEntity,
        clientDevices,
        node,
        parentNode,
        connectedDevices,
      ];
}
