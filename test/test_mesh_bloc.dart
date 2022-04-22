import 'package:moab_poc/mesh/mesh.dart';
import 'package:test/test.dart';

void main() {
  group('test mesh bloc', () {
    test('test mesh', () async {
      MeshCubit cubit = MeshCubit();
      expect(cubit.state, const MeshState.initial());
      cubit.startMesh();
      expect(cubit.state, const MeshState.qrcodeScanning());
      cubit.meshStatusChange(MeshStatus.loading);
      expect(cubit.state, const MeshState.loading());
      cubit.meshStatusChange(MeshStatus.complete);
      expect(cubit.state, const MeshState.complete());
    });
  });
}