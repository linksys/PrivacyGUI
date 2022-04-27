import 'package:bloc/bloc.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';

import 'state.dart';

enum MeshStatus { initial, qrcodeScanning, loading, complete }

class MeshCubit extends Cubit<MeshState> {
  MeshCubit({required DeviceRepository repo})
      : _repository = repo,
        super(const MeshState.initial());

  final DeviceRepository _repository;

  void meshStatusChange(MeshStatus status) {
    switch (status) {
      case MeshStatus.initial:
        emit(const MeshState.initial());
        break;
      case MeshStatus.qrcodeScanning:
        emit(const MeshState.qrcodeScanning());
        break;
      case MeshStatus.loading:
        emit(const MeshState.loading());
        break;
      case MeshStatus.complete:
        emit(const MeshState.complete());
        break;
      default:
        emit(const MeshState.initial());
    }
  }

  void startMesh() {
    emit(const MeshState.qrcodeScanning());
  }

  Future<void> syncDPPWithChild(String dpp) async {
    //TODO send DPP to child by repository
    emit(const MeshState.loading());

    _repository.sendBootstrap(dpp);
    await Future.delayed(const Duration(seconds: 180), () {
      emit(const MeshState.complete());
    });
  }

  @override
  void onChange(Change<MeshState> change) {
    super.onChange(change);
    print(change);
  }
}
