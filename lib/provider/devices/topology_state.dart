import 'package:linksys_app/page/dashboard/view/topology/topology_node.dart';

class TopologyState {
  final TopologyNode root;
  final String? selectedDeviceId;

  const TopologyState({
    required this.root,
    this.selectedDeviceId,
  });

  TopologyState copyWith({
    TopologyNode? root,
    String? selectedDeviceId,
  }) {
    return TopologyState(
      root: root ?? this.root,
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}
