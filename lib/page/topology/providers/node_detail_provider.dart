import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

/// Computed provider — looks up a single node + its connected devices by deviceId.
///
/// Uses [MeshNetwork] for direct node lookup and pre-organized connected clients.
final uspNodeDetailProvider =
    Provider.family<UspNodeDetailState, String>((ref, deviceId) {
  final data = ref.watch(devicesDataProvider).valueOrNull;
  final meshNetwork = data?.meshNetwork;

  if (meshNetwork == null) return UspNodeDetailState.empty();

  final node = meshNetwork.findNode(deviceId);
  if (node == null) return UspNodeDetailState.empty();

  // Look up parent node for slaves
  NodeEntity? parentNode;
  if (node is SlaveNode && node.backhaul.parentNodeId != null) {
    parentNode = meshNetwork.findNode(node.backhaul.parentNodeId!);
  }

  return UspNodeDetailState(
    node: node,
    parentNode: parentNode,
    connectedClients: node.connectedClients,
  );
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UspNodeDetailState extends Equatable {
  final NodeEntity? node;
  final NodeEntity? parentNode;
  final List<ClientDevice> connectedClients;

  const UspNodeDetailState({
    this.node,
    this.parentNode,
    this.connectedClients = const [],
  });

  factory UspNodeDetailState.empty() => const UspNodeDetailState();

  /// Whether data is available.
  bool get hasData => node != null;

  /// Active (online) client count.
  int get activeClientCount => connectedClients.where((c) => c.isOnline).length;

  /// Total connected client count.
  int get totalClientCount => connectedClients.length;

  /// Node display name.
  String get displayName => node?.displayName ?? '';

  /// Whether this is the master node.
  bool get isMaster => node?.isMaster ?? false;

  @override
  List<Object?> get props => [node, parentNode, connectedClients];
}
