import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/select_network/providers/select_network_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrepareDashboardView extends ArgumentsConsumerStatefulView {
  const PrepareDashboardView({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<PrepareDashboardView> createState() =>
      _PrepareDashboardViewState();
}

class _PrepareDashboardViewState extends ConsumerState<PrepareDashboardView> {
  @override
  void initState() {
    super.initState();
    _checkSelfNetworks();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              AppGap.lg(),
              AppText.bodyMedium(loc(context).processing),
            ],
          ),
        ),
      );

  _checkSelfNetworks() async {
    final router = GoRouter.of(context);
    await ref.read(connectivityProvider.notifier).forceUpdate();
    final prefs = await SharedPreferences.getInstance();
    String? serialNumber = prefs.getString(pCurrentSN);
    final loginType =
        ref.read(authProvider.select((value) => value.value?.loginType));
    if (loginType == LoginType.remote) {
      logger.i('PREPARE LOGIN:: remote');
      if (ref.read(selectedNetworkIdProvider) == null) {
        final networkId = prefs.getString(pSelectedNetworkId);

        ref.read(selectNetworkProvider.notifier).refreshCloudNetworks();
        if (networkId == null || serialNumber == null) {
          router.goNamed(RouteNamed.selectNetwork);
          return;
        } else {
          await ref
              .read(dashboardManagerProvider.notifier)
              .saveSelectedNetwork(serialNumber, networkId);
        }
      }
    } else if (loginType == LoginType.local) {
      logger.i('PREPARE LOGIN:: local');
      final routerRepository = ref.read(routerRepositoryProvider);

      final newSerialNumber = await routerRepository
          .send(
            JNAPAction.getDeviceInfo,
            fetchRemote: true,
          )
          .then<String>(
              (value) => NodeDeviceInfo.fromJson(value.output).serialNumber);
      await ref
          .read(dashboardManagerProvider.notifier)
          .saveSelectedNetwork(newSerialNumber, '');
    }
    logger.d('Go to dashboard');
    await ProviderContainer()
        .read(linksysCacheManagerProvider)
        .loadCache(serialNumber: serialNumber ?? '');
    final nodeDeviceInfo = await ref
        .read(dashboardManagerProvider.notifier)
        .checkDeviceInfo(null)
        .then<NodeDeviceInfo?>((nodeDeviceInfo) {
      // Build/Update better actions
      buildBetterActions(nodeDeviceInfo.services);
      return nodeDeviceInfo;
    }).onError((error, stackTrace) => null);
    if (nodeDeviceInfo != null) {
      logger.d('SN changed: ${nodeDeviceInfo.serialNumber}');
      await ref.read(connectivityProvider.notifier).forceUpdate();
      logger.d('Force update connectivity finish!');

      ref.read(pollingProvider.notifier).stopPolling();
      ref.read(pollingProvider.notifier).startPolling();
      // RA mode
      final raMode = prefs.getBool(pRAMode) ?? false;
      if (raMode) {
        ref.read(raSessionProvider.notifier).startMonitorSession();
      }
      router.goNamed(RouteNamed.dashboardHome);
    } else {
      // TODO #LINKSYS Error handling for unable to get deviceinfo
      logger.i('PREPARE :: Error handling for unable to get deviceinfo');
      router.goNamed(RouteNamed.cloudLoginAccount,
          extra: {'error': 'Unexpected'});
    }
  }
}
