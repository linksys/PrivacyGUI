import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';

final dashboardHomeProvider =
    NotifierProvider<DashboardHomeNotifier, DashboardHomeState>(
  () => DashboardHomeNotifier(),
);

class DashboardHomeNotifier extends Notifier<DashboardHomeState> {
  @override
  DashboardHomeState build() {
    final dashboardManagerState = ref.watch(dashboardManagerProvider);
    final deviceManagerState = ref.watch(deviceManagerProvider);
    final healthCheckState = ref.watch(healthCheckProvider);
    return createState(
        dashboardManagerState, deviceManagerState, healthCheckState);
  }

  DashboardHomeState createState(
    DashboardManagerState dashboardManagerState,
    DeviceManagerState deviceManagerState,
    HealthCheckState healthCheckState,
  ) {
    var newState = const DashboardHomeState();
    // Get WiFi list
    final wifiList = dashboardManagerState.mainRadios
        .groupFoldBy<String, List<RouterRadio>>((element) => element.band,
            (previous, element) => [...(previous ?? []), element])
        .entries
        .map((e) => DashboardWiFiItem.fromMainRadios(
            e.value,
            deviceManagerState.mainWifiDevices.where((device) {
              final deviceBand = ref
                  .read(deviceManagerProvider.notifier)
                  .getBandConnectedBy(device);
              return device.nodeType == null &&
                  device.isOnline() &&
                  e.value.any((element) => element.band == deviceBand);
            }).length))
        .toList();
    if (dashboardManagerState.guestRadios.isNotEmpty) {
      wifiList.add(DashboardWiFiItem.fromGuestRadios(
              dashboardManagerState.guestRadios,
              deviceManagerState.guestWifiDevices
                  .where((device) => device.isOnline())
                  .length)
          .copyWith(isEnabled: dashboardManagerState.isGuestNetworkEnabled));
    }

    // Get Node list
    final isAnyNodesOffline =
        deviceManagerState.nodeDevices.any((element) => !element.isOnline());

    // Get WAN type
    final wanType = deviceManagerState.wanStatus?.wanConnection?.wanType;
    final detectedWANType = deviceManagerState.wanStatus?.detectedWANType;

    // If is first polling
    final isFirstPolling = deviceManagerState.lastUpdateTime == 0;
    // Get master node icon
    final sortedDeviceList = ref.read(deviceManagerProvider).deviceList;
    final masterIcon = routerIconTestByModel(
      modelNumber: sortedDeviceList.firstOrNull?.model.modelNumber ?? '',
      hardwareVersion: sortedDeviceList.firstOrNull?.model.hardwareVersion,
    );
    
    final deviceInfo = dashboardManagerState.deviceInfo;
    final horizontalPortLayout = isHorizontalPorts(
        modelNumber: deviceInfo?.modelNumber ?? '',
        hardwareVersion: deviceInfo?.hardwareVersion ?? '1');

    newState = newState.copyWith(
      wifis: wifiList,
      uptime: () => dashboardManagerState.uptimes,
      wanPortConnection: () => dashboardManagerState.wanConnection,
      lanPortConnections: dashboardManagerState.lanConnections,
      isFirstPolling: isFirstPolling,
      masterIcon: masterIcon,
      isAnyNodesOffline: isAnyNodesOffline,
      isHorizontalLayout: horizontalPortLayout,
      wanType: () => wanType,
      detectedWANType: () => detectedWANType,
    );

    return newState;
  }
}
