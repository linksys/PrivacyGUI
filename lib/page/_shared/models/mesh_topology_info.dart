/// Info about a mesh node — lightweight view of codegen's MeshNode.
///
/// Kept as separate type to avoid naming conflict with ui_kit's MeshNode
/// used by [AppTopology] in the network topology card.
class MeshNodeInfo {
  final String instancePath;
  final String deviceId; // Device.{i}.ID (typically MAC of the node)
  final String model; // ManufacturerModel
  final String manufacturer; // Manufacturer
  final String serialNumber; // SerialNumber
  final String softwareVersion; // SoftwareVersion

  const MeshNodeInfo({
    required this.instancePath,
    required this.deviceId,
    required this.model,
    this.manufacturer = '',
    this.serialNumber = '',
    this.softwareVersion = '',
  });
}

/// Result of mesh node enrichment.
class MeshTopologyInfo {
  /// All mesh nodes discovered via DataElements.
  final List<MeshNodeInfo> nodes;

  /// Client MAC (uppercase) → node device ID that the client is connected to.
  final Map<String, String> clientToNodeMap;

  const MeshTopologyInfo({
    required this.nodes,
    required this.clientToNodeMap,
  });

  /// Empty result — used as fallback when DataElements is not supported.
  static const empty = MeshTopologyInfo(nodes: [], clientToNodeMap: {});

  bool get isEmpty => nodes.isEmpty;
  bool get isNotEmpty => nodes.isNotEmpty;
}
