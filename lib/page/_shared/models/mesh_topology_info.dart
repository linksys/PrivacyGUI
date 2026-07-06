import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

/// Result of mesh topology fetch from DataElements.
///
/// Contains mesh nodes and client-to-node mapping for determining
/// which mesh node each client device is connected to.
class MeshTopologyInfo extends Equatable with DiagnosticLoggable {
  /// Mesh nodes discovered via DataElements.
  final List<NodeUIModel> nodes;

  /// Client MAC (uppercase) → node device ID mapping.
  final Map<String, String> clientToNodeMap;

  /// Client MAC (uppercase) → signal strength (RSSI dBm).
  ///
  /// Populated from DataElements STA.SignalStrength for clients on ALL nodes,
  /// including child nodes. Used as fallback when WifiClients doesn't have
  /// signal data (WifiClients only covers master node clients).
  final Map<String, int> clientSignalMap;

  const MeshTopologyInfo({
    required this.nodes,
    required this.clientToNodeMap,
    this.clientSignalMap = const {},
  });

  /// Empty result — used as fallback when DataElements is not supported.
  static const empty = MeshTopologyInfo(
    nodes: [],
    clientToNodeMap: {},
    clientSignalMap: {},
  );

  bool get isEmpty => nodes.isEmpty;
  bool get isNotEmpty => nodes.isNotEmpty;

  @override
  List<Object?> get props => [nodes, clientToNodeMap, clientSignalMap];

  @override
  String get diagnosticName => 'MeshTopologyInfo';

  @override
  Map<String, Object?> get namedProps => {
        'nodes': nodes,
        'clientToNodeMap': clientToNodeMap,
        'clientSignalMap': clientSignalMap,
      };
}
