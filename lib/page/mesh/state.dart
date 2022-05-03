import 'package:flutter/material.dart';

@immutable
abstract class MeshState{
  const MeshState();
}

class MeshInitial extends MeshState {
  const MeshInitial(): super();
}

class MeshQRCodeScanning extends MeshState {
  const MeshQRCodeScanning(): super();
}

class MeshLoading extends MeshState {
  const MeshLoading(): super();
}

class MeshComplete extends MeshState {
  const MeshComplete(): super();
}
