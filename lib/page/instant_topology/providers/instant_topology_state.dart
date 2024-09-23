// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';

class InstantTopologyState {
  final RouterTreeNode root;

  const InstantTopologyState({
    required this.root,
  });

  InstantTopologyState copyWith({
    RouterTreeNode? root,
  }) {
    return InstantTopologyState(
      root: root ?? this.root,
    );
  }
}
