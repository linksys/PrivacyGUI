import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';

/// Adapter to convert PrivacyGUI topology data to ui_kit MeshTopology format.
///
/// This adapter bridges the existing TopologyModel/RouterTreeNode structure
/// with ui_kit's MeshTopology/MeshNode requirements, enabling seamless
/// migration to ui_kit's topology visualization system.
///
/// Usage:
/// ```dart
/// final meshTopology = TopologyAdapter.convert(routerTreeNodes);
/// AppTopology(
///   topology: meshTopology,
///   onNodeTap: (nodeId) => handleNodeTap(nodeId),
/// )
/// ```
class TopologyAdapter {
  TopologyAdapter._();

  /// Convert RouterTreeNode list to ui_kit MeshTopology.
  ///
  /// Takes the root nodes from instantTopologyProvider and converts them
  /// to a MeshTopology structure that ui_kit can render.
  static MeshTopology convert(List<RouterTreeNode> rootNodes) {
    if (rootNodes.isEmpty) {
      return MeshTopology.empty();
    }

    final nodes = <MeshNode>[];
    final links = <MeshLink>[];

    // Convert nodes recursively
    for (final rootNode in rootNodes) {
      _convertNode(rootNode, null, nodes, links);
    }

    return MeshTopology(
      nodes: nodes,
      links: links,
      lastUpdated: DateTime.now(),
    );
  }

  /// Recursively convert a RouterTreeNode and its children to MeshNodes.
  static void _convertNode(
    RouterTreeNode treeNode,
    String? parentId,
    List<MeshNode> nodes,
    List<MeshLink> links,
  ) {
    final topologyModel = treeNode.data;
    final meshNode = _createMeshNode(topologyModel, parentId, treeNode.children);

    nodes.add(meshNode);

    // Create link to parent if exists
    if (parentId != null) {
      links.add(MeshLink(
        sourceId: parentId,
        targetId: meshNode.id,
        connectionType: topologyModel.isWiredConnection ? ConnectionType.ethernet : ConnectionType.wifi,
        rssi: topologyModel.isWiredConnection ? null : _mapToRSSI(topologyModel.signalStrength),
      ));
    }

    // Process children recursively
    for (final child in treeNode.children) {
      _convertNode(child, meshNode.id, nodes, links);
    }
  }

  /// Create a MeshNode from TopologyModel data.
  static MeshNode _createMeshNode(
    TopologyModel topology,
    String? parentId,
    List<RouterTreeNode> children,
  ) {
    return MeshNode(
      id: topology.deviceId.isNotEmpty ? topology.deviceId : _generateId(topology),
      name: topology.location.isNotEmpty ? topology.location : 'Unknown Device',
      type: _determineNodeType(topology, children),
      status: _mapNodeStatus(topology),
      parentId: parentId,
      load: _calculateLoad(topology),
      iconData: _mapIcon(topology.icon),
      deviceCategory: topology.isRouter ? 'router' : 'device',
    );
  }

  /// Determine MeshNodeType from TopologyModel and children.
  static MeshNodeType _determineNodeType(TopologyModel topology, List<RouterTreeNode> children) {
    if (topology.isRouter && topology.isMaster) {
      return MeshNodeType.gateway;
    }

    if (topology.isRouter || children.isNotEmpty) {
      return MeshNodeType.extender;
    }

    return MeshNodeType.client;
  }

  /// Map TopologyModel online status to MeshNodeStatus.
  static MeshNodeStatus _mapNodeStatus(TopologyModel topology) {
    if (!topology.isOnline) {
      return MeshNodeStatus.offline;
    }

    // Consider high load scenarios (if we can determine from topology data)
    // For now, default to online
    return MeshNodeStatus.online;
  }

  /// Calculate load percentage for extender nodes.
  static double _calculateLoad(TopologyModel topology) {
    if (!topology.isRouter) return 0.0;

    // Use connected device count as a proxy for load
    // Assume max 20 devices for 100% load (arbitrary but reasonable)
    const maxDevices = 20;
    return (topology.connectedDeviceCount / maxDevices).clamp(0.0, 1.0);
  }

  /// Map signal strength percentage (0-100) to RSSI (dBm).
  /// This is an approximation since we don't have actual RSSI values.
  static int _mapToRSSI(int signalStrength) {
    // Convert percentage to approximate RSSI values
    // 100% = -30 dBm (excellent)
    // 80% = -50 dBm (strong)
    // 60% = -60 dBm (medium)
    // 40% = -70 dBm (weak)
    // 20% = -80 dBm (very weak)
    // 0% = -90 dBm (poor)

    if (signalStrength >= 80) return -40;
    if (signalStrength >= 60) return -55;
    if (signalStrength >= 40) return -65;
    if (signalStrength >= 20) return -75;
    return -85;
  }

  /// Map icon string to IconData.
  ///
  /// This mapping should match the icons used in the existing system.
  /// Add more mappings as needed based on TopologyModel.icon values.
  static IconData? _mapIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'router':
      case 'genericdevice':
        return Icons.router;
      case 'laptop':
      case 'computer':
        return Icons.laptop;
      case 'phone':
      case 'smartphone':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet;
      case 'tv':
      case 'television':
        return Icons.tv;
      case 'gamedevice':
      case 'gaming':
        return Icons.gamepad;
      case 'camera':
        return Icons.camera_alt;
      case 'printer':
        return Icons.print;
      case 'speaker':
        return Icons.speaker;
      case 'smartdevice':
      case 'iot':
        return Icons.devices_other;
      case 'extender':
      case 'repeater':
        return Icons.wifi_tethering;
      default:
        return Icons.devices; // Default fallback
    }
  }

  /// Generate a unique ID for nodes without deviceId.
  static String _generateId(TopologyModel topology) {
    if (topology.macAddress.isNotEmpty) {
      return topology.macAddress;
    }

    if (topology.location.isNotEmpty) {
      return 'device_${topology.location.hashCode}';
    }

    return 'device_${topology.hashCode}';
  }

  /// Get node ID from RouterTreeNode for callbacks.
  ///
  /// This helper method extracts the node ID that should be used
  /// in onNodeTap callbacks, maintaining compatibility with existing logic.
  static String getNodeId(RouterTreeNode treeNode) {
    final topology = treeNode.data;

    if (topology.deviceId.isNotEmpty) {
      return topology.deviceId;
    }

    return _generateId(topology);
  }

  /// Create a callback wrapper that converts nodeId to the original format.
  ///
  /// This helps maintain compatibility with existing onTap logic that
  /// expects to work with TopologyModel data.
  static void Function(String nodeId)? wrapNodeTapCallback(
    List<RouterTreeNode> originalNodes,
    void Function(RouterTreeNode node)? originalCallback,
  ) {
    if (originalCallback == null) return null;

    return (String nodeId) {
      // Find the original node by ID
      final flatNodes = <RouterTreeNode>[];
      for (final rootNode in originalNodes) {
        flatNodes.addAll(rootNode.toFlatList());
      }

      final targetNode = flatNodes.cast<RouterTreeNode?>().firstWhere(
        (node) => node != null && getNodeId(node) == nodeId,
        orElse: () => null,
      );

      if (targetNode != null) {
        originalCallback(targetNode);
      }
    };
  }
}