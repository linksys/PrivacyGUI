import 'package:bloc/bloc.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';
import 'package:moab_poc/util/connectivity.dart';

import 'state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required DeviceRepository repo})
      : _repository = repo,
        super(const DashboardState.initial());

  final DeviceRepository _repository;

  Future<String> getSSID() async {
    // WirelessInfoList? wifiInfo = await _repository.getWirelessInfo();
    final ssid = ConnectivityUtil.info.ssid;
    emit(DashboardState.ssidFetched(ssid));
    return ssid;
  }

  @override
  void onChange(Change<DashboardState> change) {
    super.onChange(change);
    print(change);
  }
}
