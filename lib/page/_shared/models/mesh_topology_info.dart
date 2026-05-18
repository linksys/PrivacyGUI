import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

/// Result of mesh topology fetch from DataElements.
///
/// Contains mesh nodes and client-to-node mapping for determining
/// which mesh node each client device is connected to.
class MeshTopologyInfo extends Equatable {
  /// Mesh nodes discovered via DataElements.
  final List<NodeUIModel> nodes;

  /// Client MAC (uppercase) → node device ID mapping.
  final Map<String, String> clientToNodeMap;

  const MeshTopologyInfo({
    required this.nodes,
    required this.clientToNodeMap,
  });

  /// Empty result — used as fallback when DataElements is not supported.
  static const empty = MeshTopologyInfo(nodes: [], clientToNodeMap: {});

  bool get isEmpty => nodes.isEmpty;
  bool get isNotEmpty => nodes.isNotEmpty;

  @override
  List<Object?> get props => [nodes, clientToNodeMap];
}
