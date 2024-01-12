import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cache/linksys_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/connectivity/_connectivity.dart';
import 'package:linksys_app/provider/connectivity/connectivity_provider.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/jnap/models/device_info.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/provider/select_network/select_network_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
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
  Widget build(BuildContext context) =>
      AppFullScreenSpinner(text: getAppLocalizations(context).processing);

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
            cacheLevel: CacheLevel.noCache,
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
        .checkDeviceInfo(serialNumber)
        .then<NodeDeviceInfo?>((value) => value)
        .onError((error, stackTrace) => null);
    if (nodeDeviceInfo != null) {
      logger.d('SN changed: ${nodeDeviceInfo.serialNumber}');
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString(pCurrentSN, nodeDeviceInfo.serialNumber);
      await ref.read(connectivityProvider.notifier).forceUpdate();
      logger.d('Force update connectivity finish!');

      ref.read(pollingProvider.notifier).stopPolling();
      ref.read(pollingProvider.notifier).startPolling();
      router.goNamed(RouteNamed.dashboardHome);
    } else {
      // TODO #LINKSYS Error handling for unable to get deviceinfo
      logger.i('PREPARE :: Error handling for unable to get deviceinfo');
    }
  }
}
