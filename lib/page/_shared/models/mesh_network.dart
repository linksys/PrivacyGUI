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

  /// Clients that belong to the network but to no node.
  ///
  /// Two populations share this bucket. One is transient: when Hosts data
  /// arrives before DataElements, clients have no parentNodeId yet and land here
  /// until the topology shows up. The other is not — a client whose parent
  /// genuinely cannot be resolved on a mesh stays here for as long as that is
  /// true, and carries [ClientDevice.isUnattributed] to say so, because
  /// attributing it to the master would be a wrong answer rather than a late one
  /// (issue #1439). Read the flag to tell the two apart.
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

  /// The slave [deviceId] names and every slave behind it, farthest first.
  ///
  /// "Behind" is the backhaul parent chain: a slave is behind the target when
  /// walking `backhaul.parentNodeId` upward from it reaches the target. A node
  /// command acts on the node that receives it and not on the nodes behind it
  /// (FWDEV#202), and a node that restarts cuts off everything behind it, so
  /// a caller rebooting or resetting a slave sends one call per node in this
  /// order.
  NodesBehind nodesBehind(String deviceId) {
    final target = findNode(deviceId);
    if (target is! SlaveNode) return const NodesBehind([], mayMissNodes: false);

    final byId = {
      for (final s in slaves) ...{
        s.deviceId.toUpperCase(): s,
        if (s.dataElementsId != null) s.dataElementsId!.toUpperCase(): s,
      },
    };
    final targetId = target.deviceId.toUpperCase();

    final behind = <(int, SlaveNode)>[];
    var mayMissNodes = false;
    for (final slave in slaves) {
      final visited = <SlaveNode>{};
      SlaveNode? current = slave;
      while (true) {
        if (current!.deviceId.toUpperCase() == targetId) {
          behind.add((visited.length, slave));
          break;
        }
        final parent = current.backhaul.parentNodeId;
        // A chain that ends anywhere but the master says nothing about where
        // this slave sits: no parent reported, a parent not in the list, or a
        // cycle (firmware can report one; backhaul_parent_graph.dart breaks it
        // for the topology, but this walk runs on the raw parents).
        if (parent == null || !visited.add(current)) {
          mayMissNodes = true;
          break;
        }
        current = byId[parent.toUpperCase()];
        if (current == null) {
          if (findNode(parent) is! MasterNode) mayMissNodes = true;
          break;
        }
      }
    }
    behind.sort((x, y) => y.$1.compareTo(x.$1));
    return NodesBehind(
      [for (final (_, node) in behind) node],
      mayMissNodes: mayMissNodes,
    );
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
  ///
  /// Returns null for an [ClientDevice.isUnattributed] client: its parent could
  /// not be resolved, so there is no node to name, and answering `master` here
  /// would reintroduce the false attribution the builder now avoids (issue
  /// #1439). A null [ClientDevice.parentNodeId] on a client that is *not*
  /// flagged still means the gateway — that is the ordinary non-mesh case.
  NodeEntity? findParentNode(ClientDevice client) {
    if (client.isUnattributed) return null;
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

/// The answer to [MeshNetwork.nodesBehind].
class NodesBehind extends Equatable {
  /// The target and every slave behind it, farthest first; the target is last.
  /// Empty when the id names no slave.
  final List<SlaveNode> nodes;

  /// Whether a slave may sit behind the target without being in [nodes].
  final bool mayMissNodes;

  const NodesBehind(this.nodes, {required this.mayMissNodes});

  @override
  List<Object?> get props => [nodes, mayMissNodes];
}
