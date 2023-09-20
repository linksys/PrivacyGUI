import 'package:linksys_app/page/dashboard/view/topology/topology_model.dart';

class TopologyState {
  final RouterTreeNode onlineRoot;
  final RouterTreeNode offlineRoot;

  const TopologyState({
    required this.onlineRoot,
    required this.offlineRoot,
  });

  TopologyState copyWith({
    RouterTreeNode? onlineRoot,
    RouterTreeNode? offlineRoot,
    String? selectedDeviceId,
  }) {
    return TopologyState(
      onlineRoot: onlineRoot ?? this.onlineRoot,
      offlineRoot: offlineRoot ?? this.offlineRoot,
    );
  }
}
