// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:linksys_app/core/jnap/models/device.dart';

class AddNodesState extends Equatable {
  final List<RawDevice>? nodesSnapshot;
  final List<RawDevice>? addedNodes;

  const AddNodesState({
    this.nodesSnapshot,
    this.addedNodes,
  });

  @override
  List<Object?> get props => [nodesSnapshot, addedNodes];

  AddNodesState copyWith({
    List<RawDevice>? nodesSnapshot,
    List<RawDevice>? addedNodes,
  }) {
    return AddNodesState(
      nodesSnapshot: nodesSnapshot ?? this.nodesSnapshot,
      addedNodes: addedNodes ?? this.addedNodes,
    );
  }
}
