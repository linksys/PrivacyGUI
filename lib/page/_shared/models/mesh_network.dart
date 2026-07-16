import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';

/// Top-level container for mesh network topology.
///
/// Single Source of Truth (SSoT) for all network entities.
/// Contains one master node, zero or more slave nodes, and all client devices
/// organized by their parent node.
class MeshNetwork with EquatableMixin, DiagnosticNamed {
  /// The master (gateway) node.
  final MasterNode master;

  /// Slave (extender) nodes.
  final List<SlaveNode> slaves;

  /// Clients not yet assigned to a node (mesh data timing issue).
  ///
  /// When Hosts data arrives before DataElements, clients may not have
  /// parentNodeId. These are stored here until mesh topology is available.
  final List<ClientDevice> unassignedClients;

  MeshNetwork({
    required this.master,
    this.slaves = const [],
    this.unassignedClients = const [],
  });

  // ─── Accessors ───

  /// All mesh nodes (master + slaves).
  List<NodeEntity> get allNodes => [master, ...slaves];

  /// All client devices across all nodes + unassigned.
  List<ClientDevice> get allClients => [
        ...master.connectedClients,
        ...slaves.expand((s) => s.connectedClients),
        ...unassignedClients,
      ];

  /// Total number of client devices.
  int get totalClientCount => allClients.length;

  /// Number of online client devices.
  int get onlineClientCount => allClients.where((c) => c.isOnline).length;

  /// Number of offline client devices.
  int get offlineClientCount => allClients.where((c) => !c.isOnline).length;

  /// Whether this is a mesh network (has slave nodes).
  bool get hasMesh => slaves.isNotEmpty;

  /// Total number of nodes.
  int get nodeCount => 1 + slaves.length;

  // ─── Lookups ───

  /// Find a node by device ID (supports both deviceId and dataElementsId).
  NodeEntity? findNode(String id) {
    final normalized = id.toUpperCase();
    for (final node in allNodes) {
      if (node.deviceId.toUpperCase() == normalized) return node;
      if (node.dataElementsId?.toUpperCase() == normalized) return node;
    }
    return null;
  }

  /// Find a client device by MAC address.
  ClientDevice? findClient(String mac) {
    final normalized = mac.toUpperCase();
    for (final client in allClients) {
      if (client.mac.toUpperCase() == normalized) return client;
      // Also check additional interfaces
      for (final iface in client.additionalInterfaces) {
        if (iface.mac.toUpperCase() == normalized) return client;
      }
    }
    return null;
  }

  /// Find the parent node for a client device.
  NodeEntity? findParentNode(ClientDevice client) {
    if (client.parentNodeId == null) return master;
    return findNode(client.parentNodeId!);
  }

  /// Get all clients connected to a specific node.
  List<ClientDevice> clientsForNode(String nodeId) {
    final node = findNode(nodeId);
    return node?.connectedClients ?? [];
  }

  // ─── Statistics ───

  /// WiFi client count (online only).
  int get wifiClientCount =>
      allClients.where((c) => c.isOnline && c.isWifi).length;

  /// Wired client count (online only).
  int get wiredClientCount =>
      allClients.where((c) => c.isOnline && !c.isWifi).length;

  /// Clients grouped by parent node ID.
  Map<String, List<ClientDevice>> get clientsByNode {
    final result = <String, List<ClientDevice>>{};
    result[master.deviceId] = master.connectedClients;
    for (final slave in slaves) {
      result[slave.deviceId] = slave.connectedClients;
    }
    if (unassignedClients.isNotEmpty) {
      result['_unassigned'] = unassignedClients;
    }
    return result;
  }

  // ─── Copy ───

  MeshNetwork copyWith({
    MasterNode? master,
    List<SlaveNode>? slaves,
    List<ClientDevice>? unassignedClients,
  }) {
    return MeshNetwork(
      master: master ?? this.master,
      slaves: slaves ?? this.slaves,
      unassignedClients: unassignedClients ?? this.unassignedClients,
    );
  }

  @override
  List<Object?> get props => [master, slaves, unassignedClients];

  @override
  String get diagnosticName => 'MeshNetwork';

  @override
  Map<String, Object?> get namedProps => {
        'master': master,
        'slaves': slaves,
        'unassignedClients': unassignedClients,
      };
}
