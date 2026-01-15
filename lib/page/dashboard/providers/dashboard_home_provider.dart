import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_provider.dart';
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
    final dashboardManagerState = ref.watch(dashboardManagerProvider);
    final deviceManagerState = ref.watch(deviceManagerProvider);

    final service = ref.read(dashboardHomeServiceProvider);
    return service.buildDashboardHomeState(
      dashboardManagerState: dashboardManagerState,
      deviceManagerState: deviceManagerState,
      getBandForDevice: (device) =>
          ref.read(deviceManagerProvider.notifier).getBandConnectedBy(device),
      deviceList: ref.read(deviceManagerProvider).deviceList,
    );
  }
}
