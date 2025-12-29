import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/services/dashboard_manager_service.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dashboardManagerProvider =
    NotifierProvider<DashboardManagerNotifier, DashboardManagerState>(
  () => DashboardManagerNotifier(),
);

class DashboardManagerNotifier extends Notifier<DashboardManagerState> {
  @override
  DashboardManagerState build() {
    final coreTransactionData = ref.watch(pollingProvider).value;
    final service = ref.read(dashboardManagerServiceProvider);
    return service.transformPollingData(coreTransactionData);
  }

  Future<void> saveSelectedNetwork(
      String serialNumber, String networkId) async {
    logger.i('[Prepare]: saveSelectedNetwork - $networkId, $serialNumber');
    final pref = await SharedPreferences.getInstance();
    logger.d('[Prepare]: save selected network - $serialNumber, $networkId');
    await pref.setString(pCurrentSN, serialNumber);
    await pref.setString(pSelectedNetworkId, networkId);
    ref.read(selectedNetworkIdProvider.notifier).state = networkId;
    state = const DashboardManagerState();
  }

  Future<NodeDeviceInfo> checkRouterIsBack() async {
    final service = ref.read(dashboardManagerServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final currentSN =
        prefs.getString(pCurrentSN) ?? prefs.getString(pPnpConfiguredSN);
    return service.checkRouterIsBack(currentSN ?? '');
  }

  Future<NodeDeviceInfo> checkDeviceInfo(String? serialNumber) async {
    final benchMark = BenchMarkLogger(name: 'checkDeviceInfo');
    benchMark.start();
    final service = ref.read(dashboardManagerServiceProvider);
    final nodeDeviceInfo = await service.checkDeviceInfo(state.deviceInfo);
    benchMark.end();
    return nodeDeviceInfo;
  }
}

final selectedNetworkIdProvider = StateProvider<String?>((ref) {
  return null;
});
