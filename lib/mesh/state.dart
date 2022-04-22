import 'cubit.dart';

class MeshState {
  const MeshState._({this.status = MeshStatus.initial});

  final MeshStatus status;

  const MeshState.initial(): this._(status: MeshStatus.initial);
  const MeshState.qrcodeScanning(): this._(status: MeshStatus.qrcodeScanning);
  const MeshState.loading(): this._(status: MeshStatus.loading);
  const MeshState.complete(): this._(status: MeshStatus.complete);
}
