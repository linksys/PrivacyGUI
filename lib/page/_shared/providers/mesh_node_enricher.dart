import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';

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

/// Fetches mesh node topology via codegen [DataElementsNetwork].
///
/// Delegates all nested multi-instance parsing
/// (Device.{i} → Radio.{j} → BSS.{k} → STA.{l})
/// to the generated [DataElementsNetwork.fetch], then transforms the tree
/// into a flat [MeshTopologyInfo] with client→node mapping.
///
/// Returns [MeshTopologyInfo.empty] if the router doesn't support DataElements
/// or the subtree is empty (non-mesh / single router).
Future<MeshTopologyInfo> fetchMeshNodes(UspService client) async {
  try {
    // DataElements uses 9 deep-wildcard paths that can be slow on OBUSPA.
    // Domain-ready gating (dashboardDomainReadyProvider) ensures lighter
    // queries complete before polling providers start.
    // TODO: Add codegen priority support so fetch() can pass RequestPriority.
    final network = await DataElementsNetwork.fetch(client);
    if (network.items.isEmpty) {
      logger
          .d('[USP][Dashboard]DataElements empty — not a mesh or unsupported');
      return MeshTopologyInfo.empty;
    }
    return _buildTopologyInfo(network);
  } catch (e) {
    logger.d('[USP][Dashboard]DataElements not supported or fetch failed: $e');
    return MeshTopologyInfo.empty;
  }
}

/// Transforms the codegen tree into a flat [MeshTopologyInfo].
///
/// Walks: MeshNode → MeshRadio → MeshBss → MeshStation to build
/// the client MAC → node device ID mapping.
MeshTopologyInfo _buildTopologyInfo(DataElementsNetwork network) {
  final nodes = <MeshNodeInfo>[];
  final clientToNodeMap = <String, String>{};

  for (final node in network.items) {
    // Device.{i}.ID may be empty on some USP systems — fall back to
    // the instance path which is always unique and present.
    final rawId = node.id.trim().toUpperCase();
    final nodeDeviceId = rawId.isNotEmpty ? rawId : node.instancePath;

    // Walk radios → BSS → STA to build client→node map
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
