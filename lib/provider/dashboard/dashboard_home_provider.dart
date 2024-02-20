import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_state.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/provider/dashboard/dashboard_home_state.dart';
import 'package:linksys_app/utils.dart';

final dashboardHomeProvider =
    NotifierProvider<DashboardHomeNotifier, DashboardHomeState>(
  () => DashboardHomeNotifier(),
);

class DashboardHomeNotifier extends Notifier<DashboardHomeState> {
  @override
  DashboardHomeState build() {
    final dashboardManagerState = ref.watch(dashboardManagerProvider);
    final deviceManagerState = ref.watch(deviceManagerProvider);
    return createState(dashboardManagerState, deviceManagerState);
  }

  DashboardHomeState createState(
    DashboardManagerState dashboardManagerState,
    DeviceManagerState deviceManagerState,
  ) {
    var newState = const DashboardHomeState();
    // Get main Wi-Fi SSID
    final ssid =
        dashboardManagerState.mainRadios.firstOrNull?.settings.ssid ?? 'Home';
    // Get available Wi-Fi radios
    final numOfWifi = _getNumberOfAvailableWifi(dashboardManagerState);
    // Get node number in the mesh
    final numOfNodes = deviceManagerState.nodeDevices.length;
    // Get online external devices number
    final onlineDevices = deviceManagerState.externalDevices
        .where((device) => device.connections.isNotEmpty)
        .toList();
    final numOfOnlineExternalDevices = onlineDevices.length;
    // Get WAN connection status
    final isWanConnected =
        deviceManagerState.wanStatus?.wanStatus == 'Connected';
    // If is first polling
    final isFirstPolling = deviceManagerState.lastUpdateTime == 0;
    // Get master node icon
    final sortedDeviceList = ref.read(deviceManagerProvider).deviceList;
    final masterIcon = routerIconTest(
      modelNumber: sortedDeviceList.firstOrNull?.model.modelNumber ?? '',
      hardwareVersion: sortedDeviceList.firstOrNull?.model.hardwareVersion,
    );
    // Get the formatted upload and download test
    final latestSpeedTest = dashboardManagerState.latestSpeedTest;
    final uploadResult = _formatHealthCheckResult(
      speed: latestSpeedTest?.speedTestResult?.uploadBandwidth ?? 0,
    );
    final downloadResult = _formatHealthCheckResult(
      speed: latestSpeedTest?.speedTestResult?.downloadBandwidth ?? 0,
    );

    return newState.copyWith(
      mainWifiSsid: ssid,
      numOfWifi: numOfWifi,
      numOfNodes: numOfNodes,
      numOfOnlineExternalDevices: numOfOnlineExternalDevices,
      isWanConnected: isWanConnected,
      isFirstPolling: isFirstPolling,
      masterIcon: masterIcon,
      uploadResult: uploadResult,
      downloadResult: downloadResult,
    );
  }

  int _getNumberOfAvailableWifi(DashboardManagerState state) {
    var count = 0;
    var ssids = <String>{};
    for (final radio in state.mainRadios) {
      ssids.add(radio.settings.ssid);
    }
    count += ssids.length;
    count += state.isGuestNetworkEnabled ? 1 : 0;
    return count;
  }

  ({String value, String unit}) _formatHealthCheckResult({required int speed}) {
    if (speed == 0) {
      return (
        value: '-',
        unit: '',
      );
    }
    // The speed is in kilobits per second
    String speedText = NetworkUtils.formatBytes(speed * 1024);
    return (
      value: speedText.split(' ').first,
      unit: speedText.split(' ').last,
    );
  }
}
