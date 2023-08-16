import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/provider/account/account_provider.dart';
import 'package:linksys_moab/provider/auth/auth_provider.dart';
import 'package:linksys_moab/provider/connectivity/_connectivity.dart';
import 'package:linksys_moab/provider/connectivity/connectivity_provider.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/core/jnap/models/device_info.dart';
import 'package:linksys_moab/core/jnap/providers/polling_provider.dart';
import 'package:linksys_moab/route/constants.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../localization/localization_hook.dart';
import '../../../core/utils/logger.dart';
import '../../components/views/arguments_view.dart';

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
    await ref.read(connectivityProvider.notifier).forceUpdate();
    if (!context.mounted) return;
    final loginType =
        ref.watch(authProvider.select((value) => value.value?.loginType));
    if (loginType == LoginType.remote) {
      logger.i('PREPARE LOGIN:: remote');
      if (context.read<NetworkCubit>().state.selected == null) {
        // TODO #LINKSYS
        // await context.read<AccountCubit>().fetchAccount();
        await context
            .read<NetworkCubit>()
            .getNetworks(accountId: ref.read(accountProvider).id);

        context.goNamed(RouteNamed.selectNetwork);
        return;
      }
    }
    logger.d('Go to dashboard');
    final routerDeviceInfo = await context
        .read<NetworkCubit>()
        .getDeviceInfo()
        .then<RouterDeviceInfo?>((value) => value)
        .onError((error, stackTrace) => null);
    if (routerDeviceInfo != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          linkstyPrefCurrentSN, routerDeviceInfo.serialNumber);
      await ref.read(connectivityProvider.notifier).forceUpdate();

      // ref.watch(navigationsProvider.notifier).clearAndPush(DashboardHomePath());
      context.goNamed(RouteNamed.dashboardHome);
      ref.watch(pollingProvider.notifier).startPolling();
    } else {
      // TODO #LINKSYS Error handling for unable to get deviceinfo
    }
  }
}
