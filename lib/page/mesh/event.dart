import 'package:flutter/material.dart';
import 'package:moab_poc/page/mesh/state.dart';

@immutable
abstract class MeshEvent {
  const MeshEvent();
}

class StartMesh extends MeshEvent {
  const StartMesh() : super();
}

class SyncDPPWithChild extends MeshEvent {
  const SyncDPPWithChild({required this.dpp}) : super();
  final String dpp;
}

class MeshStatusChange extends MeshEvent {
  const MeshStatusChange({required this.state}) : super();
  final MeshState state;
}
