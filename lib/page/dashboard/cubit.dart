import 'package:bloc/bloc.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';

import 'state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState.initial());

  Future<String> getSSID(DeviceRepository repository) async {
    WirelessInfoList? wifiInfo = await repository.getWirelessInfo();
    emit(DashboardState.ssidFetched(wifiInfo.children.first.ssid));
    return wifiInfo.children.first.ssid;
  }

  @override
  void onChange(Change<DashboardState> change) {
    super.onChange(change);
    print(change);
  }
}
