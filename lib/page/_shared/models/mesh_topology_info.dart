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

  /// Wired client MAC (uppercase) → node device ID, from DataElements
  /// `Interface.{j}.Neighbor.{k}` with `IsIEEE1905=false` (#1688 item 2).
  ///
  /// Holds only MACs exactly **one** node lists. A Wi-Fi STA already in
  /// [clientToNodeMap] is not here: the station entry wins (FWDEV#208 rule 2).
  /// Built by `wiredClientAttribution` in `mesh_topology_builder.dart`.
  final Map<String, String> wiredClientToNodeMap;

  /// Wired client MACs (uppercase) that **two or more** nodes list as a
  /// non-1905 neighbor.
  ///
  /// Kept apart from "listed by no node" because the two mean different
  /// things: no listing is no evidence, and such a client stays on the master
  /// as before; a listing by several nodes is evidence of a node the app cannot
  /// pick, and FWDEV#208 rule 2 leaves it unattributed. A neighbor table is the
  /// node's bridge forwarding table, so a client behind a switch shared by two
  /// nodes is seen through both nodes' uplinks.
  final Set<String> ambiguousWiredClients;

  const MeshTopologyInfo({
    required this.nodes,
    required this.clientToNodeMap,
    this.clientSignalMap = const {},
    this.clientBandSsidMap = const {},
    this.wiredClientToNodeMap = const {},
    this.ambiguousWiredClients = const {},
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
        'wiredClientToNodeMap': wiredClientToNodeMap,
        'ambiguousWiredClients': ambiguousWiredClients,
      };
}
