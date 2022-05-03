import 'package:bloc/bloc.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';

import 'state.dart';


class MeshCubit extends Cubit<MeshState> {
  MeshCubit({required DeviceRepository repo})
      : _repository = repo,
        super(const MeshInitial());

  final DeviceRepository _repository;

  void meshStatusChange(MeshState status) {
    switch (status.runtimeType) {
      case MeshInitial:
        emit(const MeshInitial());
        break;
      case MeshQRCodeScanning:
        emit(const MeshQRCodeScanning());
        break;
      case MeshLoading:
        emit(const MeshLoading());
        break;
      case MeshComplete:
        emit(const MeshComplete());
        break;
      default:
        emit(const MeshInitial());
    }
  }

  void startMesh() {
    emit(const MeshQRCodeScanning());
  }

  Future<void> syncDPPWithChild(String dpp) async {
    //TODO send DPP to child by repository
    emit(const MeshLoading());

    _repository.sendBootstrap(dpp);
    await Future.delayed(const Duration(seconds: 180), () {
      emit(const MeshComplete());
    });
  }

  @override
  void onChange(Change<MeshState> change) {
    super.onChange(change);
    print(change);
  }
}
