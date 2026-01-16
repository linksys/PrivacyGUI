import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/device_info_provider.dart';
import 'package:privacy_gui/core/data/providers/ethernet_ports_provider.dart';
import 'package:privacy_gui/core/data/providers/system_stats_provider.dart';
import 'package:privacy_gui/core/data/providers/wifi_radios_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/services/dashboard_home_service.dart';

final dashboardHomeProvider =
    NotifierProvider<DashboardHomeNotifier, DashboardHomeState>(
  () => DashboardHomeNotifier(),
);

class DashboardHomeNotifier extends Notifier<DashboardHomeState> {
  @override
  DashboardHomeState build() {
    final deviceInfoState = ref.watch(deviceInfoProvider);
    final wifiRadiosState = ref.watch(wifiRadiosProvider);
    final ethernetPortsState = ref.watch(ethernetPortsProvider);
    final systemStatsState = ref.watch(systemStatsProvider);
    final deviceManagerState = ref.watch(deviceManagerProvider);

    final service = ref.read(dashboardHomeServiceProvider);
    return service.buildDashboardHomeState(
      deviceInfoState: deviceInfoState,
      wifiRadiosState: wifiRadiosState,
      ethernetPortsState: ethernetPortsState,
      systemStatsState: systemStatsState,
      deviceManagerState: deviceManagerState,
      getBandForDevice: (device) =>
          ref.read(deviceManagerProvider.notifier).getBandConnectedBy(device),
      deviceList: ref.read(deviceManagerProvider).deviceList,
    );
  }
}
