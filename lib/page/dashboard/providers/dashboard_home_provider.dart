import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/services/dashboard_home_service.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';

final dashboardHomeProvider =
    NotifierProvider<DashboardHomeNotifier, DashboardHomeState>(
  () => DashboardHomeNotifier(),
);

class DashboardHomeNotifier extends Notifier<DashboardHomeState> {
  @override
  DashboardHomeState build() {
    final dashboardManagerState = ref.watch(dashboardManagerProvider);
    final deviceManagerState = ref.watch(deviceManagerProvider);
    // Watch healthCheckProvider to maintain reactivity (even though we don't use it directly)
    ref.watch(healthCheckProvider);

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
