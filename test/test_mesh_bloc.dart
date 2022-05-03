import 'package:bloc_test/bloc_test.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';
import 'package:moab_poc/page/mesh/bloc.dart';
import 'package:moab_poc/page/mesh/event.dart';
import 'package:moab_poc/page/mesh/state.dart';
import 'package:test/test.dart';

void main() {
  const device = Device(address: '192.168.100.1', port: '80');
  const identity = Identity(username: 'root', password: 'Belkin123');
  final repo = LocalDeviceRepository(OpenWRTClient(device));
  group('test mesh bloc', () {
    late MeshBloc meshBloc;
    setUp((){
      meshBloc = MeshBloc(repo: repo);
    });
    test('test mesh bloc initial state', () {
      expect(meshBloc.state.runtimeType, MeshInitial);
    });
    blocTest('test mesh bloc start to mesh',
        build: () => meshBloc,
        act: (MeshBloc bloc) => bloc.add(const StartMesh()),
        expect: () => [isA<MeshQRCodeScanning>()]);
    blocTest('test mesh bloc start to loading',
        build: () => meshBloc,
        act: (MeshBloc bloc) => bloc.add(const MeshStatusChange(state: MeshLoading())),
        expect: () => [isA<MeshLoading>()]);
    blocTest('test mesh bloc start to complete',
        build: () => meshBloc,
        act: (MeshBloc bloc) => bloc.add(const MeshStatusChange(state: MeshComplete())),
        expect: () => [isA<MeshComplete>()]);
  });
}
