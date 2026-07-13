import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';

/// Result of mesh topology fetch from DataElements.
///
/// Contains mesh nodes and client-to-node mapping for determining
/// which mesh node each client device is connected to.
///
/// NOTE: The [nodes] list contains NodeEntity instances with empty
/// [connectedClients] — client assignment happens in [MeshNetworkBuilder].
class MeshTopologyInfo extends Equatable with DiagnosticLoggable {
  /// Mesh nodes discovered via DataElements.
  final List<NodeEntity> nodes;

  /// Client MAC (uppercase) → node device ID mapping.
  final Map<String, String> clientToNodeMap;

  /// Client MAC (uppercase) → signal strength (RSSI dBm).
  ///
  /// Populated from DataElements STA.SignalStrength for clients on ALL nodes,
  /// including child nodes. Used as fallback when WifiClients doesn't have
  /// signal data (WifiClients only covers master node clients).
  final Map<String, int> clientSignalMap;

  /// Client MAC (uppercase) → (band, ssid) from DataElements BSS.
  ///
  /// Populated from DataElements BSS for clients on ALL nodes,
  /// including child nodes. Used as fallback when connectionDetailMap
  /// doesn't have band/SSID data (connectionDetailMap only covers master clients).
  final Map<String, ({String band, String ssid})> clientBandSsidMap;

  const MeshTopologyInfo({
    required this.nodes,
    required this.clientToNodeMap,
    this.clientSignalMap = const {},
    this.clientBandSsidMap = const {},
  });

  /// Empty result — used as fallback when DataElements is not supported.
  static const empty = MeshTopologyInfo(
    nodes: [],
    clientToNodeMap: {},
    clientSignalMap: {},
    clientBandSsidMap: {},
  );

  bool get isEmpty => nodes.isEmpty;
  bool get isNotEmpty => nodes.isNotEmpty;

  @override
  String get diagnosticName => 'MeshTopologyInfo';

  @override
  Map<String, Object?> get namedProps => {
        'nodes': nodes,
        'clientToNodeMap': clientToNodeMap,
        'clientSignalMap': clientSignalMap,
        'clientBandSsidMap': clientBandSsidMap,
      };
}
