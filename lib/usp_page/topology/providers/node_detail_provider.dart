import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/topology/models/node_ui_model.dart';

/// Computed provider — looks up a single node + its connected devices by deviceId.
final uspNodeDetailProvider =
    Provider.family<UspNodeDetailState, String>((ref, deviceId) {
  final state = ref.watch(uspDashboardProvider).valueOrNull;
  if (state == null) return UspNodeDetailState.empty();

  final node = state.nodeModels
      .where((n) => n.deviceId.toUpperCase() == deviceId.toUpperCase())
      .firstOrNull;

  // For non-mesh routers the synthetic gateway uses deviceId 'gateway',
  // and devices have parentNodeId == null (no DataElements mapping).
  // Treat null parentNodeId as "connected to gateway".
  final isGatewayLookup = deviceId.toUpperCase() == 'GATEWAY';
  final connectedDevices = state.deviceModels
      .where((d) =>
          (d.parentNodeId != null &&
              d.parentNodeId!.toUpperCase() == deviceId.toUpperCase()) ||
          (isGatewayLookup && d.parentNodeId == null))
      .toList();

  return UspNodeDetailState(
    node: node,
    connectedDevices: connectedDevices,
  );
});

class UspNodeDetailState extends Equatable {
  final NodeUIModel? node;
  final List<DeviceUIModel> connectedDevices;

  const UspNodeDetailState({
    this.node,
    this.connectedDevices = const [],
  });

  factory UspNodeDetailState.empty() => const UspNodeDetailState();

  int get activeDeviceCount => connectedDevices.where((d) => d.isActive).length;

  @override
  List<Object?> get props => [node, connectedDevices];
}
