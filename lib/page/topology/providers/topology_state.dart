// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:privacy_gui/page/topology/_topology.dart';

class TopologyState {
  final RouterTreeNode onlineRoot;
  final RouterTreeNode offlineRoot;
  final int nodesCount;

  const TopologyState({
    required this.onlineRoot,
    required this.offlineRoot,
    required this.nodesCount,
  });

  TopologyState copyWith({
    RouterTreeNode? onlineRoot,
    RouterTreeNode? offlineRoot,
    RouterTreeNode? treeRoot,
    int? nodesCount,
  }) {
    return TopologyState(
      onlineRoot: onlineRoot ?? this.onlineRoot,
      offlineRoot: offlineRoot ?? this.offlineRoot,
      nodesCount: nodesCount ?? this.nodesCount,
    );
  }
}
