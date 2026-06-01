import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

/// Computed provider — looks up a single node + its connected devices by deviceId.
final uspNodeDetailProvider =
    Provider.family<UspNodeDetailState, String>((ref, deviceId) {
  final data = ref.watch(devicesDataProvider).valueOrNull;
  if (data == null) return UspNodeDetailState.empty();

  final node = data.nodeModels
      .where((n) => n.deviceId.toUpperCase() == deviceId.toUpperCase())
      .firstOrNull;

  if (node == null) return UspNodeDetailState.empty();

  // Look up parent node using backhaulParentDeviceId (parent's Device ID)
  NodeUIModel? parentNode;
  if (node.backhaulParentDeviceId != null &&
      node.backhaulParentDeviceId!.isNotEmpty) {
    final parentId =
        node.backhaulParentDeviceId!.toUpperCase().replaceAll(':', '');
    parentNode = data.nodeModels.where((n) {
      final nodeId = n.deviceId.toUpperCase().replaceAll(':', '');
      final nodeDeId = n.dataElementsId?.toUpperCase().replaceAll(':', '');
      return nodeId == parentId || nodeDeId == parentId;
    }).firstOrNull;
  }

  // For non-mesh routers the synthetic gateway uses deviceId 'gateway',
  // and devices have parentNodeId == null (no DataElements mapping).
  // Treat null parentNodeId as "connected to gateway".
  final isGatewayLookup = deviceId.toUpperCase() == 'GATEWAY';
  final connectedDevices = data.deviceModels
      .where((d) =>
          (d.parentNodeId != null &&
              d.parentNodeId!.toUpperCase() == deviceId.toUpperCase()) ||
          (isGatewayLookup && d.parentNodeId == null))
      .toList();

  return UspNodeDetailState(
    node: node,
    parentNode: parentNode,
    connectedDevices: connectedDevices,
  );
});

class UspNodeDetailState extends Equatable {
  final NodeUIModel? node;
  final NodeUIModel? parentNode;
  final List<DeviceUIModel> connectedDevices;

  const UspNodeDetailState({
    this.node,
    this.parentNode,
    this.connectedDevices = const [],
  });

  factory UspNodeDetailState.empty() => const UspNodeDetailState();

  int get activeDeviceCount => connectedDevices.where((d) => d.isActive).length;

  @override
  List<Object?> get props => [node, parentNode, connectedDevices];
}
