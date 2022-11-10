import 'package:equatable/equatable.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_node.dart';

class TopologyState extends Equatable {
  final TopologyNode rootNode;

  const TopologyState({
    required this.rootNode
  });

  TopologyState copyWith({
    TopologyNode? rootNode,
  }) {
    return TopologyState(
      rootNode: rootNode ?? this.rootNode,
    );
  }

  @override
  List<Object?> get props => [
    rootNode,
  ];
}