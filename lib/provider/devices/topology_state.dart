import 'package:linksys_app/page/dashboard/view/topology/topology_model.dart';

class TopologyState {
  final RouterTreeNode root;
  final String? selectedDeviceId;

  const TopologyState({
    required this.root,
    this.selectedDeviceId,
  });

  TopologyState copyWith({
    RouterTreeNode? root,
    String? selectedDeviceId,
  }) {
    return TopologyState(
      root: root ?? this.root,
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}
