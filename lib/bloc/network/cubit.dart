import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/mixin/stream_mixin.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/model/router/network.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/core_extension.dart';
import 'package:linksys_moab/repository/router/router_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/repository/router/wireless_ap_extension.dart';
import 'package:linksys_moab/util/logger.dart';

class NetworkCubit extends Cubit<NetworkState> with StateStreamRegister {
  NetworkCubit({required RouterRepository routerRepository})
      : _routerRepository = routerRepository,
        super(const NetworkState()) {
    shareStream = stream;
    register(_routerRepository);
  }

  final RouterRepository _routerRepository;

  @override
  Future<void> close() async {
    unregisterAll();
    super.close();
  }

  Future<RouterDeviceInfo> getDeviceInfo() async {
    final result = await _routerRepository.getDeviceInfo();
    final routerDeviceInfo = RouterDeviceInfo.fromJson(result.output);
    buildBetterActions(routerDeviceInfo.services);
    emit(state.copyWith(
        selected: state.selected?.copyWith(deviceInfo: routerDeviceInfo) ??
            MoabNetwork(
                id: routerDeviceInfo.serialNumber,
                deviceInfo: routerDeviceInfo)));
    return routerDeviceInfo;
  }

  Future<RouterWANStatus> getWANStatus() async {
    final result = await _routerRepository.getWANStatus();
    final wanStatus = RouterWANStatus.fromJson(result.output);
    emit(state.copyWith(
        selected: state.selected!.copyWith(wanStatus: wanStatus)));
    return wanStatus;
  }

  Future<List<RouterRadioInfo>> getRadioInfo() async {
    final result = await _routerRepository.getRadioInfo();
    final radioInfo = List.from(result.output['radios']).map((e) => RouterRadioInfo.fromJson(e)).toList();
    emit(state.copyWith(selected: state.selected!.copyWith(radioInfo: radioInfo)));
    return radioInfo;
  }

  createAdminPassword(String password, String hint) async {
    await _routerRepository.createAdminPassword('admin', hint);
  }

  Future pollingData() async {
    logger.d('start polling data');
    final result = await _routerRepository.pollingData();
    logger.d('finish polling data');
  }
}
