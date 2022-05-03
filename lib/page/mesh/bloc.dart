import 'package:bloc/bloc.dart';
import 'event.dart';
import 'state.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';

class MeshBloc extends Bloc<MeshEvent, MeshState> {
  final DeviceRepository _repository;

  MeshBloc({required DeviceRepository repo})
      : _repository = repo,
        super(const MeshInitial()) {
    on<StartMesh>(_startMesh);
    on<SyncDPPWithChild>(_syncDPP);
    on<MeshStatusChange>(_meshStatusChange);
  }

  void _startMesh(StartMesh event, Emitter<MeshState> emit) {
    emit(const MeshQRCodeScanning());
  }

  void _syncDPP(SyncDPPWithChild event, Emitter<MeshState> emit) async {
    emit(const MeshLoading());
    _repository.sendBootstrap(event.dpp);
    await Future.delayed(const Duration(seconds: 180), () {
      emit(const MeshComplete());
    });
  }

  void _meshStatusChange(MeshStatusChange event, Emitter<MeshState> emit) {
    switch (event.state.runtimeType) {
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
  
  @override
  void onTransition(Transition<MeshEvent, MeshState> transition) {
    super.onTransition(transition);
    print(transition);
  }
}
